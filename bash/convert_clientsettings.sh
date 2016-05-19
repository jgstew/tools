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

# check that AWK & SED are present
if command_exists awk && command_exists sed; then
  echo AWK and SED present
else
  echo AWK and/or SED missing
  exit 1
fi
