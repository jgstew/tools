# usage:
# curl -O https://raw.githubusercontent.com/jgstew/tools/master/bash/bigfix_run_qna_aix.sh
# bash bigfix_run_qna_aix.sh
#
# !!! UNTESTED !!!
# AIX runs on IBM POWER hardware. There is no GitHub Actions runner, no
# vmactions VM, and no practical QEMU image for AIX, so this script cannot be
# exercised in CI. It mirrors the approach of the other scripts and is provided
# for completeness / manual use on a real AIX host. The extraction path may
# need adjustment, which is why the qna binary is located with `find` below.

args=$*

if ! [ -d /tmp/qna ]; then
mkdir /tmp/qna
fi

# AIX installp package (backup-by-name format, extractable with `restore`)
if ! [ -f /tmp/qna/BESAgent-aix.pkg ]; then
curl -o /tmp/qna/BESAgent-aix.pkg https://software.bigfix.com/download/bes/110/BESAgent-11.0.4.60.ppc64_aix71.pkg
fi

cd /tmp/qna

# extract the backup-format installp image without installing it.
# https://www.ibm.com/docs/en/aix/7.1?topic=r-restore-command
restore -xvqf /tmp/qna/BESAgent-aix.pkg

# BigFix installs qna to /opt/BESClient/bin/qna ; locate it wherever restore put it
QNA=$(find /tmp/qna -type f -name qna 2>/dev/null | head -1)

# get arg length
len=${#args}
if [ $len -lt 3 ]; then
"$QNA" -showtypes
else
echo $args | "$QNA" -showtypes
fi
