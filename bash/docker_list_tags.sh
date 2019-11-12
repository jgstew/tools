#!/usr/bin/env bash

# Get Docker Registry Page, Parse Tags, Get Only Major # tags, Get Unique results
wget -q https://registry.hub.docker.com/v1/repositories/debian/tags -O -  | sed -e 's/[][]//g' -e 's/"//g' -e 's/ //g' | tr '}' '\n'  | awk -F: '{print $3}' | grep -o "^[0-9]*" | uniq


# References:
#     - https://stackoverflow.com/questions/28320134/how-can-i-list-all-tags-for-a-docker-image-on-a-remote-registry/51921869#51921869
#     - https://stackoverflow.com/questions/1898553/return-a-regex-match-in-a-bash-script-instead-of-replacing-it
#     - https://stackoverflow.com/questions/16327566/unique-lines-in-bash
