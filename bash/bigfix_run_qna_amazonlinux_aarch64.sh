# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_amazonlinux_aarch64.sh
# bash bigfix_run_qna_amazonlinux_aarch64.sh

# NOTE: the only 64-bit ARM (aarch64) BigFix agent is the Amazon Linux 2 rpm.
#       There is currently no rhe*/debian* aarch64 agent build.

args=$*

if ! [ -d /tmp/qna ]; then
mkdir /tmp/qna
fi

if ! [ -f /tmp/qna/BESAgent-al2.aarch64.rpm ]; then
curl -o /tmp/qna/BESAgent-al2.aarch64.rpm https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-al2.aarch64.rpm
fi

cd /tmp/qna

# https://stackoverflow.com/questions/18787375/how-do-i-extract-the-contents-of-an-rpm
rpm2cpio /tmp/qna/BESAgent-al2.aarch64.rpm | cpio -imvud

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/qna/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/qna/opt/BESClient/bin/qna -showtypes
fi
