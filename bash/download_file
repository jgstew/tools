#!/usr/bin/env bash
# https://github.com/jgstew/tools/issues/10
# https://github.com/jgstew/tools/issues/7

  # https://www.mattcutts.com/blog/how-to-fetch-a-url-with-curl-or-wget-silently/
  if command_exists curl ; then
    curl -silent -o $2 "$1"
  else
    if command_exists wget ; then
      wget "$1" -quiet -O $2
    else
      echo neither wget nor curl is installed.
      echo not able to download required files.
      echo exiting...
      exit 2
    fi
  fi
  # TODO: handle error conditions
  # https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html

