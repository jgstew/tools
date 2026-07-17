# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_raspbian.sh
# bash bigfix_run_qna_raspbian.sh

args=$*

# prereqs: (needed on docker / minimal raspios)
#   apt-get install -y curl binutils xz-utils

# Raspberry Pi OS / Raspbian is 32-bit ARM (armhf)
if ! [ -f /tmp/BESAgent-raspbian.deb ]; then
curl -o /tmp/BESAgent-raspbian.deb https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-raspbian10.armhf.deb
fi

# https://www.cyberciti.biz/faq/how-to-extract-a-deb-file-without-opening-it-on-debian-or-ubuntu-linux/
ar x /tmp/BESAgent-raspbian.deb --output=/tmp

ls /tmp

tar --overwrite --extract --file=/tmp/data.tar.xz --directory=/tmp --exclude=var* --exclude=etc* --exclude=lib/*

rm /tmp/control.tar.xz
rm /tmp/data.tar.xz
rm /tmp/debian-binary
rm --dir /tmp/lib

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/opt/BESClient/bin/qna -showtypes
fi
