# Turn `yara -s php_detect.yar ...` output into "path<TAB>version" lines.
#   yara -s -r php_detect.yar /opt 2>/dev/null | awk -f php_versions.awk | sort -u
# Handles paths with spaces and the UTF-16 ProductVersion match ($pv), which
# yara prints with escaped NULs (8\x00.\x002\x00...).

# rule line: "<RULE> <path>"
/^PHP_/ { file = $0; sub(/^[^ ]+ /, "", file); next }

# string line: "0xOFFSET:$id: <matched text>"
/:\$(ver|pv|cfg_ver|hdr_ver): / {
  v = $0; gsub(/\\x00/, "", v); sub(/^[^ ]+ /, "", v)
  if (match(v, /[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+~_-]*/)) print file "\t" substr(v, RSTART, RLENGTH)
}
