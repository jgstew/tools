:<<"::CMDLITERAL"
@ECHO OFF
REM  Usage: 
REM powershell -command "& { (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/jgstew/tools/master/CMD/install_bigfix.bat', 'install_bigfix.bat') }" -ExecutionPolicy Bypass
REM install_bigfix.bat __FQDN_OF_ROOT_OR_RELAY__

REM    Source: https://github.com/jgstew/tools/blob/master/CMD/install_bigfix.bat
REM   Related: https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh

REM http://stackoverflow.com/questions/2541767/what-is-the-proper-way-to-test-if-variable-is-empty-in-a-batch-file-if-not-1
IF [%1] == [] ECHO please provide FQDN for root or relay && EXIT /B
REM KNOWN ISSUE: if enhanced security is enabled on root/relay, then must use HTTPS for masthead download. This will mean that the download part will have to ignore SSL errors
SET MASTHEADURL=http://%1:52311/masthead/masthead.afxm
SET BASEFOLDER=C:\Windows\Temp

REM  TODO: handle clientsettings.cfg or masthead.afxm or actionsite.afxm already in the CWD
REM  TODO: check for admin rights http://stackoverflow.com/questions/4051883/batch-script-how-to-check-for-admin-rights

REM http://stackoverflow.com/questions/4781772/how-to-test-if-an-executable-exists-in-the-path-from-a-windows-batch-file
where /q powershell || ECHO Cound not find powershell. && EXIT /B

@ECHO ON
REM this following line will need to ignore SSL errors if HTTPS is used instead of HTTP
powershell -command "& { (New-Object Net.WebClient).DownloadFile('%MASTHEADURL%', '%BASEFOLDER%\actionsite.afxm') }" -ExecutionPolicy Bypass
powershell -command "& { (New-Object Net.WebClient).DownloadFile('http://software.bigfix.com/download/bes/95/BigFix-BES-Client-9.5.1.9.exe', '%BASEFOLDER%\BESClient.exe') }" -ExecutionPolicy Bypass
@ECHO OFF

REM https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli%20Endpoint%20Manager/page/Configuration%20Settings
REM https://gist.github.com/jgstew/51a99ab4b5997efa0318
REM http://stackoverflow.com/questions/1702762/how-to-create-an-empty-file-at-the-command-line-in-windows
REM http://stackoverflow.com/questions/7225630/how-to-echo-2-no-quotes-to-a-file-from-a-batch-script
type NUL > %BASEFOLDER%\clientsettings.cfg
REM  TODO: only do the following line if FQDN_variable is set
>>%BASEFOLDER%\clientsettings.cfg ECHO _BESClient_RelaySelect_FailoverRelay=http://%1:52311/bfmirror/downloads/
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

EXIT /B
::CMDLITERAL

#!/usr/bin/env bash
# kickstart bigfix install
# current target - Mac OS X, Debian, Ubuntu, RHEL, CentOS, Fedora
# 
# Reference: https://support.bigfix.com/bes/install/besclients-nonwindows.html
#
# Usage:
#   curl -o install_bigfix.sh https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh
#   chmod u+x install_bigfix.sh
#   ./install_bigfix.sh __ROOT_OR_RELAY_FQDN__
#
# Single Line:
#  curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh ; chmod u+x install_bigfix.sh ; ./install_bigfix.sh __ROOT_OR_RELAY_FQDN__

# NOTE: AMD64 compatible OS architecture is assumed (x86, Itanium, and Power are not common, but could be added)

# TODO: if Mac OS X then get clientsettings.cfg from CWD (currently creating a default one)

# TODO: use the masthead file in current directory if present

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

# if $1 exists, then set MASTHEADURL
# http://www.tldp.org/LDP/abs/html/comparison-ops.html
if [ -n "$1" ]; then
  MASTHEADURL="http://$1:52311/masthead/masthead.afxm"
fi

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

if [[ $OSTYPE == darwin* ]]; then
  # Mac OS X
  INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-BigFix_MacOSX10.7.pkg"
  INSTALLDIR="/tmp"
  INSTALLER="/tmp/BESAgent.pkg"
  
  # create clientsettings.cfg file
  echo -n > $INSTALLDIR/clientsettings.cfg
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_RelaySelect_FailoverRelay=http://$1:52311/bfmirror/downloads/
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_StartupNormalSpeed=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_RetryMinutes=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_WorkIdle=20
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Resource_SleepIdle=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollEnable=1
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Comm_CommandPollIntervalSeconds=10800
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Log_Days=30
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_UtilitiesCacheLimitMB=500
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_DownloadsCacheLimitMB=5000
  >> $INSTALLDIR/clientsettings.cfg echo _BESClient_Download_MinimumDiskFreeMB=2000
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
      INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-ubuntu10.$URLBITS.deb"
    else
      # Debian
      INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-debian6.$URLBITS.deb"
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
    
    INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-rhe5.$URLBITS.rpm"
    
    # because only RHEL style dist is currently supported for RPM installs, then exit if not RHEL family
    if [ ! -f /etc/redhat-release ] ; then
      echo Only RHEL, CentOS, or Fedora currently supported for RPM installs
      exit 1
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

if command_exists curl ; then
  # Download the BigFix agent (using cURL because it is on most Linux & OS X by default)
  curl -o $INSTALLER $INSTALLERURL
  # Download the masthead, renamed, into the correct location
  # TODO: get masthead from CWD instead if present
  # http://unix.stackexchange.com/questions/60750/does-curl-have-a-no-check-certificate-option-like-wget
  #  the url for the masthead will not use a valid SSL certificate, instead it will use one tied to the masthead itself
  curl --insecure -o $INSTALLDIR/actionsite.afxm $MASTHEADURL
  # TODO: add error checking to ensure masthead was downloaded
else
  if command_exists wget ; then
    # this is run if curl doesn't exist, but wget does
    # download using wget
    # http://stackoverflow.com/questions/16678487/wget-command-to-download-a-file-and-save-as-a-different-filename
    # https://www.gnu.org/software/wget/manual/html_node/HTTPS-_0028SSL_002fTLS_0029-Options.html
    wget $MASTHEADURL -O $INSTALLDIR/actionsite.afxm --no-check-certificate
    # TODO: add error checking to ensure masthead was downloaded
    wget $INSTALLERURL -O $INSTALLER
  else
    echo neither wget nor curl is installed.
    echo not able to download required files.
    echo exiting...
    exit 2
  fi
fi

# open up linux firewall to accept UDP 52311 - iptables
if command_exists iptables ; then
  iptables -A INPUT -p udp --dport 52311 -j ACCEPT
fi
# open up linux firewall to accept UDP 52311 - firewall-cmd
if command_exists firewall-cmd ; then
  firewall-cmd --zone=public --add-port=52311/udp --permanent
fi

# install BigFix client
if [[ $INSTALLER == *.deb ]]; then
  #  debian (DEB)
  dpkg -i $INSTALLER
fi
if [[ $INSTALLER == *.pkg ]]; then
  #  Mac OS X (PKG)
  installer -pkg $INSTALLER -target /
  # TODO: add case for Solaris
  # pkgadd -d $INSTALLER  #  Solaris (PKG)
fi
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
  /etc/init.d/besclient start
fi

### Referenes:
# - http://stackoverflow.com/questions/733824/how-to-run-a-sh-script-in-an-unix-console-mac-terminal
# - http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
# - http://wiki.bash-hackers.org/scripting/posparams
# - http://stackoverflow.com/questions/6482377/check-existence-of-input-argument-in-a-bash-shell-script
# - http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# - https://forum.bigfix.com/t/script-to-kickstart-the-installation-of-bigfix-on-os-x-debian-family-rhel-family/17023
# - http://stackoverflow.com/questions/30557508/bash-checking-if-string-does-not-contain-other-string
