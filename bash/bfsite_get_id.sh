# Related:
# - https://github.com/jgstew/tools/blob/master/Python/bfsite_get_id.py
# - https://github.com/jgstew/tools/blob/master/SQL/BigFix_ExternalSites_SiteIDs.sql

URL='https://sync.bigfix.com/cgi-bin/bfgather/patchesforubuntu2404'
curl -sSL "$URL" -o /tmp/site.smime

awk '
  /Content-Type: application\/x-pkcs7-signature/{sig=1; next}
  sig && /^$/{body=1; next}
  body { if ($0 ~ /^--/) exit; gsub(/\r/,""); if (length) print }
' /tmp/site.smime > /tmp/site.p7s.b64

base64 -D -i /tmp/site.p7s.b64 -o /tmp/site.p7s

openssl pkcs7 -inform DER -in /tmp/site.p7s -print_certs -text 2>/dev/null \
 | awk '
  /Serial Number:/ { sn=$0; next }
  /Subject:/       { print sn " | " $0; sn="" }
' | grep "Sitename:" | grep -oE 'Serial Number: [0-9A-F]+ ' | uniq
