# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_rhel_s390x.sh
# bash bigfix_run_qna_rhel_s390x.sh

# IBM Z (s390x) - RHEL family rpm

args=$*

if ! [ -d /tmp/qna ]; then
mkdir /tmp/qna
fi

if ! [ -f /tmp/qna/BESAgent-s390x.rpm ]; then
curl -o /tmp/qna/BESAgent-s390x.rpm https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-rhe7.s390x.rpm
fi

cd /tmp/qna

# https://stackoverflow.com/questions/18787375/how-do-i-extract-the-contents-of-an-rpm
rpm2cpio /tmp/qna/BESAgent-s390x.rpm | cpio -imvud

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/qna/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/qna/opt/BESClient/bin/qna -showtypes
fi
