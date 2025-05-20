
args=$*

# prereqs: (needed on docker)
#   apt-get install -y curl binutils xz-utils

if ! [ -f /tmp/BESAgent-ubuntu.deb ]; then
curl -o /tmp/BESAgent-ubuntu.deb https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-ubuntu18.amd64.deb
fi

# https://www.cyberciti.biz/faq/how-to-extract-a-deb-file-without-opening-it-on-debian-or-ubuntu-linux/
ar x /tmp/BESAgent-ubuntu.deb --output=/tmp

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
