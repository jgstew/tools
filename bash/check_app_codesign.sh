
# Check signatures of /Applications
# https://stackoverflow.com/a/20292636
# https://macadmins.slack.com/archives/C066MCBT2/p1499952935591722
cd /Applications && find . -maxdepth 1 -type d \( ! -name . \) -exec sh -c 'spctl --assess "{}"' \;
