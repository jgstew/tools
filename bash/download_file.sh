#!/usr/bin/env bash
# https://github.com/jgstew/tools/issues/10
# https://github.com/jgstew/tools/issues/7

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

  # https://www.mattcutts.com/blog/how-to-fetch-a-url-with-curl-or-wget-silently/
  if command_exists curl ; then
    if [ -n "$2" ]; then
      curl -silent -o "$2" "$1"
    else
      curl -silent -O "$1"
    fi
  else
    if command_exists wget ; then
      if [ -n "$2" ]; then
        wget "$1" -quiet -O "$2"
      else
        wget "$1" -quiet
      fi
    else
      echo neither wget nor curl is installed.
      echo not able to download required files.
      echo exiting...
      exit 2
    fi
  fi
  # TODO: handle error conditions
  # https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html
  # http://stackoverflow.com/questions/1378274/in-a-bash-script-how-can-i-exit-the-entire-script-if-a-certain-condition-occurs
exit $?
