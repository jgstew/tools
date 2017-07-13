
# Check signatures of /Applications
# https://stackoverflow.com/a/20292636
cd /Applications && find . -iname \*.app -maxdepth 3 -type d \( ! -name . \) -exec sh -c 'spctl --assess "{}"' \;

# https://macadmins.slack.com/archives/C066MCBT2/p1499952935591722
# From elliot: find /Applications -iname *.app -maxdepth 3 -exec spctl --assess "{}" ';'
