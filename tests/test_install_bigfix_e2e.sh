#!/usr/bin/env bash
# Parallel end-to-end tests for bash/install_bigfix.sh in Docker.
#
# How it works:
#   - A fake "relay" nginx container serves a dummy masthead over self-signed
#     TLS on port 52311 (works because the script fetches the masthead with
#     --insecure by design; the masthead cert is tied to the deployment, not
#     a public CA).
#   - Five test containers run IN PARALLEL (--platform linux/amd64, so this
#     also works on arm64 hosts via emulation), each doing a REAL agent
#     download from software.bigfix.com, installing it, and asserting the
#     install completed.
#
# Tests:
#   ubuntu-deb             .deb path via apt-get on ubuntu:24.04
#   debian-rpm-regression  Debian WITH the rpm command installed must still
#                           choose the .deb installer (regression for the bug
#                           where the rpm block overrode dpkg detection)
#   alma-dnf               .rpm path via dnf on almalinux:9
#   leap-zypper            .rpm path via zypper on opensuse/leap:15
#   startbigfix-false      StartBigFix=false installs but does not start the
#                           client, skips the 30s sleep, exits 0
#
# Prerequisites: docker (with amd64 emulation on non-x86 hosts), openssl,
#                network access to software.bigfix.com and docker hub.
# Usage:
#   bash tests/test_install_bigfix_e2e.sh
# Exits 0 if all tests pass, 1 otherwise. Takes several minutes.
set -u

SRCDIR="$(cd "$(dirname "$0")/../bash" && pwd)"
[ -f "$SRCDIR/install_bigfix.sh" ] || { echo "ERROR: $SRCDIR/install_bigfix.sh not found" >&2; exit 1; }

NET=bigfix-e2e
PLATFORM=linux/amd64
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/bigfix_e2e.XXXXXX")" || exit 1
LOGDIR="$WORKDIR/logs"
mkdir -p "$LOGDIR" "$WORKDIR/relay/www/masthead"

cleanup() {
  docker rm -f e2e-relay >/dev/null 2>&1
  for t in ubuntu-deb debian-rpm-regression alma-dnf leap-zypper startbigfix-false; do
    docker rm -f "e2e-$t" >/dev/null 2>&1
  done
  docker network rm $NET >/dev/null 2>&1
}
# clean up any leftovers from a previous aborted run; temp dir is removed at exit
cleanup
trap 'cleanup; rm -rf "$WORKDIR"' EXIT

# fake relay: self-signed cert + nginx config + dummy masthead
openssl req -x509 -newkey rsa:2048 -nodes -days 2 \
  -keyout "$WORKDIR/relay/key.pem" -out "$WORKDIR/relay/cert.pem" \
  -subj "/CN=relay" >/dev/null 2>&1 || { echo "ERROR: openssl cert generation failed" >&2; exit 1; }
cat > "$WORKDIR/relay/nginx.conf" <<'EOF'
events {}
http {
  server {
    listen 52311 ssl;
    ssl_certificate /relay/cert.pem;
    ssl_certificate_key /relay/key.pem;
    root /relay/www;
  }
}
EOF
echo "dummy-masthead-content-for-e2e-test" > "$WORKDIR/relay/www/masthead/masthead.afxm"

docker network create $NET >/dev/null || exit 1
docker run -d --rm --name e2e-relay --network $NET --network-alias relay \
  -v "$WORKDIR/relay:/relay:ro" \
  nginx:alpine nginx -c /relay/nginx.conf -g 'daemon off;' >/dev/null || exit 1
sleep 2

# run_test <name> <image> <inner-script>
run_test() {
  local name=$1 image=$2 inner=$3
  docker run --rm --name "e2e-$name" --platform $PLATFORM --network $NET \
    -v "$SRCDIR:/src:ro" "$image" bash -c "$inner" \
    > "$LOGDIR/$name.log" 2>&1
  echo $? > "$LOGDIR/$name.exit"
}

# Common tail of every inner script: run installer, require exit 0, assert artifacts.
RUN_AND_ASSERT='
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
bash install_bigfix.sh relay
rc=$?
echo "SCRIPT_EXIT=$rc"
[ $rc -eq 0 ] || exit 10
[ -x /opt/BESClient/bin/BESClient ]        || { echo "MISSING: BESClient binary"; exit 11; }
[ -f /var/opt/BESClient/besclient.config ] || { echo "MISSING: besclient.config"; exit 12; }
[ -f /etc/opt/BESClient/actionsite.afxm ]  || { echo "MISSING: actionsite.afxm"; exit 13; }
'

declare -a NAMES=()

NAMES+=(ubuntu-deb)
run_test ubuntu-deb ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ] || { echo 'MISSING: staged BESAgent.deb'; exit 14; }
echo E2E_PASS
" &

# Regression for the rpm-overrides-dpkg bug: Debian WITH the rpm command
# installed must still choose the .deb installer, never the SUSE rpm.
NAMES+=(debian-rpm-regression)
run_test debian-rpm-regression debian:latest "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates rpm >/dev/null 2>&1
command -v rpm >/dev/null || { echo 'SETUP FAIL: rpm not installed'; exit 20; }
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ]   || { echo 'REGRESSION: BESAgent.deb not staged'; exit 21; }
[ ! -f /work/BESAgent.rpm ] || { echo 'REGRESSION: rpm block overrode deb detection'; exit 22; }
dpkg -l | grep -qi besagent || { echo 'REGRESSION: deb package not installed'; exit 23; }
echo E2E_PASS
" &

NAMES+=(alma-dnf)
run_test alma-dnf almalinux:9 "
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

NAMES+=(leap-zypper)
run_test leap-zypper opensuse/leap:15 "
command -v curl >/dev/null || zypper --non-interactive install curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

# Verifies the StartBigFix=false behavior: installs but does not start the
# client, does not sleep 30s, exits 0.
# NOTE: pgrep -x (exact process name), NOT -f, which would false-positive on
# this test shell's own command line containing the string "BESClient".
NAMES+=(startbigfix-false)
run_test startbigfix-false ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive StartBigFix=false
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates procps >/dev/null 2>&1
$RUN_AND_ASSERT
pgrep -x BESClient >/dev/null && { echo 'FAIL: BESClient running despite StartBigFix=false'; exit 30; }
echo E2E_PASS
" &

wait

echo
echo "==== RESULTS ===="
FAILED=0
for name in "${NAMES[@]}"; do
  ec=$(cat "$LOGDIR/$name.exit" 2>/dev/null || echo "?")
  if [ "$ec" = "0" ] && grep -q E2E_PASS "$LOGDIR/$name.log"; then
    status=PASS
  else
    status="FAIL(exit=$ec)"
    FAILED=1
  fi
  # StartBigFix=false must not have slept
  if [ "$name" = "startbigfix-false" ] && grep -q "sleep for 30 seconds" "$LOGDIR/$name.log"; then
    status="FAIL(slept despite StartBigFix=false)"
    FAILED=1
  fi
  printf "%-25s %s\n" "$name" "$status"
  if [ "$status" != "PASS" ]; then
    echo "---- last 20 lines of $name.log ----"
    tail -20 "$LOGDIR/$name.log" 2>/dev/null
    echo "------------------------------------"
  fi
done

exit $FAILED
