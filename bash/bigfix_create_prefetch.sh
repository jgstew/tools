#!/usr/bin/env bash
# This script was tested on MacOS, but should work on any bash.

# get first argument as filepath, must enclose filepath in quotes.
File=$1

# get string following last `/` character:
FileName=`echo "$File" | rev | cut -d "/" -f1 | rev`

# subtitute spaces for underscores:
FileName=`tr -s ' ' '_' <<< "$FileName"`

echo "prefetch $FileName sha1:`shasum $File | awk '{print $1}'` size:`ls -l $File | awk '{print $5}'` https://localhost:52311/Uploads/$FileName sha256:`shasum -a 256 $File | awk '{print $1}'`"
