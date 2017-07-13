
cd /Applications && find . -maxdepth 1 -type d \( ! -name . \) -exec sh -c 'spctl --assess "{}"' \;
