# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_rhel_ppc64le.sh
# bash bigfix_run_qna_rhel_ppc64le.sh

# IBM POWER little-endian (ppc64le) - RHEL family rpm

args=$*

if ! [ -d /tmp/qna ]; then
mkdir /tmp/qna
fi

if ! [ -f /tmp/qna/BESAgent-ppc64le.rpm ]; then
curl -o /tmp/qna/BESAgent-ppc64le.rpm https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-rhe7.ppc64le.rpm
fi

cd /tmp/qna

# https://stackoverflow.com/questions/18787375/how-do-i-extract-the-contents-of-an-rpm
rpm2cpio /tmp/qna/BESAgent-ppc64le.rpm | cpio -imvud

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/qna/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/qna/opt/BESClient/bin/qna -showtypes
fi
