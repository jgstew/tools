#!/usr/bin/env bash
# Parallel end-to-end tests for bash/install_bigfix.sh in Docker.
#
# How it works:
#   - A fake "relay" nginx container serves a dummy masthead over self-signed
#     TLS on port 52311 (works because the script fetches the masthead with
#     --insecure by design; the masthead cert is tied to the deployment, not
#     a public CA).
#   - All test containers run IN PARALLEL simultaneously (mostly
#     --platform linux/amd64, so this also works on arm64 hosts via
#     emulation), each doing a REAL agent download from software.bigfix.com,
#     installing it, and asserting the install completed. Expect max CPU
#     usage while the suite runs.
#
# Tests:
#   ubuntu-deb             .deb path via apt-get on ubuntu:24.04
#   ubuntu2204-deb         .deb path via apt-get on ubuntu:22.04
#   debian-rpm-regression  Debian WITH the rpm command installed must still
#                           choose the .deb installer (regression for the bug
#                           where the rpm block overrode dpkg detection)
#   alma-dnf               .rpm path via dnf on almalinux:9
#   oracle-dnf             .rpm path via dnf on oraclelinux:9
#   fedora-dnf             .rpm path via dnf on fedora:41
#   amazon-dnf             .rpm path on amazonlinux:2023 — exercises the
#                           /etc/system-release branch (no /etc/redhat-release;
#                           must pick the RHEL rpm, not fall through to SUSE)
#   ubi7-yum               .rpm path via yum on Red Hat UBI 7 (RHEL 7)
#   ubi8-dnf               .rpm path via dnf on Red Hat UBI 8 (RHEL 8)
#   ubi9-dnf               .rpm path via dnf on Red Hat UBI 9 (RHEL 9)
#   ubi10-dnf              .rpm path via dnf on Red Hat UBI 10 (RHEL 10)
#                           (auto-SKIPs where emulation lacks x86-64-v3,
#                           e.g. Apple Silicon hosts)
#   leap-zypper            .rpm path via zypper on opensuse/leap:15
#   startbigfix-false      StartBigFix=false installs but does not start the
#                           client, skips the 30s sleep, exits 0
#   wget-fallback          download path when wget is present but curl is not
#   amazon2-yum            .rpm path via yum (no dnf) on amazonlinux:2
#   rpm-only               plain `rpm -ivh` fallback when no dnf/yum/zypper
#   sh-reexec              invoking via `sh` re-execs itself under bash
#   readonly-staging       script dir mounted read-only -> stages in /tmp
#   hostport-arg           host:port argument form (colon-parsing branch)
#   relaypass              relay password ($2) lands in besclient.config
#   custom-cfg             pre-existing clientsettings.cfg in CWD is used
#                           instead of generating defaults
#   negatives              no-arg exits 1; unreachable relay fails nonzero
#                           without installing; no curl/wget exits 2
#   armhf-native           native arm64 debian takes the raspbian armhf branch
#                           (runs natively on arm64 hosts, emulated elsewhere)
#   i386-bigfix95          32-bit x86 falls back to BigFix 9.5 (linux/386)
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
# Per-test logs default inside WORKDIR (removed at exit). Set E2E_LOGDIR to a
# path outside it to keep the logs after the run, e.g. for CI artifact upload.
LOGDIR="${E2E_LOGDIR:-$WORKDIR/logs}"
mkdir -p "$LOGDIR" "$WORKDIR/relay/www/masthead"

cleanup() {
  docker rm -f e2e-relay >/dev/null 2>&1
  for t in ubuntu-deb ubuntu2204-deb debian-rpm-regression alma-dnf oracle-dnf fedora-dnf amazon-dnf leap-zypper startbigfix-false \
           ubi7-yum ubi8-dnf ubi9-dnf ubi10-dnf \
           wget-fallback amazon2-yum rpm-only sh-reexec readonly-staging hostport-arg relaypass custom-cfg negatives armhf-native i386-bigfix95; do
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

# run_test <name> <image> <inner-script> [platform]
run_test() {
  local name=$1 image=$2 inner=$3 platform=${4:-$PLATFORM}
  docker run --rm --name "e2e-$name" --platform "$platform" --network $NET \
    -v "$SRCDIR:/src:ro" "$image" bash -c "$inner" \
    > "$LOGDIR/$name.log" 2>&1
  echo $? > "$LOGDIR/$name.exit"
}

# Post-run assertions shared by every install test: requires $rc set to the
# installer script's exit code by the preceding lines.
ASSERT_COMMON='
echo "SCRIPT_EXIT=$rc"
[ $rc -eq 0 ] || exit 10
[ -x /opt/BESClient/bin/BESClient ]        || { echo "MISSING: BESClient binary"; exit 11; }
[ -f /var/opt/BESClient/besclient.config ] || { echo "MISSING: besclient.config"; exit 12; }
[ -f /etc/opt/BESClient/actionsite.afxm ]  || { echo "MISSING: actionsite.afxm"; exit 13; }
'

# Common tail of every inner script: run installer, require exit 0, assert artifacts.
RUN_AND_ASSERT='
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
bash install_bigfix.sh relay
rc=$?
'"$ASSERT_COMMON"

declare -a NAMES=()

NAMES+=(ubuntu-deb)
run_test ubuntu-deb ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ] || { echo 'MISSING: staged BESAgent.deb'; exit 14; }
echo E2E_PASS
" &

NAMES+=(ubuntu2204-deb)
run_test ubuntu2204-deb ubuntu:22.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ] || { echo 'MISSING: staged BESAgent.deb'; exit 14; }
echo E2E_PASS
" &

# Regression for the rpm-overrides-dpkg bug: Debian WITH the rpm command
# installed must still choose the .deb installer, never the SUSE rpm.
NAMES+=(debian-rpm-regression)
run_test debian-rpm-regression debian:12 "
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

NAMES+=(oracle-dnf)
run_test oracle-dnf oraclelinux:9 "
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

NAMES+=(fedora-dnf)
run_test fedora-dnf fedora:41 "
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

# Amazon Linux has /etc/system-release but NOT /etc/redhat-release; the script
# must still select the RHEL rpm rather than falling through to the SUSE build.
NAMES+=(amazon-dnf)
run_test amazon-dnf amazonlinux:2023 "
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
[ ! -f /etc/redhat-release ] || { echo 'SETUP FAIL: unexpected /etc/redhat-release'; exit 20; }
[ -f /etc/system-release ]   || { echo 'SETUP FAIL: missing /etc/system-release'; exit 20; }
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

# Red Hat UBI images: real RHEL 7/8/9/10 userlands, publicly pullable.
# UBI 7 is yum-based; 8/9/10 use dnf. All have /etc/redhat-release, so they
# take the RHEL branch (rhe7 rpm). Note UBI repos are a subset of full RHEL,
# so the ldd missing-library loop may only find some soname providers there.

NAMES+=(ubi7-yum)
run_test ubi7-yum registry.access.redhat.com/ubi7/ubi "
[ -f /etc/redhat-release ] || { echo 'SETUP FAIL: missing /etc/redhat-release'; exit 20; }
command -v curl >/dev/null || yum install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

NAMES+=(ubi8-dnf)
run_test ubi8-dnf registry.access.redhat.com/ubi8/ubi "
[ -f /etc/redhat-release ] || { echo 'SETUP FAIL: missing /etc/redhat-release'; exit 20; }
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

NAMES+=(ubi9-dnf)
run_test ubi9-dnf registry.access.redhat.com/ubi9/ubi "
[ -f /etc/redhat-release ] || { echo 'SETUP FAIL: missing /etc/redhat-release'; exit 20; }
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

NAMES+=(ubi10-dnf)
run_test ubi10-dnf registry.access.redhat.com/ubi10/ubi "
[ -f /etc/redhat-release ] || { echo 'SETUP FAIL: missing /etc/redhat-release'; exit 20; }
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

# All tests run simultaneously — expect max CPU usage while the suite runs.

# Download path when wget is present but curl is not (debian base has no curl).
NAMES+=(wget-fallback)
run_test wget-fallback debian:12 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq wget ca-certificates >/dev/null 2>&1
command -v curl >/dev/null && { echo 'SETUP FAIL: curl unexpectedly present'; exit 20; }
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ] || { echo 'MISSING: staged BESAgent.deb'; exit 14; }
echo E2E_PASS
" &

# yum path: amazonlinux:2 has yum but no dnf.
NAMES+=(amazon2-yum)
run_test amazon2-yum amazonlinux:2 "
command -v dnf >/dev/null && { echo 'SETUP FAIL: dnf unexpectedly present'; exit 20; }
command -v curl >/dev/null || yum install -y -q curl >/dev/null 2>&1
$RUN_AND_ASSERT
[ -f /work/BESAgent.rpm ] || { echo 'MISSING: staged BESAgent.rpm'; exit 14; }
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

# Plain `rpm -ivh` fallback: hide dnf/yum so no dependency-resolving package
# manager is found (zypper is absent on almalinux).
NAMES+=(rpm-only)
run_test rpm-only almalinux:9 "
command -v curl >/dev/null || dnf install -y -q curl >/dev/null 2>&1
mv /usr/bin/dnf /usr/bin/dnf.hidden 2>/dev/null
mv /usr/bin/yum /usr/bin/yum.hidden 2>/dev/null
command -v dnf >/dev/null && { echo 'SETUP FAIL: dnf still present'; exit 20; }
$RUN_AND_ASSERT
rpm -q BESAgent >/dev/null || { echo 'MISSING: BESAgent rpm not installed'; exit 15; }
echo E2E_PASS
" &

# Invoking via `sh` (dash on ubuntu) must re-exec itself under bash.
NAMES+=(sh-reexec)
run_test sh-reexec ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
sh install_bigfix.sh relay
rc=$?
'"$ASSERT_COMMON
echo E2E_PASS
" &

# Script dir mounted read-only: staging must fall back to /tmp.
NAMES+=(readonly-staging)
run_test readonly-staging ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
cd /
bash /src/install_bigfix.sh relay
rc=$?
'"$ASSERT_COMMON"'
[ -f /tmp/BESAgent.deb ]        || { echo "FAIL: installer not staged in /tmp"; exit 40; }
[ -f /tmp/clientsettings.cfg ]  || { echo "FAIL: clientsettings.cfg not staged in /tmp"; exit 41; }
echo E2E_PASS
' &

# host:port argument form exercises the colon-parsing branch.
NAMES+=(hostport-arg)
run_test hostport-arg debian:12 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
bash install_bigfix.sh relay:52311
rc=$?
'"$ASSERT_COMMON
echo E2E_PASS
" &

# Relay password ($2) must land in the staged cfg and besclient.config.
NAMES+=(relaypass)
run_test relaypass ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
bash install_bigfix.sh relay secretpass123
rc=$?
'"$ASSERT_COMMON"'
grep -q "_BESClient_SecureRegistration=secretpass123" /work/clientsettings.cfg || { echo "FAIL: password not in staged cfg"; exit 42; }
grep -q "secretpass123" /var/opt/BESClient/besclient.config || { echo "FAIL: password not in besclient.config"; exit 43; }
echo E2E_PASS
' &

# A pre-existing clientsettings.cfg in CWD must be used as-is (no generated defaults).
NAMES+=(custom-cfg)
run_test custom-cfg ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
printf "_BESClient_Custom_TestMarker=e2emarker42\n_BESClient_Log_Days=7\n" > clientsettings.cfg
bash install_bigfix.sh relay
rc=$?
'"$ASSERT_COMMON"'
grep -q "e2emarker42" /var/opt/BESClient/besclient.config || { echo "FAIL: custom cfg not used"; exit 44; }
grep -q "CommandPollEnable" /var/opt/BESClient/besclient.config && { echo "FAIL: defaults generated despite custom cfg"; exit 45; }
echo E2E_PASS
' &

# Negative cases: no-arg usage error, unreachable relay, no curl/wget.
NAMES+=(negatives)
run_test negatives ubuntu:24.04 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
"'
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
bash install_bigfix.sh
[ $? -eq 1 ] || { echo "FAIL: no-arg should exit 1"; exit 31; }
bash install_bigfix.sh nonexistent-relay.invalid
rc=$?
[ $rc -ne 0 ] || { echo "FAIL: unreachable relay should exit nonzero"; exit 32; }
[ ! -x /opt/BESClient/bin/BESClient ] || { echo "FAIL: agent installed despite failed download"; exit 33; }
mv /usr/bin/curl /usr/bin/curl.hidden
bash install_bigfix.sh relay
[ $? -eq 2 ] || { echo "FAIL: no curl/wget should exit 2"; exit 34; }
echo E2E_PASS
' &

# Native arm64 debian reports aarch64 and takes the raspbian armhf branch
# (dpkg --add-architecture armhf + raspbian10.armhf.deb).
NAMES+=(armhf-native)
run_test armhf-native debian:12 "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
uname -m | grep -q aarch64 || { echo 'SETUP FAIL: not aarch64'; exit 20; }
$RUN_AND_ASSERT
[ -f /work/BESAgent.deb ] || { echo 'MISSING: staged BESAgent.deb'; exit 14; }
echo E2E_PASS
" linux/arm64 &

# 32-bit x86 must fall back to BigFix 9.5 (last release with 32-bit builds).
# On native x86_64 hosts an i386 container still reports x86_64 from uname
# (the binaries run natively, no emulation), so there the script must run
# under linux32, which sets the 32-bit personality and makes uname -m report
# i686 - exactly what a real 32-bit machine reports. Under qemu on non-x86
# hosts uname -m is already i686, and linux32 must NOT be used (qemu-user
# cannot set the personality and setarch exits nonzero).
NAMES+=(i386-bigfix95)
run_test i386-bigfix95 i386/debian:bullseye "
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq >/dev/null && apt-get install -y -qq curl ca-certificates >/dev/null 2>&1
dpkg --print-architecture | grep -qx i386 || { echo 'SETUP FAIL: not an i386 userland'; exit 20; }
"'
uname -m | grep -qE "i.86" || linux32 true 2>/dev/null || { echo "SETUP FAIL: cannot get a 32-bit uname"; exit 20; }
RUNARCH=""
uname -m | grep -qE "i.86" || RUNARCH=linux32
mkdir -p /work && cp /src/install_bigfix.sh /work/ && cd /work
$RUNARCH bash install_bigfix.sh relay
rc=$?
'"$ASSERT_COMMON"'
[ -f /work/BESAgent.deb ] || { echo "MISSING: staged BESAgent.deb"; exit 14; }
dpkg -s besagent 2>/dev/null | grep -q "^Version: 9.5" || { echo "FAIL: expected BigFix 9.5 fallback version"; exit 46; }
echo E2E_PASS
' linux/386 &

wait

echo
echo "==== RESULTS ===="
FAILED=0
for name in "${NAMES[@]}"; do
  ec=$(cat "$LOGDIR/$name.exit" 2>/dev/null || echo "?")
  # RHEL 10 x86_64 requires the x86-64-v3 microarchitecture; emulation on
  # some hosts (e.g. Apple Silicon) cannot provide it. Skip, don't fail.
  if grep -q "CPU does not support x86-64-v3" "$LOGDIR/$name.log" 2>/dev/null; then
    printf "%-25s %s\n" "$name" "SKIP(host emulation lacks x86-64-v3)"
    continue
  fi
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
