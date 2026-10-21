#!/usr/bin/env bash
#### Usage: ./yara_x_scan_macos.sh [-t TARGET_PATH] [-o OUTPUT_DIR] [-f text|json|ndjson] [-k]
#
# Self-contained YARA-X scan for macOS:
#   1. downloads the YARA-X CLI (yr) release for this CPU architecture
#   2. verifies the SHA256 of the download against a pinned value
#   3. unpacks it into a temporary folder
#   4. scans TARGET_PATH (recursively) with the YARA rule embedded below,
#      staying on TARGET_PATH's volume: other mounts (DMGs, network shares,
#      external disks, autofs, Time Machine snapshots) are skipped
#   5. writes results + a log to OUTPUT_DIR
#
# Run with sudo (and give the terminal / agent Full Disk Access) for a full
# scan; otherwise protected files are logged as unreadable and skipped.
#
# Options:
#   -t TARGET_PATH  file or folder to scan            (default: / = whole local boot drive)
#   -o OUTPUT_DIR   folder to write results into      (default: ./yara_results)
#   -f FORMAT       yr output format: text|json|ndjson (default: text)
#   -k              keep the downloaded yr binary in OUTPUT_DIR/bin for reuse
#   -h              show this help
#
# Exit codes: 0 = scan ran, no matches; 1 = scan ran, matches found;
#             2 = usage error; 3 = download/verify/unpack error; 4 = scan error
#
# Release: https://github.com/VirusTotal/yara-x/releases/tag/v1.22.0
# SHA256 values below are the GitHub-computed asset digests for v1.22.0.
# Related: https://github.com/jgstew/tools/tree/master/YARA/php

set -euo pipefail

YARAX_VERSION="1.22.0"
YARAX_BASE_URL="https://github.com/VirusTotal/yara-x/releases/download/v${YARAX_VERSION}"
SHA256_AARCH64="79d596da5bf02205de63a1d7844a964daebc7293fa36fcb7da46c3e3c7567229"
SHA256_X86_64="d059da4b91c7d7b43f6f50174a7739e3362b51f349f2ba8b33d46e3334bb3300"

TARGET_PATH="/"
OUTPUT_DIR="$PWD/yara_results"
OUTPUT_FORMAT="text"
KEEP_BINARY=0

usage() {
  sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

while getopts ":t:o:f:kh" opt; do
  case "$opt" in
    t) TARGET_PATH="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    f) OUTPUT_FORMAT="$OPTARG" ;;
    k) KEEP_BINARY=1 ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 2 ;;
  esac
done

case "$OUTPUT_FORMAT" in
  text|json|ndjson) ;;
  *) echo "Invalid format '$OUTPUT_FORMAT' (use text, json or ndjson)." >&2; exit 2 ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script is for macOS only." >&2
  exit 2
fi

if [ ! -e "$TARGET_PATH" ]; then
  echo "Target path does not exist: $TARGET_PATH" >&2
  exit 2
fi

# uname -m reports arm64 on Apple Silicon, but the release asset is named aarch64
case "$(uname -m)" in
  arm64|aarch64) ARCH="aarch64"; EXPECTED_SHA256="$SHA256_AARCH64" ;;
  x86_64)        ARCH="x86_64";  EXPECTED_SHA256="$SHA256_X86_64" ;;
  *) echo "Unsupported architecture: $(uname -m)" >&2; exit 2 ;;
esac

ASSET_NAME="yara-x-v${YARAX_VERSION}-${ARCH}-apple-darwin.tar.gz"
ASSET_URL="${YARAX_BASE_URL}/${ASSET_NAME}"

WORK_DIR="$(mktemp -d -t yara_x_scan)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

mkdir -p "$OUTPUT_DIR"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"
RESULT_EXT="txt"
[ "$OUTPUT_FORMAT" = "text" ] || RESULT_EXT="$OUTPUT_FORMAT"
RESULT_FILE="${OUTPUT_DIR}/yara_results_$(hostname -s)_${TIMESTAMP}.${RESULT_EXT}"
LOG_FILE="${OUTPUT_DIR}/yara_scan_$(hostname -s)_${TIMESTAMP}.log"

# ---- download -------------------------------------------------------------
log "Downloading $ASSET_URL"
if ! curl --fail --silent --show-error --location \
     --retry 3 --retry-delay 2 --connect-timeout 30 \
     --output "${WORK_DIR}/${ASSET_NAME}" "$ASSET_URL"; then
  log "ERROR: download failed"
  exit 3
fi

# ---- verify ---------------------------------------------------------------
ACTUAL_SHA256="$(shasum -a 256 "${WORK_DIR}/${ASSET_NAME}" | awk '{print $1}')"
if [ "$ACTUAL_SHA256" != "$EXPECTED_SHA256" ]; then
  log "ERROR: SHA256 mismatch for $ASSET_NAME"
  log "  expected: $EXPECTED_SHA256"
  log "  actual:   $ACTUAL_SHA256"
  exit 3
fi
log "SHA256 verified: $ACTUAL_SHA256"

# ---- unpack ---------------------------------------------------------------
mkdir -p "${WORK_DIR}/bin"
if ! tar -xzf "${WORK_DIR}/${ASSET_NAME}" -C "${WORK_DIR}/bin"; then
  log "ERROR: failed to unpack $ASSET_NAME"
  exit 3
fi
YR="${WORK_DIR}/bin/yr"
if [ ! -x "$YR" ]; then
  log "ERROR: yr binary not found in archive"
  exit 3
fi
# curl does not set the quarantine flag, but strip it defensively so Gatekeeper won't block yr
xattr -d com.apple.quarantine "$YR" 2>/dev/null || true
log "Unpacked $("$YR" --version)"

# ---- embedded YARA rule ---------------------------------------------------
# TODO: replace the placeholder rule below with the real detection rule (TBD).
# The placeholder matches the harmless EICAR antivirus test string so the
# pipeline can be tested end to end.
RULE_FILE="${WORK_DIR}/embedded_rule.yar"
cat > "$RULE_FILE" <<'YARA_RULE'
/*
  PHP install detection + version, all OSes (Linux ELF, Windows PE, macOS Mach-O).

  Deliberately broad: PHP_Binary_Broad flags anything that looks PHP-related so
  nothing is missed; the other rules carry the exact version string. Run with
  `yara -s` (or `yr scan -s`) to print the matched version text.

  Rules:
    PHP_Runtime_Version     - PHP core runtime; $ver holds the exact version,
                              incl. distro suffix (e.g. 8.1.2-1ubuntu2.27)
    PHP_Windows_VersionInfo - any PE whose version resource says ProductName=PHP
                              (php.exe, php-cgi.exe, php8ts.dll, ext\php_*.dll);
                              $pv holds ProductVersion
    PHP_Binary_Broad        - catch-all: any executable with any PHP marker
    PHP_Build_Artifact      - php-config / php_version.h left by source installs

  No modules are imported so the rules also work in embedded YARA engines
  (osquery, EDRs) that are built without the pe/elf/macho modules.

  See README.md for tested samples and the API number -> branch table.
*/

private rule PHP_Detect_IsExecutable
{
  condition:
    uint32(0) == 0x464C457F                                 // ELF
    or uint16(0) == 0x5A4D                                  // PE (MZ)
    or uint32(0) == 0xFEEDFACE or uint32(0) == 0xFEEDFACF   // Mach-O 32/64
    or uint32(0) == 0xCEFAEDFE or uint32(0) == 0xCFFAEDFE   // Mach-O 32/64, byte-swapped
    or uint32(0) == 0xBEBAFECA                              // Mach-O universal (CAFEBABE)
}

rule PHP_Runtime_Version
{
  meta:
    description = "PHP core runtime (CLI/CGI/FPM/mod_php/libphp/php*ts.dll/php8.dll/embedded); $ver = exact version"
    confidence = "high"
  strings:
    // Compile-time literal "X-Powered-By: PHP/" PHP_VERSION in main/SAPI.c.
    // Present regardless of expose_php. Suffix covers distro builds (8.1.2-1ubuntu2.27)
    // and pre-releases (8.5.0RC1).
    $ver = /X-Powered-By: PHP\/[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}[0-9A-Za-z.+~_-]{0,40}/
  condition:
    PHP_Detect_IsExecutable and $ver
}

rule PHP_Windows_VersionInfo
{
  meta:
    description = "Windows PE with PHP version resource; $pv = ProductVersion (exact version)"
    confidence = "high"
  strings:
    // UTF-16LE "ProductName" <NUL + 0-2 bytes alignment pad> "PHP\0"
    $pname = { 50 00 72 00 6F 00 64 00 75 00 63 00 74 00 4E 00 61 00 6D 00 65 00 [2-4] 50 00 48 00 50 00 00 00 }
    $pv = /ProductVersion\x00[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}[0-9A-Za-z.\-]{0,20}/ wide
  condition:
    // #pv >= 0 is always true: $pv is only there so -s prints the version
    uint16(0) == 0x5A4D and $pname and #pv >= 0
}

rule PHP_Binary_Broad
{
  meta:
    description = "Broad catch-all: executable containing any PHP runtime/extension marker"
    confidence = "medium"
  strings:
    $xpb    = "X-Powered-By: PHP/"
    $zend   = "Zend Engine v"
    // ZEND_MODULE_BUILD_ID, e.g. API20220829,NTS / API20250925,TS - also in extensions
    $api    = /API20[0-9]{6},N?TS/
    $pname  = { 50 00 72 00 6F 00 64 00 75 00 63 00 74 00 4E 00 61 00 6D 00 65 00 [2-4] 50 00 48 00 50 00 00 00 }
    $grp    = "The PHP Group" ascii wide
    $ini    = "php.ini"
    $fmt    = "PHP %s (%s)"
  condition:
    PHP_Detect_IsExecutable and
    (
      $xpb or $zend or $api or $pname
      or ($grp and ($ini or $fmt))
    )
}

rule PHP_Build_Artifact
{
  meta:
    description = "php-config script or php_version.h header from a PHP build/install; $v* = version"
    confidence = "medium"
  strings:
    // php-config (installed next to the php binary by `make install` and -dev packages)
    $cfg_ver   = /version="[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}[0-9A-Za-z.+~_-]{0,40}"/
    $cfg_a     = "php_cli_binary="
    $cfg_b     = "--php-binary"
    // main/php_version.h
    $hdr_ver   = /#define PHP_VERSION "[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,3}[0-9A-Za-z.+~_-]{0,40}"/
    $hdr_a     = "#define PHP_MAJOR_VERSION"
  condition:
    filesize < 64KB and
    (
      ($cfg_ver and $cfg_a and $cfg_b)
      or ($hdr_ver and $hdr_a)
    )
}
YARA_RULE

# ---- build list of files to scan ------------------------------------------
# yr has no "stay on one filesystem" option, so find builds the file list:
#  -xdev       don't cross into other mounts (DMGs, network shares, external
#              disks, autofs). The APFS Data volume is firmlinked into / with
#              the same device id, so /Users, /Applications etc. are included.
#  -type f     regular files only; symlinks are not followed
#  prunes      /System/Volumes (Data would be scanned twice via its firmlinks,
#              the rest are separate system volumes), /dev, and this script's
#              own output/work folders (old results contain matched strings)
# Paths are resolved with pwd -P because /var, /tmp are symlinks to /private.
if [ "$(id -u)" -ne 0 ]; then
  log "WARNING: not running as root - protected files will be skipped (see log)"
fi
OUTPUT_DIR_REAL="$(cd "$OUTPUT_DIR" && pwd -P)"
WORK_DIR_REAL="$(cd "$WORK_DIR" && pwd -P)"
if [ -d "$TARGET_PATH" ]; then
  TARGET_PATH="$(cd "$TARGET_PATH" && pwd -P)"
fi
SCAN_LIST="${WORK_DIR}/scan_list.txt"
log "Listing files under $TARGET_PATH (skipping other mounts)"
find "$TARGET_PATH" -xdev \
  \( -path /System/Volumes -o -path /dev \
     -o -path "$OUTPUT_DIR_REAL" -o -path "$WORK_DIR_REAL" \) -prune \
  -o -type f -print >"$SCAN_LIST" 2>>"$LOG_FILE" || true  # non-zero on permission errors
log "Found $(wc -l <"$SCAN_LIST" | tr -d ' ') file(s) to scan"

# ---- scan -----------------------------------------------------------------
log "Scanning..."
log "Results: $RESULT_FILE"
SCAN_RC=0
"$YR" scan --scan-list --print-meta --print-strings \
  --output-format "$OUTPUT_FORMAT" \
  "$RULE_FILE" "$SCAN_LIST" >"$RESULT_FILE" 2>>"$LOG_FILE" || SCAN_RC=$?

# find and yr report per-file errors (e.g. permission denied) on stderr; yr still
# scans the rest and exits 0, so non-zero means the scan itself failed
if [ "$SCAN_RC" -ne 0 ]; then
  log "ERROR: yr exited with code $SCAN_RC (see $LOG_FILE)"
  exit 4
fi

if [ "$KEEP_BINARY" -eq 1 ]; then
  mkdir -p "${OUTPUT_DIR}/bin"
  cp "$YR" "${OUTPUT_DIR}/bin/yr"
  log "Kept yr binary at ${OUTPUT_DIR}/bin/yr"
fi

if [ -s "$LOG_FILE" ]; then
  log "yr wrote $(wc -l <"$LOG_FILE" | tr -d ' ') warning/error line(s) to $LOG_FILE"
else
  rm -f "$LOG_FILE"
fi

# Any output in text/ndjson mode means at least one match; json always prints an object
if [ "$OUTPUT_FORMAT" = "json" ]; then
  grep -q '"rule"\|"identifier"' "$RESULT_FILE" && MATCHED=1 || MATCHED=0
else
  [ -s "$RESULT_FILE" ] && MATCHED=1 || MATCHED=0
fi

if [ "$MATCHED" -eq 1 ]; then
  log "MATCHES FOUND - see $RESULT_FILE"
  exit 1
fi
log "No matches."
exit 0
