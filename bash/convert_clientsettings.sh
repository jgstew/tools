#!/usr/bin/env bash
# see related script: https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

# either take file location as argument, or assume current folder
if [ -n "$1" ]; then
  CLIENTSETTINGSFILE=$1
else
  CLIENTSETTINGSFILE=clientsettings.cfg
fi

# either take file location as argument, or assume current folder
if [ -n "$2" ]; then
  OUTPUTFILE=$2
else
  OUTPUTFILE=besclient.config
fi

# check that AWK & SED are present
if command_exists awk && command_exists sed; then
  if [ -f $CLIENTSETTINGSFILE ] ; then
    cat $CLIENTSETTINGSFILE | awk 'BEGIN { print "[Software\\BigFix\\EnterpriseClient]"; print "EnterpriseClientFolder = /opt/BESClient"; print; print "[Software\\BigFix\\EnterpriseClient\\GlobalOptions]"; print "StoragePath = /var/opt/BESClient"; print "LibPath = /opt/BESClient/BESLib"; } /=/ {gsub(/=/, " "); print "\n[Software\\BigFix\\EnterpriseClient\\Settings\\Client\\" $1 "]\neffective date = \nvalue = " $2;}' | sed "s/effective\ date\ =\ /effective\ date\ =\ $(date +'%a, %d %b %Y %T %z')/"
  fi
else
  echo AWK and/or SED missing!
  echo cant continue, exiting.
  exit 1
fi
