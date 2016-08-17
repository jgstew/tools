
sudo docker run -d ubuntu bash -c "apt-get update;apt-get install wget -y;wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh;chmod u+x install_bigfix.sh;./install_bigfix.sh alpha.bigfix.com;tail -f /dev/null"
