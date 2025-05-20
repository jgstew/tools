# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_macos.sh
# sudo bash bigfix_run_qna_macos.sh

args=$*

mkdir -p /tmp/bigfix_qna

if ! [ -f /tmp/bigfix_qna/BigFix_MacOS.pkg ]; then
curl -o /tmp/bigfix_qna/BigFix_MacOS.pkg https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60-BigFix_MacOS11.0.pkg
fi

# extract pkg file
xar -xf /tmp/bigfix_qna/BigFix_MacOS.pkg -C /tmp/bigfix_qna
# extract sub pkg payload
cd /tmp/bigfix_qna && bash -c "cat /tmp/bigfix_qna/besagent.pkg/Payload | gunzip -dc | cpio -i"

# cleanup
rm /tmp/bigfix_qna/Distribution
rm -rf /tmp/bigfix_qna/Resources
rm -rf /tmp/bigfix_qna/besagent.pkg
rm -rf /tmp/bigfix_qna/besagentdaemon.pkg
rm -rf /tmp/bigfix_qna/swidtag.pkg
rm -rf /tmp/bigfix_qna/triggerclientui.pkg

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
/tmp/bigfix_qna/BESAgent.app/Contents/MacOS/QnA -showtypes
else
echo $args | /tmp/bigfix_qna/BESAgent.app/Contents/MacOS/QnA -showtypes
fi

# cleanup
rm -rf /tmp/bigfix_qna/BESAgent.app
