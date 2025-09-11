:<<"::CMDLITERAL"
@ECHO OFF
REM Short link: http://bit.ly/installbigfix
REM  Usage:
REM powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/CMD/install_bigfix_universal.bat', 'install_bigfix.bat') }" -ExecutionPolicy Bypass
REM install_bigfix.bat __FQDN_OF_ROOT_OR_RELAY__

REM    Source: https://github.com/jgstew/tools/blob/master/CMD/install_bigfix.bat
REM   Related: https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh

REM http://stackoverflow.com/questions/2541767/what-is-the-proper-way-to-test-if-variable-is-empty-in-a-batch-file-if-not-1
IF [%1] == [] ECHO please provide FQDN for root or relay && EXIT /B
REM KNOWN ISSUE: if enhanced security is enabled on root/relay, then must use HTTPS for masthead download. This will mean that the download part will have to ignore SSL errors
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
SET RELAYFQDN=%1
SET BASEFOLDER=C:\Windows\Temp

REM check if BigFix is installed
sc query besclient | find /I "besclient" > nul
if %errorlevel% NEQ 1 goto end
REM if errorlevel = 1 then BigFix is NOT installed, so continue:

REM  TODO: handle clientsettings.cfg or masthead.afxm or actionsite.afxm already in the CWD
REM  TODO: check for admin rights http://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights

REM http://stackoverflow.com/questions/4781772/how-to-test-if-an-executable-exists-in-the-path-from-a-windows-batch-file
where /q powershell || ECHO Could not find powershell. && EXIT /B

@ECHO ON
REM this following line will need to ignore SSL errors if HTTPS is used instead of HTTP
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%MASTHEADURL%', '%BASEFOLDER%\actionsite.afxm') }" -ExecutionPolicy Bypass
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.14.73.exe', '%BASEFOLDER%\BESClient.exe') }" -ExecutionPolicy Bypass
@ECHO OFF

REM https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli%20Endpoint%20Manager/page/Configuration%20Settings
REM https://gist.github.com/jgstew/51a99ab4b5997efa0318
REM http://stackoverflow.com/questions/1702762/how-to-create-an-empty-file-at-the-command-line-in-windows
REM http://stackoverflow.com/questions/7225630/how-to-echo-2-no-quotes-to-a-file-from-a-batch-script
type NUL > %BASEFOLDER%\clientsettings.cfg
REM  TODO: only do the following line if FQDN_variable is set
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_RelaySelect_FailoverRelay=http://%1:52311/bfmirror/downloads/
>>%BASEFOLDER%\clientsettings.cfg ECHO __RelaySelect_Automatic=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_StartupNormalSpeed=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_RetryMinutes=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_WorkIdle=20
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Resource_SleepIdle=500
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Comm_CommandPollEnable=1
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Comm_CommandPollIntervalSeconds=10800
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Log_Days=30
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_UtilitiesCacheLimitMB=500
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_DownloadsCacheLimitMB=5000
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_Download_MinimumDiskFreeMB=2000

ECHO
ECHO %0
ECHO %1
ECHO %MASTHEADURL%
ECHO
ECHO Installing BigFix now.
%BASEFOLDER%\BESClient.exe /s /v"/l*voicewarmup %BASEFOLDER%\install_bigfix.log /qn"

:end
EXIT /B
::CMDLITERAL

#!/usr/bin/env bash
# Short link: http://bit.ly/installbigfix
#
#   Work In Progress:  curl http://bit.ly/installbigfix | grep -o '".*"' | sed 's/"//g'
# kickstart bigfix install
# tested as working with the following: Mac OS X, Debian, Ubuntu, RHEL, CentOS, Fedora, OracleEL, SUSE
#
# Only currently works with Intel32 & AMD64 architectures. (any Intel or AMD or compatible processor)
#          (Itanium, Power, and others are not common, but could be added)
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

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# http://www.tldp.org/LDP/abs/html/functions.html
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

# if $1 exists, then set MASTHEADURL
# http://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  MASTHEADURL="http://$1:52311/masthead/masthead.afxm"
  RELAYFQDN=$1
else
  # TODO: allow a masthead to be provided in the CWD instead.
  echo Must provide FQDN of Root or Relay
  exit 1
fi

# these variables are used to determine which version of the BigFix agent should be downloaded
# these variables are typically set to the latest version of the BigFix agent
# URLMAJORMINOR is the first two integers of URLVERSION
#  most recent version# found here under `Agent`:  http://support.bigfix.com/bes/release/
URLVERSION=9.5.14.73
URLMAJORMINOR=`echo $URLVERSION | awk '/./ {gsub(/\./, " "); print $1 $2}'`

# check for x32bit or x64bit OS
MACHINETYPE=`uname -m`

# set OS_BIT variable based upon MACHINE_TYPE (this currently assumes either Intel 32bit or AMD 64bit)
# if machine_type does not contain 64 then 32bit else 64bit (assume 64 unless otherwise noted)
if [[ $MACHINETYPE != *"64"* ]]; then
  OSBIT=x32
else
  OSBIT=x64
  # KNOWN ISSUE: this will incorrectly assume AMD64 compatible processor in the case of PowerPC64
fi

############################################################
# TODO: add more linux cases, not all are handled

# set INSTALLDIR for OS X - other OS options will change this variable
#   This will also be used to create the default clientsettings.cfg file
INSTALLDIR="/tmp"

# if clientsettings.cfg exists in CWD copy it
if [ -f clientsettings.cfg ] && [ ! -f $INSTALLDIR/clientsettings.cfg ] ; then
  cp clientsettings.cfg $INSTALLDIR/clientsettings.cfg
fi

if [ ! -f $INSTALLDIR/clientsettings.cfg ] ; then
  # create clientsettings.cfg file
  echo -n > $INSTALLDIR/clientsettings.cfg
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_RelaySelect_FailoverRelay=http://$RELAYFQDN:52311/bfmirror/downloads/
  >> $INSTALLDIR/clientsettings.cfg echo __RelaySelect_Automatic=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_StartupNormalSpeed=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_RetryMinutes=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_CheckAvailabilitySeconds=120
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_WorkIdle=20
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_SleepIdle=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_PowerSaveEnable=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_SleepTime=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_WorkTime=250
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Query_NMOMaxQueryTime=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_AccelerateForPendingMessage=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollEnable=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollIntervalSeconds=600
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Log_Days=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Log_MaxSize=1536000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_UtilitiesCacheLimitMB=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_DownloadsCacheLimitMB=5000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_MinimumDiskFreeMB=2000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_HistoryKeepDays=1825
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_HistoryDisplayDaysTech=90
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_ActionManager_CompletionDialogTimeoutSeconds=30
  # TODO: the following line needs tested. Seems to not be working in docker containers, or perhaps not at all.
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_InstallTime_User=`echo $SUDO_USER`
fi

if [[ $OSTYPE == darwin* ]]; then
  # Mac OS X
  INSTALLERURL="http://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-BigFix_MacOSX10.7.pkg"
  INSTALLER="/tmp/BESAgent.pkg"
else
  # For most Linux:
  INSTALLDIR="/etc/opt/BESClient"

  # if dpkg exists (Debian)
  if command_exists dpkg ; then
    # Debian based
    INSTALLER="BESAgent.deb"

    # check distribution
    DEBDIST=`cat /etc/lsb-release | grep '^DISTRIB_ID' | awk -F=  '{ print $2 }'`

    if [[ $OSBIT == x64 ]]; then
      URLBITS=amd64
    else
      URLBITS=i386
    fi

    if [[ $DEBDIST == Ubuntu* ]]; then
      # Ubuntu
      INSTALLERURL="http://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-ubuntu10.$URLBITS.deb"
    else
      # Debian
      INSTALLERURL="http://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-debian6.$URLBITS.deb"
    fi
  fi # END_IF Debian (dpkg)

  # if rpm exists
  if command_exists rpm ; then
    # rpm - Currently assuming RedHat based
    INSTALLER="BESAgent.rpm"

    if [[ $OSBIT == x64 ]]; then
      URLBITS=x86_64
    else
      URLBITS=i686
    fi

    INSTALLERURL="http://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-rhe5.$URLBITS.rpm"

    # because only RHEL style dist is currently supported for RPM installs, then exit if not RHEL family
    if [ ! -f /etc/redhat-release ] ; then
      # Assume SUSE
      #  SUSE is the only other RPM based linux supported by BigFix that is not based upon the RHEL family
      INSTALLERURL=http://software.bigfix.com/download/bes/$URLMAJORMINOR/BESAgent-$URLVERSION-sle11.$URLBITS.rpm
      # TODO: could add support for SUSE 10, but 11+ should work with the above.
    fi # END_IF not-RHEL-family
  fi # END_IF exists rpm

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
  mkdir $INSTALLDIR
fi


#### Downloads #############################################
DLEXITCODE=0
if command_exists curl ; then
  # Download the BigFix agent (using cURL because it is on most Linux & OS X by default)
  curl -o $INSTALLER $INSTALLERURL
  # http://stackoverflow.com/questions/6348902/how-can-i-add-numbers-in-a-bash-script
  DLEXITCODE=$(( DLEXITCODE + $? ))
  # Download the masthead, renamed, into the correct location
  # TODO: get masthead from CWD instead if present
  # http://unix.stackexchange.com/questions/60750/does-curl-have-a-no-check-certificate-option-like-wget
  #  the url for the masthead will not use a valid SSL certificate, instead it will use one tied to the masthead itself
  curl --insecure -o $INSTALLDIR/actionsite.afxm $MASTHEADURL
  DLEXITCODE=$(( DLEXITCODE + $? ))
else
  if command_exists wget ; then
    # this is run if curl doesn't exist, but wget does
    # download using wget
    # http://stackoverflow.com/questions/16678487/wget-command-to-download-a-file-and-save-as-a-different-filename
    # https://www.gnu.org/software/wget/manual/html_node/HTTPS-_0028SSL_002fTLS_0029-Options.html
    wget $MASTHEADURL -O $INSTALLDIR/actionsite.afxm --no-check-certificate
    DLEXITCODE=$(( DLEXITCODE + $? ))

    wget $INSTALLERURL -O $INSTALLER
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
  # http://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
  (>&2 echo Download Failed. ExitCode=$DLEXITCODE)
  exit $DLEXITCODE
fi

# open up linux firewall to accept UDP 52311 - iptables
if command_exists iptables ; then
  iptables -A INPUT -p udp --dport 52311 -j ACCEPT
fi
# open up linux firewall to accept UDP 52311 - firewall-cmd
if command_exists firewall-cmd ; then
  firewall-cmd --zone=public --add-port=52311/udp --permanent
fi
# open up linux firewall to accept UDP 52311 - firewall-offline-cmd
if command_exists firewall-offline-cmd ; then
  # this applies in anaconda at install time in particular
  firewall-offline-cmd --add-port=52311/udp
fi

# install BigFix client
if [[ $INSTALLER == *.deb ]]; then
  #  debian (DEB)
  dpkg -i $INSTALLER
fi
if [[ $INSTALLER == *.pkg ]]; then
  # PKG type
  #   Could be Mac OS X, Solaris, or AIX
  if command_exists installer ; then
    #  Mac OS X
    installer -pkg $INSTALLER -target /
  else
    if command_exists pkgadd ; then
        # TODO: test case for Solaris
        pkgadd -d $INSTALLER
    fi # pkgadd
  fi # installer
fi # *.pkg install file
if [[ $INSTALLER == *.rpm ]]; then
  #  linux (RPM)
  # if file `/etc/init.d/besclient` exists then do upgrade
  if [ -f /etc/init.d/besclient ]; then
    /etc/init.d/besclient stop
    rpm -U $INSTALLER
  else
    rpm -ivh $INSTALLER
  fi
fi

### start the BigFix client (required for most linux dist)
# if file `/etc/init.d/besclient` exists
if [ -f /etc/init.d/besclient ]; then
  # if missing, create besclient.config file based upon /tmp/clientsettings.cfg
  if [ ! -f /var/opt/BESClient/besclient.config ]; then
    cat /tmp/clientsettings.cfg | awk 'BEGIN { print "[Software\\BigFix\\EnterpriseClient]"; print "EnterpriseClientFolder = /opt/BESClient"; print; print "[Software\\BigFix\\EnterpriseClient\\GlobalOptions]"; print "StoragePath = /var/opt/BESClient"; print "LibPath = /opt/BESClient/BESLib"; } /=/ {gsub(/=/, " "); print "\n[Software\\BigFix\\EnterpriseClient\\Settings\\Client\\" $1 "]\nvalue = " $2;}' > /var/opt/BESClient/besclient.config
    chmod 600 /var/opt/BESClient/besclient.config
  fi

  # Do not start bigfix if: StartBigFix=false
  if [[ "$StartBigFix" != "false" ]]; then
    /etc/init.d/besclient start
  fi
fi

# pause 5 seconds to wait for bigfix to get going a bit
sleep 5

# output the contents of the log file to see if things are working:  https://github.com/jgstew/tools/blob/master/bash/bigfixlogs.sh
# TODO: add mac support to the following:
if [ -f "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log" ]; then
  tail --lines=25 --verbose "/var/opt/BESClient/__BESData/__Global/Logs/`date +%Y%m%d`.log"

  # Related:
  #  - https://bigfix.me/fixlet/details/24646
  #  - https://bigfix.me/relevance/details/3020387
fi

### References:
# - http://stackoverflow.com/questions/733824/how-to-run-a-sh-script-in-an-unix-console-mac-terminal
# - http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
# - http://wiki.bash-hackers.org/scripting/posparams
# - http://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
# - http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# - https://forum.bigfix.com/t/script-to-kickstart-the-installation-of-bigfix-on-os-x-debian-family-rhel-family/17023
# - http://stackoverflow.com/questions/30557508/bash-checking-if-string-does-not-contain-other-string
