# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_solaris.sh
# bash bigfix_run_qna_solaris.sh

args=$*

if ! [ -d /tmp/qna ]; then
mkdir /tmp/qna
fi

# Solaris 11 x86 SVR4 datastream package ( `file` reports: pkg Datastream (SVR4) )
if ! [ -f /tmp/qna/BESAgent-solaris.pkg ]; then
curl -o /tmp/qna/BESAgent-solaris.pkg https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60.x86_sol11.pkg
fi

# convert the datastream package into filesystem (spooled) format without installing it.
# absolute-path packages land under <dest>/<PKG>/root/... , so qna ends up at:
#   /tmp/qna/dest/BESagent/root/opt/BESClient/bin/qna
rm -rf /tmp/qna/dest
mkdir /tmp/qna/dest
# https://docs.oracle.com/cd/E36784_01/html/E36870/pkgtrans-1.html
pkgtrans /tmp/qna/BESAgent-solaris.pkg /tmp/qna/dest BESagent

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/qna/dest/BESagent/root/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/qna/dest/BESagent/root/opt/BESClient/bin/qna -showtypes
fi
