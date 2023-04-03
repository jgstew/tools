#!/usr/bin/env bash

# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/openQnA.sh

# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations
QNAPATH="./qna"

if [ -f '/c/Program Files (x86)/BigFix Enterprise/BES Client/qna' ]; then
  QNAPATH="/c/Program Files (x86)/BigFix Enterprise/BES Client/qna"
  "$QNAPATH" -showtypes
fi

if [ -f /opt/BESClient/bin/qna ]; then
  QNAPATH="/opt/BESClient/bin/qna"
fi

if [ -f /Library/BESAgent/BESAgent.app/Contents/MacOS/QnA ]; then
  QNAPATH="/Library/BESAgent/BESAgent.app/Contents/MacOS/QnA"
fi

sudo $QNAPATH -showtypes
