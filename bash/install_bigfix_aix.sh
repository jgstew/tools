#!/usr/bin/env bash
# kickstart bigfix install

# AIX 7.2 does seem to have bash in addition to sh, though sh is the default
# wget is preinstalled, curl is not (normal)
# having trouble downloading the script with wget :(

# `uname` = AIX
# `uname -p` = powerpc
# OSTYPE & HOSTTYPE don't work in SH on AIX

command_exists () {
  type "$1" &> /dev/null ;
}

