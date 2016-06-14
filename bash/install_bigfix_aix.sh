#!/usr/bin/env bash
# kickstart bigfix install

# AIX 7.2 does seem to have bash in addition to sh, though sh is the default

# wget is preinstalled, curl is not (normal)
# having trouble downloading the script with wget :(
#  whenever downloading over https, wget gives the error messagine `- : Unsupported scheme.`
#    this is probably an HTTPS issue, need to try `--no-check-certificate` (Didn't work)
#    the `--no-check-certificate` option is not available for the wget that ships with AIX 7.2
#
#  http://www.bullfreeware.com/affichage.php?id=2401
#  http://www.bullfreeware.com/download/bin/2401/wget-1.17.1-1.aix6.1.ppc.rpm

# python -c "import urllib; print urllib.urlopen('https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix_aix.sh').read()" > install_bigfix_aix.sh

# `uname` = AIX
# `uname -p` = powerpc
# OSTYPE & HOSTTYPE don't work in SH on AIX

command_exists () {
  type "$1" &> /dev/null ;
}

OSAIX = `uname`
echo $OSAIX

# References:
#   http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
