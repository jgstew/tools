
############################################################
# WORK IN PROGRESS - UNTESTED!
# Run the BigFix Client on Ubuntu
#  - https://github.com/jgstew/tools/blob/master/bash/docker_bigfix_client.sh
############################################################

FROM ubuntu:latest

RUN apt-get update
RUN apt-get install wget -y
RUN wget https://raw.githubusercontent.com/jgstew/tools/master/bash/install_bigfix.sh

ENV BigFixRelay mybigfixrelay.local

RUN StartBigFix=false bash install_bigfix.sh $BigFixRelay

# incase SSH is installed later for debugging:
EXPOSE 22

# start bigfix client when container is started
# using this to make it keep running:  tail -f /dev/null
# could potentially use QnA to keep it running instead, which would be interesting
ENTRYPOINT bash -c "/etc/init.d/besclient start;tail -f /dev/null"
