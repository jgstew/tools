
# WARNING: `-i ''` causes this to directly overwrite the existing file with changes on macOS
#    Note: on Linux, use `-i` only  instead of `-i ''` on macOS
sed -i '' '/\(^use_fully_qualified_names *= *\).*/ s//\1False/' sssd.conf


# References:
# - https://stackoverflow.com/questions/7573368/in-place-edits-with-sed-on-os-x
# - https://stackoverflow.com/questions/20568515/how-to-use-sed-to-replace-a-config-files-variable
# - https://stackoverflow.com/questions/19567275/modifying-ini-files-using-shell-script
# - https://stackoverflow.com/questions/2464760/modify-config-file-using-bash-script
