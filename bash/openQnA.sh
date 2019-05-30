#!/usr/bin/env bash

# https://www.ibm.com/developerworks/community/wikis/home?lang=en#!/wiki/Tivoli+Endpoint+Manager/page/Common+File+Locations
QNAPATH="./qna"

if [ -f /Library/BESAgent/BESAgent.app/Contents/MacOS/QnA ]; then
  QNAPATH="/Library/BESAgent/BESAgent.app/Contents/MacOS/QnA"
else
  QNAPATH="/opt/BESClient/bin/qna"
fi

$QNAPATH -showtypes
