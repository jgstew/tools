# Turn `yara -s` / `yr scan -s` output of php_detect.yar into "path<TAB>version".
#   yara -s -r php_detect.yar /opt 2>/dev/null | awk -f php_versions.awk | sort -u
# Handles paths with spaces and the UTF-16 ProductVersion match ($pv), which
# yara prints with escaped NULs (8\x00.\x002\x00...). Matched files with no
# version string (e.g. Linux extensions) get "unknown".

# rule line: "<RULE> <path>", or with yr --print-meta "<RULE> [meta...] <path>"
/^PHP_/ { file = $0; sub(/^[^ ]+ /, "", file); sub(/^\[[^]]*\] /, "", file); seen[file] = 1; next }

# string line: "0xOFFSET:$id: <matched text>"
/:\$(ver|pv|cfg_ver|hdr_ver): / {
  v = $0; gsub(/\\x00/, "", v); sub(/^[^ ]+ /, "", v)
  if (match(v, /[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+~_-]*/)) { print file "\t" substr(v, RSTART, RLENGTH); versioned[file] = 1 }
}

END { for (f in seen) if (!(f in versioned)) print f "\tunknown" }
