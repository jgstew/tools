#!/usr/bin/env bash
# kickstart bigfix install
# current target - ubuntu/debian
# 
# Reference: https://support.bigfix.com/bes/install/besclients-nonwindows.html
#
# Usage:
#   wget install_bigfix_ubuntu.sh
#   chmod u+x install_bigfix_ubuntu.sh
#   ./install_bigfix_ubuntu.sh

# NOTE: AMD64 compatible OS architecture is assumed (x86, Itanium, and Power are not common, but could be added)

# TODO: if Mac OS X then get clientsettings.cfg from CWD or create a default one
# TODO: add commands to open up firewall to incoming UDP 52311 on Linux

# TODO: use the masthead file in current directory if present

command_exists () {
  type "$1" &> /dev/null ;
}

if [ ! -z "$1" ]; then
  MASTHEADURL="http://$1:52311/masthead/masthead.afxm"
  echo MASTHEAD=$MASTHEADURL
fi

# MUST HAVE ROOT PRIV
if [ "$(id -u)" != "0" ]; then
  echo "Sorry, you are not root."
  exit 1
fi

# use this to check if Mac (darwin)
echo $OSTYPE

############################################################
# TODO: these vars need to change based upon OS dist

if [[ $OSTYPE == darwin* ]]; then
  # Mac OS X
  INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-BigFix_MacOSX10.7.pkg"
  INSTALLDIR="/tmp"
  INSTALLER="/tmp/BESAgent.pkg"
else
  # For most Linux:
  INSTALLDIR="/etc/opt/BESClient"

  # if Debian based
  INSTALLER="BESAgent.deb"

  # Debian
  INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-debian6.amd64.deb"
  # Ubuntu
  INSTALLERURL="http://software.bigfix.com/download/bes/95/BESAgent-9.5.1.9-ubuntu10.amd64.deb"

fi # END_IF darwin
############################################################


# Create $INSTALLDIR folder if missing
if [ ! -d "$INSTALLDIR" ]; then
  # Control will enter here if $INSTALLDIR doesn't exist.
  mkdir $INSTALLDIR
fi

# Download the BigFix agent (using cURL because it is on most Linux & OS X by default)
# TODO: if curl not present, use wget instead
curl -o $INSTALLER $INSTALLERURL
# Download the masthead, renamed, into the correct location
# TODO: get masthead from CWD instead if present
curl -o $INSTALLDIR/actionsite.afxm $MASTHEADURL


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
  rpm -ivh $INSTALLER
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
