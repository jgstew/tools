
args=$*

if ! [ -f /tmp/qna ]; then
mkdir /tmp/qna
fi

if ! [ -f /tmp/qna/BESAgent-rhe6.x86_64.rpm ]; then
curl -o /tmp/qna/BESAgent-rhe6.x86_64.rpm https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-rhe7.x86_64.rpm
fi

cd /tmp/qna

# https://stackoverflow.com/questions/18787375/how-do-i-extract-the-contents-of-an-rpm
rpm2cpio /tmp/qna/BESAgent-rhe6.x86_64.rpm | cpio -imvud

# rm --dir /tmp/lib

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/qna/opt/BESClient/bin/qna -showtypes
else
echo $args | /tmp/qna/opt/BESClient/bin/qna -showtypes
fi
