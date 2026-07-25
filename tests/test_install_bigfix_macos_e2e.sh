#!/usr/bin/env bash
# End-to-end test for the macOS (darwin) branch of bash/install_bigfix.sh.
#
# This REALLY INSTALLS the BigFix agent on THIS machine — it is meant for a
# disposable GitHub Actions macos runner
# (.github/workflows/test_install_bigfix_macos_e2e.yaml), not a workstation.
# As a guard it refuses to run unless CI=true or E2E_ALLOW_LOCAL_INSTALL=1.
#
# Fake relay: docker is not available on macOS runners, so instead of the
# nginx container the main suite uses, a python3 HTTPS server serves the same
# dummy masthead over self-signed TLS on 127.0.0.1:52311, with "relay" mapped
# to 127.0.0.1 in /etc/hosts (removed again on exit). The agent download
# itself is REAL, from software.bigfix.com (BESAgent-*-BigFix_MacOS11.0.pkg,
# a universal binary, so this works on both Intel and Apple Silicon runners).
#
# Usage (as root):
#   sudo bash tests/test_install_bigfix_macos_e2e.sh
# Exits 0 if the test passes, 1 otherwise. Prints a "==== RESULTS ====" block
# in the same format as the main suite.
set -u

[[ "$OSTYPE" == darwin* ]] || { echo "ERROR: this test must run on macOS (OSTYPE=$OSTYPE)" >&2; exit 1; }
[ "$(id -u)" = "0" ] || { echo "ERROR: must run as root (installs the agent): sudo bash $0" >&2; exit 1; }
if [ "${CI:-}" != "true" ] && [ -z "${E2E_ALLOW_LOCAL_INSTALL:-}" ]; then
  echo "ERROR: refusing to install the BigFix agent on a non-CI machine." >&2
  echo "       Set E2E_ALLOW_LOCAL_INSTALL=1 if you really want that." >&2
  exit 1
fi

SRCDIR="$(cd "$(dirname "$0")/../bash" && pwd)"
[ -f "$SRCDIR/install_bigfix.sh" ] || { echo "ERROR: $SRCDIR/install_bigfix.sh not found" >&2; exit 1; }

WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/bigfix_e2e_mac.XXXXXX")" || exit 1
RELAYPID=""
HOSTS_MARKER="# bigfix-e2e-relay"

cleanup() {
  [ -n "$RELAYPID" ] && kill "$RELAYPID" 2>/dev/null
  sed -i '' "/$HOSTS_MARKER/d" /etc/hosts 2>/dev/null
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

# fake relay: self-signed cert + python3 https server + dummy masthead
mkdir -p "$WORKDIR/relay/www/masthead"
openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
  -keyout "$WORKDIR/relay/key.pem" -out "$WORKDIR/relay/cert.pem" \
  -subj "/CN=relay" >/dev/null 2>&1 || { echo "ERROR: openssl cert generation failed" >&2; exit 1; }
echo "dummy-masthead-content-for-e2e-test" > "$WORKDIR/relay/www/masthead/masthead.afxm"
cat > "$WORKDIR/relay/server.py" <<'EOF'
import http.server, ssl, sys
httpd = http.server.HTTPServer(("127.0.0.1", 52311), http.server.SimpleHTTPRequestHandler)
ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ctx.load_cert_chain(sys.argv[1], sys.argv[2])
httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
httpd.serve_forever()
EOF
(cd "$WORKDIR/relay/www" && python3 "$WORKDIR/relay/server.py" "$WORKDIR/relay/cert.pem" "$WORKDIR/relay/key.pem" &
 echo $! > "$WORKDIR/relay/pid") || exit 1
RELAYPID="$(cat "$WORKDIR/relay/pid")"

echo "127.0.0.1 relay $HOSTS_MARKER" >> /etc/hosts

# wait for the relay to answer before running the installer
for _ in 1 2 3 4 5 6 7 8 9 10; do
  curl -sk "https://relay:52311/masthead/masthead.afxm" >/dev/null && break
  sleep 1
done
curl -sk "https://relay:52311/masthead/masthead.afxm" >/dev/null \
  || { echo "ERROR: fake relay not reachable at https://relay:52311" >&2; exit 1; }

mkdir -p "$WORKDIR/work"
cp "$SRCDIR/install_bigfix.sh" "$WORKDIR/work/"
cd "$WORKDIR/work" || exit 1

bash install_bigfix.sh relay
rc=$?
echo "SCRIPT_EXIT=$rc"

# macOS layout differs from Linux: the pkg installs BESAgent.app under
# /Library/BESAgent, and install_bigfix.sh stages the masthead next to the
# installer (INSTALLDIR=STAGINGDIR) for the pkg installer to pick up.
FAILED=0
fail() { echo "$1"; FAILED=1; }
[ $rc -eq 0 ]                                          || fail "FAIL: install_bigfix.sh exited $rc"
[ -f "$WORKDIR/work/BESAgent.pkg" ]                    || fail "MISSING: staged BESAgent.pkg"
[ -f "$WORKDIR/work/actionsite.afxm" ]                 || fail "MISSING: staged actionsite.afxm (masthead)"
[ -d /Library/BESAgent/BESAgent.app ]                  || fail "MISSING: /Library/BESAgent/BESAgent.app"
pkgutil --pkgs 2>/dev/null | grep -qiE 'bigfix|besagent' || fail "MISSING: no BigFix pkg receipt (pkgutil --pkgs)"
[ $FAILED -eq 0 ] && echo E2E_PASS

echo
echo "==== RESULTS ===="
if [ $FAILED -eq 0 ]; then
  printf "%-25s %s\n" "macos-pkg" "PASS"
else
  printf "%-25s %s\n" "macos-pkg" "FAIL(exit=$rc)"
fi
exit $FAILED
