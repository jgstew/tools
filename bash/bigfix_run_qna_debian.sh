if ! [ -f /tmp/BESAgent-debian.deb ]; then
curl -o /tmp/BESAgent-debian.deb https://software.bigfix.com/download/bes/100/BESAgent-10.0.9.21-debian6.amd64.deb
fi

ar x /tmp/BESAgent-debian.deb --output=/tmp

tar --overwrite --extract --file=/tmp/data.tar.gz --directory=/tmp --exclude=var* --exclude=etc* --exclude=lib*

/tmp/opt/BESClient/bin/qna -showtypes
