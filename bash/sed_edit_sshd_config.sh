
# WARNING: `-i ''` causes this to directly overwrite the existing file with changes on macOS
#    Note: on Linux, use `-i` only  instead of `-i ''` on macOS
sed -i  /\(^ChallengeResponseAuthentication *\).*/ s//\1yes/ sshd.conf
