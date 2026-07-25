#!/usr/bin/env bash
# Short link: https://bit.ly/installbigfix
#
# kickstart bigfix install
# tested as working with the following: Mac OS X, Debian, Ubuntu, RHEL, CentOS, Fedora, OracleEL, SUSE
#
# Supported architectures:
#   - x86_64 / amd64   (BigFix 11)
#   - i386  / i686     (falls back to BigFix 9.5, the last release with 32-bit x86 builds)
#   - armhf            (Raspberry Pi OS / Raspbian, .deb only)
#   - ppc64le          (Ubuntu .deb only in this script; RPM ppc64le/s390x not yet wired up)
#
#    Reference: https://support.bigfix.com/bes/install/besclients-nonwindows.html
#      Related: https://github.com/bigfix/bfdocker/tree/master/besclient
#
# Usage:
#   curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh
#   bash install_bigfix.sh __ROOT_OR_RELAY_FQDN__
#
# Single Line:
#  curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh ; bash install_bigfix.sh __ROOT_OR_RELAY_FQDN__

# TODO: use the masthead file in current directory if present

# Ensure we are actually running under bash, not sh/dash/ash.
#  $BASH_VERSION is unset in any non-bash shell.
#  This guard must stay pure POSIX (no [[ ]], no &>) so sh can parse it,
#   then it transparently re-executes the script under bash if available.
# see the issue this solves:  https://github.com/jgstew/tools/issues/20
# https://unix.stackexchange.com/questions/71121/determine-shell-in-script-during-runtime
if [ -z "$BASH_VERSION" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  fi
  echo "ERROR: this script requires bash (it uses [[ ]], &>, and OSTYPE)." >&2
  echo "       Re-run as: bash $0 $*" >&2
  exit 1
fi

# https://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# https://www.tldp.org/LDP/abs/html/functions.html
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

# resolve the directory this script lives in, regardless of CWD
#  (degrades to CWD when piped, e.g. `curl ... | bash`, where $0 is not a file)
SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"

# All downloads and generated files are staged in STAGINGDIR.
#  Defaults to the script's own directory; falls back to /tmp when that
#  is not writable (e.g. script mounted read-only in a container).
#  This is separate from INSTALLDIR, which is where the BES installer
#  expects to read the masthead from (OS specific, set further below).
# see the issue this solves:  https://github.com/jgstew/tools/issues/16
STAGINGDIR="$SCRIPTDIR"
if [ ! -w "$STAGINGDIR" ]; then
  echo "NOTE: $STAGINGDIR is not writable, staging in /tmp instead"
  STAGINGDIR="/tmp"
fi
STAGED_CFG="$STAGINGDIR/clientsettings.cfg"

# if $1 exists, then set MASTHEADURL
# https://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  MASTHEADURL="https://$1:52311/masthead/masthead.afxm"
  RELAYFQDN="$1:52311"
  # if parameter contains colon:
  if [[ "$1" == *":"* ]]; then
    MASTHEADURL="https://$1/masthead/masthead.afxm"
    RELAYFQDN=$1
  fi
else
  # TODO: allow a masthead to be provided in the CWD instead.
  echo Must provide FQDN of Root or Relay
  exit 1
fi

if [ -n "$2" ]; then
  RELAYPASS="$2"
fi

# these variables are used to determine which version of the BigFix agent should be downloaded
# these variables are typically set to the latest version of the BigFix agent
# URLMAJORMINOR is the first two integers of URLVERSION
#  most recent version# found here under `Agent`:  https://support.bigfix.com/bes/release/
URLVERSION=11.0.6.137

# check for x32bit or x64bit OS
MACHINETYPE=`uname -m`

# set OSBIT based on MACHINETYPE. Only x86-family CPUs get OSBIT=x32 (name lacks "64" but contains "86").
# Anything else (x86_64, aarch64, ppc64le, s390x, armv7l, ...) gets OSBIT=x64 and is disambiguated below.
if [[ $MACHINETYPE != *"64"* ]] && [[ $MACHINETYPE == *"86"* ]]; then
  OSBIT=x32
  URLVERSION=9.5.25.11
else
  OSBIT=x64
  # KNOWN ISSUE: this will incorrectly assume AMD64 compatible processor in the case of PowerPC64
fi

URLMAJORMINOR=`echo $URLVERSION | awk -F. '{print $1 $2}'`

############################################################
# TODO: add more linux cases, not all are handled

# if clientsettings.cfg exists in CWD (or next to this script) copy it to
#  staging. CWD wins if both exist. Guard against copying a file onto itself
#  when the cfg already sits in the staging directory.
if [ -f clientsettings.cfg ] && [ ! -f "$STAGED_CFG" ] && [ "$(pwd)/clientsettings.cfg" != "$STAGED_CFG" ] ; then
  cp clientsettings.cfg "$STAGED_CFG"
fi
if [ -f "$SCRIPTDIR/clientsettings.cfg" ] && [ ! -f "$STAGED_CFG" ] && [ "$SCRIPTDIR/clientsettings.cfg" != "$STAGED_CFG" ] ; then
  cp "$SCRIPTDIR/clientsettings.cfg" "$STAGED_CFG"
fi

if [ ! -f "$STAGED_CFG" ] ; then
  # create clientsettings.cfg file
  echo -n > "$STAGED_CFG"
  >> "$STAGED_CFG" echo _BESClient_RelaySelect_FailoverRelay=https://$RELAYFQDN/bfmirror/downloads/
  >> "$STAGED_CFG" echo __RelaySelect_Automatic=1
  >> "$STAGED_CFG" echo _BESClient_Resource_StartupNormalSpeed=1
  >> "$STAGED_CFG" echo _BESClient_Download_RetryMinutes=1
  >> "$STAGED_CFG" echo _BESClient_Download_CheckAvailabilitySeconds=120
  >> "$STAGED_CFG" echo _BESClient_Resource_WorkIdle=20
  >> "$STAGED_CFG" echo _BESClient_Resource_SleepIdle=500
  >> "$STAGED_CFG" echo _BESClient_Resource_PowerSaveEnable=1
  >> "$STAGED_CFG" echo _BESClient_Query_SleepTime=500
  >> "$STAGED_CFG" echo _BESClient_Query_WorkTime=250
  >> "$STAGED_CFG" echo _BESClient_Query_NMOMaxQueryTime=30
  >> "$STAGED_CFG" echo _BESClient_Resource_AccelerateForPendingMessage=1
  >> "$STAGED_CFG" echo _BESClient_Comm_CommandPollEnable=1
  >> "$STAGED_CFG" echo _BESClient_Comm_CommandPollIntervalSeconds=1800
  >> "$STAGED_CFG" echo _BESClient_Log_Days=30
  >> "$STAGED_CFG" echo _BESClient_Log_MaxSize=1536000
  >> "$STAGED_CFG" echo _BESClient_Download_UtilitiesCacheLimitMB=500
  >> "$STAGED_CFG" echo _BESClient_Download_DownloadsCacheLimitMB=5000
  >> "$STAGED_CFG" echo _BESClient_Download_MinimumDiskFreeMB=2000
  >> "$STAGED_CFG" echo _BESClient_ActionManager_HistoryKeepDays=1825
  >> "$STAGED_CFG" echo _BESClient_ActionManager_HistoryDisplayDaysTech=90
  >> "$STAGED_CFG" echo _BESClient_ActionManager_CompletionDialogTimeoutSeconds=30
  >> "$STAGED_CFG" echo _BESClient_PersistentConnection_Enabled=1
  >> "$STAGED_CFG" echo _BESClient_ActionManager_OverrideTimeoutSeconds=21600
  # Best-effort record of who initiated the install.
  #  $SUDO_USER only exists when launched through sudo, so fall back through
  #  progressively less specific sources. who/logname need a tty/utmp entry,
  #  so in docker containers / non-interactive root this resolves to "root"
  #  via id -un, which is the truthful answer there.
  # see the issue this solves:  https://github.com/jgstew/tools/issues/17
  INSTALL_USER="$SUDO_USER"
  [ -z "$INSTALL_USER" ] && INSTALL_USER=`who am i 2>/dev/null | awk '{print $1}'`
  [ -z "$INSTALL_USER" ] && INSTALL_USER=`logname 2>/dev/null`
  [ -z "$INSTALL_USER" ] && INSTALL_USER="$USER"
  [ -z "$INSTALL_USER" ] && INSTALL_USER=`id -un 2>/dev/null`
  >> "$STAGED_CFG" echo _BESClient_InstallTime_SudoUser=$INSTALL_USER
  if [ -n "$RELAYPASS" ]; then
    >> "$STAGED_CFG" echo _BESClient_SecureRegistration=$RELAYPASS
  fi
fi

if [[ $OSTYPE == darwin* ]]; then
  # Mac OS X
  # the macOS installer reads the masthead from the staging folder
  INSTALLDIR="$STAGINGDIR"
  # example: https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-BigFix_MacOS11.0.pkg
  INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-BigFix_MacOS11.0.pkg"
  INSTALLER="$STAGINGDIR/BESAgent.pkg"
else
  # For most Linux:
  INSTALLDIR="/etc/opt/BESClient"

  # if dpkg exists (Debian)
  if command_exists dpkg ; then
    # Debian based
    INSTALLER="$STAGINGDIR/BESAgent.deb"

    # check distribution
    # cat /etc/os-release /etc/lsb-release | grep --ignore-case --max-count=1 --count ubuntu
    # cat /etc/os-release | grep '^ID' | awk -F=  '{ print $2 }'
    DEBDIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`

    if [[ $DEBDIST == "" ]]; then
      DEBDIST=`cat /etc/os-release | grep '^ID' | awk -F=  '{ print $2 }'`
    fi

    if [[ $OSBIT == x64 ]]; then
      URLBITS=amd64
      UBUNTUDIST=ubuntu18
      DEBIANDIST=debian10
    else
      URLBITS=i386
      # BigFix 9.5 (the last release with 32-bit x86 builds) uses older distro tags.
      UBUNTUDIST=ubuntu10
      DEBIANDIST=debian6
    fi

    if [[ $DEBDIST == *buntu* ]]; then
      # Ubuntu
      INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-$UBUNTUDIST.$URLBITS.deb"
    else
      # Debian
      INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-$DEBIANDIST.$URLBITS.deb"

      # get rasbian installer if on arm architecture:
      if uname -m | grep --ignore-case --max-count=1 --count -E "aarch64|arm" ; then
        # Raspberry Pi OS / Raspbian is 32-bit ARM (armhf)
        URLBITS=armhf
        INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-raspbian10.armhf.deb"
        dpkg --add-architecture armhf
        apt-get update
      fi
    fi

    # Check for CPU architecture (ppc64el)
    # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-ubuntu18.ppc64el.deb
    if uname -m | grep --ignore-case --max-count=1 --count -E "ppc64le" ; then
      # PPC64LE architecture
      URLBITS=ppc64el
      INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-ubuntu18.$URLBITS.deb"
    fi
  fi # END_IF Debian (dpkg)

  # if rpm exists
  if command_exists rpm ; then
    # rpm - Currently assuming RedHat based
    INSTALLER="$STAGINGDIR/BESAgent.rpm"

    if [[ $OSBIT == x64 ]]; then
      URLBITS=x86_64
      RHELDIST=rhe7
      SUSEDIST=sle12
    else
      URLBITS=i686
      # BigFix 9.5 (the last release with 32-bit x86 builds) uses older distro tags.
      RHELDIST=rhe6
      SUSEDIST=sle11
    fi

    INSTALLERURL="https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-$RHELDIST.$URLBITS.rpm"

    # TODO check for other CPU architectures (arm64, ppc64le, s390x, etc) and set URLBITS accordingly
    # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-al2.aarch64.rpm
    # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-rhe7.ppc64le.rpm
    # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-rhe7.s390x.rpm

    # if not RHEL family, fall through to SUSE (the only other RPM-based dist BigFix ships)
    #  Amazon Linux has /etc/system-release but NOT /etc/redhat-release, and
    #  should use the RHEL build, so only assume SUSE when neither exists.
    if [ ! -f /etc/redhat-release ] && [ ! -f /etc/system-release ] ; then
      # Assume SUSE
      #  SUSE is the only other RPM based linux supported by BigFix that is not based upon the RHEL family
      INSTALLERURL=https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-$SUSEDIST.$URLBITS.rpm
      # NOTE: BigFix 11 dropped sle11 builds; sle12 is the oldest SUSE build published for 11.0.x.
      #       32-bit x86 (i686) falls back to BigFix 9.5 which does publish sle11.i686.rpm.
      # TODO: Check for CPU architecture (ppc64le, s390x) and set URLBITS accordingly
      # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-sle12.ppc64le.rpm
      # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137-sle12.s390x.rpm
    fi # END_IF not-RHEL-family
  fi # END_IF exists rpm

  if command_exists pkgadd ; then
      # TODO: test case for Solaris
      echo "Solaris Detected"
      # BigFix on Solaris uses /etc/opt/BESClient for the masthead/clientsettings staging
      # (same layout as Linux). Set it explicitly so any future non-Linux paths above
      # don't accidentally leak into the Solaris branch.
      INSTALLDIR="/etc/opt/BESClient"
      INSTALLER="$STAGINGDIR/BESAgent.pkg"
      # example:   https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137.x86_sol11.pkg
      INSTALLERURL=https://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION.x86_sol11.pkg
      echo $INSTALLERURL

      # TODO check for CPU architecture (sparc)
      # https://software.bigfix.com/download/bes/110/BESAgent-11.0.6.137.sparc_sol11.pkg
  fi # END_IF pkgadd
fi # END_IF darwin
############################################################


# MUST HAVE ROOT PRIV
if [ "$(id -u)" != "0" ]; then
  # dump out data for debugging
  echo
  echo OSTYPE=$OSTYPE
  echo MACHINETYPE=$MACHINETYPE
  echo OSBIT=$OSBIT
  echo INSTALLDIR=$INSTALLDIR
  echo INSTALLER=$INSTALLER
  echo INSTALLERURL=$INSTALLERURL
  echo URLBITS=$URLBITS
  echo URLVERSION=$URLVERSION
  echo URLMAJORMINOR=$URLMAJORMINOR
  echo MASTHEADURL=$MASTHEADURL
  echo DEBDIST=$DEBDIST
  echo
  echo "Sorry, you are not root. Exiting."
  echo
  exit 1
fi

############################################################
###    Start execution:    #################################
############################################################

# Create $INSTALLDIR folder if missing
if [ ! -d "$INSTALLDIR" ]; then
  # Control will enter here if $INSTALLDIR doesn't exist.
  mkdir -p "$INSTALLDIR"
fi


#### Downloads #############################################

# Fail fast if OS detection above did not produce a download URL (unsupported OS/arch).
if [ -z "$INSTALLERURL" ] || [ -z "$INSTALLER" ]; then
  (>&2 echo "ERROR: could not determine BigFix agent download URL for this OS/arch.")
  (>&2 echo "  OSTYPE=$OSTYPE MACHINETYPE=$MACHINETYPE OSBIT=$OSBIT")
  exit 3
fi

DLEXITCODE=0
if command_exists curl ; then
  # Download the BigFix agent (using cURL because it is on most Linux & OS X by default)
  curl -S -f -o "$INSTALLER" $INSTALLERURL
  # https://stackoverflow.com/questions/6348902/how-can-i-add-numbers-in-a-bash-script
  DLEXITCODE=$(( DLEXITCODE + $? ))
  # Download the masthead, renamed, into the correct location
  # TODO: get masthead from CWD instead if present
  # https://unix.stackexchange.com/questions/60750/does-curl-have-a-no-check-certificate-option-like-wget
  #  the url for the masthead will not use a valid SSL certificate, instead it will use one tied to the masthead itself
  curl -S -f --insecure -o "$INSTALLDIR/actionsite.afxm" $MASTHEADURL
  DLEXITCODE=$(( DLEXITCODE + $? ))
else
  if command_exists wget ; then
    # this is run if curl doesn't exist, but wget does
    # download using wget
    # https://stackoverflow.com/questions/16678487/wget-command-to-download-a-file-and-save-as-a-different-filename
    # https://www.gnu.org/software/wget/manual/html_node/HTTPS-_0028SSL_002fTLS_0029-Options.html
    wget $MASTHEADURL -O "$INSTALLDIR/actionsite.afxm" --no-check-certificate
    DLEXITCODE=$(( DLEXITCODE + $? ))

    wget $INSTALLERURL -O "$INSTALLER"
    DLEXITCODE=$(( DLEXITCODE + $? ))
  else
    echo neither wget nor curl is installed.
    echo not able to download required files.
    echo exiting...
    exit 2
  fi
fi

# Exit if download failed
if [ $DLEXITCODE -ne 0 ]; then
  # https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
  (>&2 echo Download Failed. ExitCode=$DLEXITCODE)
  exit $DLEXITCODE
fi

# See here: https://github.com/jgstew/tools/blob/master/bash/enable_incoming_port.sh
# open up linux firewall to accept UDP 52311 - iptables
if command_exists iptables ; then
  iptables -A INPUT -p udp --dport 52311 -j ACCEPT
fi
# open up linux firewall to accept UDP 52311 - firewall-cmd
if command_exists firewall-cmd ; then
  firewall-cmd --zone=public --add-port=52311/udp --permanent
  firewall-cmd --reload
fi
# open up linux firewall to accept UDP 52311 - firewall-offline-cmd
if command_exists firewall-offline-cmd ; then
  # this applies in anaconda at install time in particular
  firewall-offline-cmd --add-port=52311/udp
  firewall-offline-cmd --reload
fi
# open Debian/Ubuntu firewall:
if command_exists ufw ; then
  ufw allow 52311/udp
fi

# install BigFix client
if [[ $INSTALLER == *.deb ]]; then
  #  debian (DEB)
  # Prefer apt-get so runtime dependencies get resolved automatically on
  #  minimal or container images. Fall back to dpkg (no dependency
  #  resolution) if apt-get is missing or fails (e.g. empty package lists).
  #  The ./ prefix makes apt-get treat it as a local file, not a repo package.
  # see the issue this solves:  https://github.com/jgstew/tools/issues/19
  if command_exists apt-get ; then
    apt-get install -y "$INSTALLER" || dpkg -i "$INSTALLER"
  else
    dpkg -i "$INSTALLER"
  fi
fi
if [[ $INSTALLER == *.pkg ]]; then
  # PKG type
  #   Could be Mac OS X, Solaris, or AIX
  if command_exists installer ; then
    #  Mac OS X
    installer -pkg "$INSTALLER" -target /
  else
    if command_exists pkgadd ; then
        # TODO: test case for Solaris

        echo y | pkgadd -d "$INSTALLER" BESagent
    fi # pkgadd
  fi # installer
fi # *.pkg install file
if [[ $INSTALLER == *.rpm ]]; then
  #  linux (RPM)
  # if file `/etc/init.d/besclient` exists then stop before upgrade
  if [ -f /etc/init.d/besclient ]; then
    /etc/init.d/besclient stop
  fi
  # Prefer a dependency resolving package manager (dnf, then yum) so runtime
  #  dependencies like libstdc++ get pulled in automatically on minimal or
  #  container images. Fall back to plain rpm, which does not resolve
  #  dependencies, since some environments only have the rpm command.
  #  The ./ prefix makes dnf/yum treat it as a local file, not a repo package.
  # see the issue this solves:  https://github.com/jgstew/tools/issues/19
  if command_exists dnf ; then
    dnf install -y "$INSTALLER"
  elif command_exists yum ; then
    yum install -y "$INSTALLER"
  elif command_exists zypper ; then
    # SUSE: --no-gpg-checks because the BESAgent rpm key is not imported
    zypper --non-interactive --no-gpg-checks install "$INSTALLER"
  else
    # if file `/etc/init.d/besclient` exists then do upgrade
    if [ -f /etc/init.d/besclient ]; then
      rpm -U "$INSTALLER"
    else
      rpm -ivh "$INSTALLER"
    fi
  fi

  # The BESAgent rpm does not declare its shared library dependencies
  #  (verified against 11.0.6.137: `rpm -qp --requires` lists no sonames),
  #  so even a dependency resolving package manager cannot pull them in.
  #  Instead ask ldd which libraries are actually missing and install
  #  whatever package provides that soname (e.g. minimal container images
  #  are missing libdbus-1.so.3 and sometimes libstdc++.so.6).
  #  Nothing is hardcoded here so this adapts if the missing library changes.
  # see the issue this solves:  https://github.com/jgstew/tools/issues/19
  if command_exists ldd && [ -f /opt/BESClient/bin/BESClient ]; then
    for MISSINGLIB in `ldd /opt/BESClient/bin/BESClient 2>/dev/null | grep "not found" | awk '{print $1}' | sort -u`; do
      echo "BESClient requires missing library: $MISSINGLIB - attempting to install it"
      if command_exists dnf ; then
        dnf install -y "$MISSINGLIB()(64bit)" || dnf install -y "$MISSINGLIB"
      elif command_exists yum ; then
        yum install -y "$MISSINGLIB()(64bit)" || yum install -y "$MISSINGLIB"
      elif command_exists zypper ; then
        zypper --non-interactive install "$MISSINGLIB()(64bit)" || zypper --non-interactive install "$MISSINGLIB"
      else
        (>&2 echo "WARNING: no package manager available to install $MISSINGLIB - BESClient may not run")
      fi
    done
  fi
fi

# if missing, create besclient.config file based upon the staged clientsettings.cfg
if [ ! -f /var/opt/BESClient/besclient.config ]; then
  cat "$STAGED_CFG" | awk 'BEGIN { print "[Software\\BigFix\\EnterpriseClient]"; print "EnterpriseClientFolder = /opt/BESClient"; print; print "[Software\\BigFix\\EnterpriseClient\\GlobalOptions]"; print "StoragePath = /var/opt/BESClient"; print "LibPath = /opt/BESClient/BESLib"; } /=/ {gsub(/=/, " "); print "\n[Software\\BigFix\\EnterpriseClient\\Settings\\Client\\" $1 "]\nvalue = " $2;}' > /var/opt/BESClient/besclient.config
  chmod 600 /var/opt/BESClient/besclient.config
fi

### start the BigFix client (required for most linux dist)
# if file `/etc/init.d/besclient` exists
if [ -f /etc/init.d/besclient ]; then
  # Do not start bigfix if: StartBigFix=false
  if [[ "$StartBigFix" != "false" ]]; then
    /etc/init.d/besclient start
  fi
else
  # start using systemd
  systemctl start besclient
fi

# pause 30 seconds to wait for bigfix to get going a bit
echo "sleep for 30 seconds"
sleep 30

# output the contents of the log file to see if things are working:  https://github.com/jgstew/tools/blob/master/bash/bigfixlogs.sh
# TODO: add mac support to the following:
if [ -f "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log" ]; then

  if [ -n "$NOEXIT" ]; then
    # tail log forever if NOEXIT set to anything
    tail --verbose "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log"
  else
    tail --lines=25 --verbose "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log"
  fi
  # Related:
  #  - https://bigfix.me/fixlet/details/24646
  #  - https://bigfix.me/relevance/details/3020387
fi

### References:
# - https://stackoverflow.com/questions/733824/how-to-run-a-sh-script-in-an-unix-console-mac-terminal
# - https://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
# - https://flokoe.github.io/bash-hackers-wiki/scripting/posparams/
# - https://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
# - https://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# - https://forum.bigfix.com/t/script-to-kickstart-the-installation-of-bigfix-on-os-x-debian-family-rhel-family/17023
# - https://stackoverflow.com/questions/30557508/bash-checking-if-string-does-not-contain-other-string
