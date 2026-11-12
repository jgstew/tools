# Turn `yara -s` / `yr scan -s` output of php/php_detect.yar,
# node/node_detect.yar and apache/apache_detect.yar into
# "path<TAB>product<TAB>version", one line per product found in a file
# (product: php, node, electron, apache or mod_http2):
#   yr scan -s -r php/php_detect.yar node/node_detect.yar apache/apache_detect.yar /opt 2>/dev/null | awk -f versions.awk | sort -u
# Handles paths with spaces and the UTF-16 ProductVersion match ($pv), which
# yara prints with escaped NULs (8\x00.\x002\x00...). Matched files with no
# version string (e.g. Linux PHP extensions, Node addons) get "unknown".
# Versions: php from $ver / $pv; node from $ver (node.js/v...), or from $rel
# (the release URL) when no $ver matched; electron from $electron, so an
# Electron framework gets a node and an electron line; apache from $ver
# (Apache/...); mod_http2 from $_module_ver (a candidate, see apache_detect.yar).

# rule line: "<RULE> <path>", or with yr --print-meta "<RULE> [meta...] <path>"
/^(PHP|Node|Apache)_/ {
  prod = /^PHP_/ ? "php" : /^Node_/ ? "node" : /^Apache_HTTP2_/ ? "mod_http2" : "apache"
  file = $0; sub(/^[^ ]+ /, "", file); sub(/^\[[^]]*\] /, "", file); seen[file SUBSEP prod] = 1; next
}

# string line: "0xOFFSET:$id: <matched text>"
/:\$(ver|pv|rel|electron|_module_ver): / {
  v = $0; gsub(/\\x00/, "", v)
  id = v; sub(/: .*/, "", id); sub(/.*\$/, "", id)
  sub(/^[^ ]+ /, "", v)
  if (!match(v, /[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+~_-]*/)) next
  v = substr(v, RSTART, RLENGTH)
  if (id == "electron") print file "\telectron\t" v
  else if (id == "rel") rel[file SUBSEP prod SUBSEP v] = 1
  else { print file "\t" prod "\t" v; versioned[file SUBSEP prod] = 1 }
}

END {
  for (k in rel) {
    split(k, a, SUBSEP)
    if (!((a[1] SUBSEP a[2]) in versioned)) { print a[1] "\t" a[2] "\t" a[3]; fromrel[a[1] SUBSEP a[2]] = 1 }
  }
  for (k in seen) {
    split(k, a, SUBSEP)
    if (!(k in versioned) && !(k in fromrel)) print a[1] "\t" a[2] "\tunknown"
  }
}
