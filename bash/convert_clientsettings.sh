#!/usr/bin/env bash
# see the issue this solves:  https://github.com/jgstew/tools/issues/4
# see related script:  https://github.com/jgstew/tools/blob/master/bash/install_bigfix.sh

# Ensure we are actually running under bash, not sh/dash/ash.
#  $BASH_VERSION is unset in any non-bash shell.
#  This guard must stay pure POSIX (no [[ ]], no &>) so sh can parse it,
#   then it transparently re-executes the script under bash if available.
# see the issue this solves:  https://github.com/jgstew/tools/issues/20
if [ -z "$BASH_VERSION" ]; then
  if command -v bash >/dev/null 2>&1; then
    exec bash "$0" "$@"
  fi
  echo "ERROR: this script requires bash (it uses &>)." >&2
  echo "       Re-run as: bash $0 $*" >&2
  exit 1
fi

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

# FUNCTION: convert clientsettings.cfg to besclient.config format
convert_clientsettings () {
  awk 'BEGIN { print "[Software\\BigFix\\EnterpriseClient]"; print "EnterpriseClientFolder = /opt/BESClient"; print; print "[Software\\BigFix\\EnterpriseClient\\GlobalOptions]"; print "StoragePath = /var/opt/BESClient"; print "LibPath = /opt/BESClient/BESLib"; } /=/ {gsub(/=/, " "); print "\n[Software\\BigFix\\EnterpriseClient\\Settings\\Client\\" $1 "]\nvalue = " $2;}' "$CLIENTSETTINGSFILE"
}

# check that AWK is present
if command_exists awk ; then
  if [ -f "$CLIENTSETTINGSFILE" ] ; then
    # only redirect to OUTPUTFILE if second argument was explicitly given,
    #  otherwise write to stdout so existing pipe/redirect usage keeps working
    # see the issue this solves:  https://github.com/jgstew/tools/issues/12
    if [ -n "$2" ]; then
      convert_clientsettings > "$OUTPUTFILE"
    else
      convert_clientsettings
    fi
  else
    (>&2 echo "input file not found: $CLIENTSETTINGSFILE")
    exit 1
  fi
else
  (>&2 echo "AWK is missing!")
  (>&2 echo "can not continue, exiting.")
  exit 1
fi
