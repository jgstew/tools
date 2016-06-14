#!/usr/bin/env bash
# kickstart bigfix install

# AIX 7.2 does seem to have bash in addition to sh, though sh is the default

# python -c "import urllib; print urllib.urlopen('https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix_aix.sh').read()" > install_bigfix_aix.sh

# `uname` = AIX
# `uname -p` = powerpc
# OSTYPE & HOSTTYPE don't work in SH on AIX

command_exists () {
  type "$1" &> /dev/null ;
}

OSAIX=`uname`
echo $OSAIX

# References:
#   http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
