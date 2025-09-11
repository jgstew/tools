#!/usr/bin/env bash
# https://github.com/jgstew/tools/issues/9

# also works with:  https://www.mozilla.org/en-US/firefox/releases/

HTMLTMPFILE=newest_version_tmp.html

# http://stackoverflow.com/questions/592620/check-if-a-program-exists-from-a-bash-script
# FUNCTION: check if command exists
command_exists () {
  type "$1" &> /dev/null ;
}

download_file () {
  # https://www.mattcutts.com/blog/how-to-fetch-a-url-with-curl-or-wget-silently/
  if command_exists curl ; then
    curl -silent -o $HTMLTMPFILE "$1"
  else
    if command_exists wget ; then
      wget "$1" -quiet -O $HTMLTMPFILE
    else
      echo neither wget nor curl is installed.
      echo not able to download required files.
      echo exiting...
      exit 2
    fi
  fi
  # TODO: handle error conditions
  # https://www.gnu.org/software/wget/manual/html_node/Exit-Status.html
}

if [ -n "$1" ]; then
  download_file $1
  #  TODO: this currently only handles the format `>version<` but could also handle `"version"` or similar.
  #        it is extremely difficult to build a regex that could handle all versions reliably.
  echo `cat $HTMLTMPFILE | grep -o -P -e '>\d{1,2}\.\d{1,2}\.?\d*\.?\d*<' | grep -o -P -e '\d{1,2}\.\d{1,2}\.?\d*\.?\d*' | sort -r -V | grep -m 1 -i "."`
else
  download_file https://support.bigfix.com/bes/release/index.html
  echo `cat $HTMLTMPFILE | grep -m 16 -i -o -P -e '>\d+\.\d+\.\d+\.\d+<\/td>' | grep -o -P -e '\d+\.\d+\.\d+\.\d+' | sort -r -V | uniq -c | grep -m 1 -i "4 " | grep -o -P -e '\d+\.\d+\.\d+\.\d+'`
fi

rm newest_version_tmp.html
