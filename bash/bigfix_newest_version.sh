#!/usr/bin/env bash
# https://github.com/jgstew/tools/issues/9


# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

if [ -n "$1" ]; then
  HTMLURL=$1
else
  HTMLURL=http://support.bigfix.com/bes/release/index.html
fi

if command_exists curl ; then
  curl -s -O $HTMLURL 2>&1 >/dev/null
else
  if command_exists wget ; then
    wget $HTMLURL 2>&1 >/dev/null
  else
    echo neither wget nor curl is installed.
    echo not able to download required files.
    echo exiting...
    exit 2
  fi
fi

echo `cat index.html | grep -m 16 -i -o -P -e '<td align="left">\d+\.\d+\.\d+\.\d+<\/td>' | grep -o -P -e '\d+\.\d+\.\d+\.\d+' | sort -r -V | uniq -c | grep -m 1 -i "4 " | grep -o -P -e '\d+\.\d+\.\d+\.\d+'`
