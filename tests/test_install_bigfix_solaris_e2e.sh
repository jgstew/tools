#!/usr/bin/env bash
# End-to-end test for the Solaris (pkgadd) branch of bash/install_bigfix.sh.
#
# Unlike tests/test_install_bigfix_e2e.sh this is NOT a docker harness:
# Solaris cannot run in docker containers (containers share the Linux kernel),
# so this script runs INSIDE a Solaris host. In CI that host is the
# vmactions/solaris-vm VM launched by
# .github/workflows/test_install_bigfix_solaris_e2e.yaml (the same mechanism
# run_qna_solaris.yaml uses), which first starts the fake relay on the runner:
# nginx serving a dummy masthead over self-signed TLS on 52311, identical to
# the main suite (works because the script fetches the masthead with
# --insecure by design).
#
# From inside the VM the runner host is reachable at the default-route
# gateway IP (QEMU user-mode networking maps the 10.0.2.2 gateway to the
# host), so "relay" is mapped to that IP in /etc/inet/hosts before running
# the installer. The agent download itself is REAL, from software.bigfix.com
# (BESAgent-*.x86_sol11.pkg).
#
# Environment variables:
#   RELAY_HOST   IP/hostname serving the fake masthead on 52311
#                (default: the default-route gateway, i.e. the hypervisor host)
#   E2E_LOGDIR   directory for diagnostic logs (default: ./solaris-e2e-logs,
#                so vmactions copyback returns it to the runner for artifact
#                upload). A full diagnostic dump lands here on failure.
#
# Usage (on a Solaris host, as root):
#   bash tests/test_install_bigfix_solaris_e2e.sh
# Exits 0 if the test passes, 1 otherwise. Prints a "==== RESULTS ====" block
# in the same format as the main suite.
#
# NOTE: a FAIL here may be a genuine Solaris-branch bug in install_bigfix.sh
# (that branch is marked "TODO: test case for Solaris") — read the diagnostic
# dump before assuming the harness is at fault.
set -u

LOGDIR="${E2E_LOGDIR:-$(pwd)/solaris-e2e-logs}"
mkdir -p "$LOGDIR" 2>/dev/null || LOGDIR=/var/tmp/solaris-e2e-logs
mkdir -p "$LOGDIR"

# Dump everything that helps tell a harness problem from a real installer bug
# apart. Called on any failure; best-effort, never fails the script itself.
dump_diagnostics() {
  echo "==== DIAGNOSTICS (see $LOGDIR) ===="
  {
    echo "### uname -a";            uname -a
    echo "### id";                  id
    echo "### netstat -rn";         netstat -rn 2>&1
    echo "### /etc/inet/hosts";     cat /etc/inet/hosts 2>&1
    echo "### RELAY_HOST=$RELAY_HOST"
    echo "### curl -v masthead";    curl -vk "https://relay:52311/masthead/masthead.afxm" 2>&1
    echo "### pkginfo | grep -i bes"; pkginfo 2>/dev/null | grep -i bes
    echo "### ls -l /opt/BESClient/bin"; ls -l /opt/BESClient/bin 2>&1
    echo "### besclient.config";    cat /var/opt/BESClient/besclient.config 2>&1
    echo "### staged files in $WORKDIR"; ls -l "$WORKDIR" 2>&1
    echo "### client log tail"
    tail -50 "/var/opt/BESClient/__BESData/__Global/Logs/$(date +%Y%m%d).log" 2>&1
  } | tee "$LOGDIR/diagnostics.txt"
  echo "==== END DIAGNOSTICS ===="
}

[ "$(uname -s)" = "SunOS" ] || { echo "ERROR: this test must run ON Solaris (uname -s = $(uname -s)); in CI it runs inside the vmactions/solaris-vm VM" >&2; exit 1; }
[ "$(id -u)" = "0" ] || { echo "ERROR: must run as root (installs the agent)" >&2; exit 1; }

SRCDIR="$(cd "$(dirname "$0")/../bash" && pwd)"
[ -f "$SRCDIR/install_bigfix.sh" ] || { echo "ERROR: $SRCDIR/install_bigfix.sh not found" >&2; exit 1; }

WORKDIR=/var/tmp/bigfix_e2e

# The hypervisor host (which serves the fake relay) is the guest's default
# gateway in both qemu user-mode and libvirt NAT networking.
RELAY_HOST="${RELAY_HOST:-$(netstat -rn 2>/dev/null | awk '$1 == "default" {print $2; exit}')}"
if [ -z "$RELAY_HOST" ]; then
  echo "ERROR: could not determine default gateway; set RELAY_HOST" >&2
  dump_diagnostics
  exit 1
fi
echo "using fake relay at $RELAY_HOST (mapped to hostname 'relay')"

# Map the hostname "relay" (matches the cert CN and the main suite) to the host.
grep -w relay /etc/inet/hosts >/dev/null 2>&1 || echo "$RELAY_HOST relay" >> /etc/inet/hosts

# The fake relay must answer before the installer runs, or a network problem
# in the harness would be indistinguishable from an installer failure.
if ! curl -sk "https://relay:52311/masthead/masthead.afxm" >/dev/null 2>&1; then
  echo "ERROR: fake relay not reachable at https://relay:52311 from inside the VM" >&2
  dump_diagnostics
  exit 1
fi
echo "fake relay reachable; running installer"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cp "$SRCDIR/install_bigfix.sh" "$WORKDIR/"
cd "$WORKDIR" || exit 1

# Capture the installer's own output for the diagnostic bundle.
bash install_bigfix.sh relay 2>&1 | tee "$LOGDIR/installer.log"
rc=${PIPESTATUS[0]}
echo "SCRIPT_EXIT=$rc"

# Same assertions as ASSERT_COMMON in the main suite, plus the SVR4 package
# registration (the script installs with `pkgadd -d ... BESagent`).
FAILED=0
fail() { echo "$1"; FAILED=1; }
[ $rc -eq 0 ]                                || fail "FAIL: install_bigfix.sh exited $rc"
pkginfo BESagent >/dev/null 2>&1             || fail "MISSING: BESagent SVR4 package not registered"
[ -x /opt/BESClient/bin/BESClient ]          || fail "MISSING: BESClient binary"
[ -f /var/opt/BESClient/besclient.config ]   || fail "MISSING: besclient.config"
[ -f /etc/opt/BESClient/actionsite.afxm ]    || fail "MISSING: actionsite.afxm"
[ -f "$WORKDIR/BESAgent.pkg" ]               || fail "MISSING: staged BESAgent.pkg"

if [ $FAILED -ne 0 ]; then
  dump_diagnostics
else
  echo E2E_PASS
fi

echo
echo "==== RESULTS ===="
if [ $FAILED -eq 0 ]; then
  printf "%-25s %s\n" "solaris-pkgadd" "PASS"
else
  printf "%-25s %s\n" "solaris-pkgadd" "FAIL(exit=$rc)"
fi
exit $FAILED
