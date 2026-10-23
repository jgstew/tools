#!/usr/bin/env bash
#### Usage: ./yara_x_scan_macos.sh [-t TARGET_PATH] [-o OUTPUT_DIR] [-f text|json|ndjson] [-k] [-a YR_ARCHIVE] [-m MAX_MB] [-T THREADS] [-x DIR]... [-S] [-E] [-C]
#
# Self-contained YARA-X scan for macOS:
#   1. downloads the YARA-X CLI (yr) release for this CPU architecture
#   2. verifies the SHA256 of the download against a pinned value
#   3. unpacks it into a temporary folder
#   4. scans TARGET_PATH (recursively) with the YARA rule embedded below,
#      staying on TARGET_PATH's volume: other mounts (DMGs, network shares,
#      external disks, autofs, Time Machine snapshots) are skipped
#   5. writes results + a log to OUTPUT_DIR; for text format:
#        yara_results_<host>_<time>.raw.text  full yr output (rules, meta, strings)
#        yara_results_<host>_<time>.text      "path<TAB>version", one per line
#
#        Files matched with no version string, e.g. Linux PHP extensions,
#        are listed with version "unknown".
#
# Run with sudo (and give the terminal / agent Full Disk Access) for a full
# scan; otherwise protected files are logged as unreadable and skipped.
#
# Options:
#   -t TARGET_PATH  file or folder to scan            (default: / = whole local boot drive)
#   -o OUTPUT_DIR   folder to write results into      (default: ./yara_results)
#   -f FORMAT       yr output format: text|json|ndjson (default: text)
#   -k              keep the downloaded yr binary in OUTPUT_DIR/bin for reuse
#   -a YR_ARCHIVE   use a local yr release archive instead of downloading: the
#                   file, or a folder holding it under its release name (e.g. a
#                   BigFix prefetch folder); its SHA256 is still checked
#   -m MAX_MB       skip files of MAX_MB MB or larger, 0 = no limit (default: 512)
#   -T THREADS      yr scan threads                   (default: 2)
#   -x DIR          also skip this folder; repeat for more (a find -path
#                   pattern such as '*/node_modules' works too)
#   -S              also scan the sealed macOS system paths
#   -E              also scan file types that can't be executables
#   -C              also scan cloud-drive folders
#   -h              show this help
#
# Skipped by default (none of these can hold a likely PHP install; each skip
# is reported while running, files over the size cap are listed in the log):
#   - files of 512 MB or more: PHP builds are ~20 MB, the largest known
#     (FrankenPHP, static PHP in Go) ~180 MB; this cuts VM disks, Docker.raw,
#     model weights, media
#   - on macOS 12+ (no bundled PHP): /System, /bin, /sbin, /usr except
#     /usr/local, /Library/Apple - the read-only sealed system volume
#   - images, media, archives, documents, fonts, web/source/text files, C
#     headers other than php_version.h, Xcode/SDK data (.swiftmodule, .tbd,
#     ...), logs and databases: the rules only match executables (by header)
#     and php-config/php_version.h; files with no extension, .dylib, .so,
#     .dll, .exe, .a, .o are kept
#   - empty files
#   - ~/Library/CloudStorage, ~/Library/Mobile Documents (iCloud), and
#     online-only (dataless) files anywhere, e.g. iCloud "Desktop & Documents":
#     reading them would download them
# A skip whose folder contains TARGET_PATH is turned off automatically, and
# none apply when TARGET_PATH is a single file.
#
# find and yr run at low priority (nice 10) and yr uses 2 threads (-T), so a
# full scan doesn't take over the machine.
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
YR_ARCHIVE=""
MAX_MB=512
THREADS=2
EXCLUDE_DIRS=()
SKIP_SEALED=1
SKIP_NONBINARY=1
SKIP_CLOUD=1

# Extensions of files that can't start with an executable header and aren't
# php-config / php_version.h. Compared case-insensitively with the text after
# the last "." of the file name; php_version.h is kept despite "h". The second
# line was measured on a Mac (no executables among them): Xcode/SDK, unified
# logs, Chromium/app resources and SQLite/LMDB side files, ~half of the files
# left after the first line. Not .a: macOS static libraries can be universal binaries.
NONBINARY_EXTS='jpg jpeg png gif heic tif tiff bmp webp ico icns svg svgz mov mp4 m4v avi mkv mp3 m4a aac wav aiff caf flac pdf zip gz tgz xz bz2 zst 7z rar dmg pkg xip iso jar whl docx xlsx pptx doc xls ppt pages numbers key txt md rst json js mjs cjs ts tsx jsx map css scss html htm xml plist strings nib car py pyc rb php java class go rs c cc cpp h hpp m swift yml yaml toml ini csv tsv log sqlite db sqlite-wal sqlite-shm ttf otf woff woff2 mo po lock sum'  # codespell:ignore caf
NONBINARY_EXTS="$NONBINARY_EXTS swiftmodule swiftdoc swiftinterface swiftsourceinfo tbd modulemap apinotes pcm metallib tracev3 bnnsir pak fxf data bom db-wal db-shm mdb"

usage() {
  awk 'NR > 1 && /^# Release:/ { exit } NR > 1 { sub(/^# ?/, ""); print }' "$0"
}

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

while getopts ":t:o:f:ka:m:T:x:SECh" opt; do
  case "$opt" in
    t) TARGET_PATH="$OPTARG" ;;
    o) OUTPUT_DIR="$OPTARG" ;;
    f) OUTPUT_FORMAT="$OPTARG" ;;
    k) KEEP_BINARY=1 ;;
    a) YR_ARCHIVE="$OPTARG" ;;
    m) MAX_MB="$OPTARG" ;;
    T) THREADS="$OPTARG" ;;
    x) [ "$OPTARG" = / ] && EXCLUDE_DIRS+=( / ) || EXCLUDE_DIRS+=( "${OPTARG%/}" ) ;;
    S) SKIP_SEALED=0 ;;
    E) SKIP_NONBINARY=0 ;;
    C) SKIP_CLOUD=0 ;;
    h) usage; exit 0 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage; exit 2 ;;
  esac
done

case "$OUTPUT_FORMAT" in
  text|json|ndjson) ;;
  *) echo "Invalid format '$OUTPUT_FORMAT' (use text, json or ndjson)." >&2; exit 2 ;;
esac

case "$MAX_MB" in
  ''|*[!0-9]*) echo "Invalid -m '$MAX_MB' (whole number of MB, 0 = no limit)." >&2; exit 2 ;;
esac

case "$THREADS" in
  ''|*[!0-9]*|0) echo "Invalid -T '$THREADS' (number of threads, 1 or more)." >&2; exit 2 ;;
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
RESULT_BASE="${OUTPUT_DIR}/yara_results_$(hostname -s)_${TIMESTAMP}"
SUMMARY_FILE=""
if [ "$OUTPUT_FORMAT" = "text" ]; then
  RESULT_FILE="${RESULT_BASE}.raw.text"
  SUMMARY_FILE="${RESULT_BASE}.text"
else
  RESULT_FILE="${RESULT_BASE}.${OUTPUT_FORMAT}"
fi
LOG_FILE="${OUTPUT_DIR}/yara_scan_$(hostname -s)_${TIMESTAMP}.log"

# ---- download -------------------------------------------------------------
if [ -n "$YR_ARCHIVE" ]; then
  [ -d "$YR_ARCHIVE" ] && YR_ARCHIVE="${YR_ARCHIVE%/}/${ASSET_NAME}"
  if [ ! -f "$YR_ARCHIVE" ]; then
    log "ERROR: yr archive not found: $YR_ARCHIVE"
    exit 3
  fi
  log "Using local archive $YR_ARCHIVE"
  cp "$YR_ARCHIVE" "${WORK_DIR}/${ASSET_NAME}"
else
  log "Downloading $ASSET_URL"
  if ! curl --fail --silent --show-error --location \
       --retry 3 --retry-delay 2 --connect-timeout 30 \
       --output "${WORK_DIR}/${ASSET_NAME}" "$ASSET_URL"; then
    log "ERROR: download failed"
    exit 3
  fi
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
# PHP install detection + version. Copy of YARA/php/php_detect.yar - keep in
# sync. The version is in the printed strings ($ver, $pv, $cfg_ver, $hdr_ver).
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

# ---- embedded version extractor (text format) -----------------------------
# Copy of YARA/php/php_versions.awk - keep in sync.
VERSIONS_AWK="${WORK_DIR}/php_versions.awk"
cat > "$VERSIONS_AWK" <<'AWK_SCRIPT'
# rule line: "<RULE> <path>", or with yr --print-meta "<RULE> [meta...] <path>"
/^PHP_/ { file = $0; sub(/^[^ ]+ /, "", file); sub(/^\[[^]]*\] /, "", file); seen[file] = 1; next }

# string line: "0xOFFSET:$id: <matched text>"
/:\$(ver|pv|cfg_ver|hdr_ver): / {
  v = $0; gsub(/\\x00/, "", v); sub(/^[^ ]+ /, "", v)
  if (match(v, /[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+~_-]*/)) { print file "\t" substr(v, RSTART, RLENGTH); versioned[file] = 1 }
}

END { for (f in seen) if (!(f in versioned)) print f "\tunknown" }
AWK_SCRIPT

# ---- build list of files to scan ------------------------------------------
# yr has no "stay on one filesystem" option, so find builds the file list:
#  -xdev       don't cross into other mounts (DMGs, network shares, external
#              disks, autofs). The APFS Data volume is firmlinked into / with
#              the same device id, so /Users, /Applications etc. are included.
#  -type f     regular files only; symlinks are not followed
#  prunes      /System/Volumes (Data would be scanned twice via its firmlinks,
#              the rest are separate system volumes), /dev, and this script's
#              own output/work folders (old results contain matched strings),
#              plus the default skips described in the header
# Paths are resolved with pwd -P because /var, /tmp are symlinks to /private.
if [ "$(id -u)" -ne 0 ]; then
  log "WARNING: not running as root - protected files will be skipped (see log)"
fi
OUTPUT_DIR_REAL="$(cd "$OUTPUT_DIR" && pwd -P)"
WORK_DIR_REAL="$(cd "$WORK_DIR" && pwd -P)"
if [ -d "$TARGET_PATH" ]; then
  TARGET_PATH="$(cd "$TARGET_PATH" && pwd -P)"
else
  TARGET_PATH="$(cd "$(dirname "$TARGET_PATH")" && pwd -P)/$(basename "$TARGET_PATH")"
fi

# path_within PATH DIR: PATH is DIR or somewhere below it
path_within() { case "$1/" in "$2"/*) return 0 ;; esac; return 1; }

# An explicitly named file is always scanned
NONEMPTY=( -size +0c )
if [ -f "$TARGET_PATH" ]; then
  MAX_MB=0; SKIP_SEALED=0; SKIP_NONBINARY=0; SKIP_CLOUD=0; NONEMPTY=()
fi

if [ "$SKIP_SEALED" -eq 1 ]; then
  MACOS_MAJOR="$(sw_vers -productVersion | cut -d. -f1)"
  if [ "$MACOS_MAJOR" -lt 12 ]; then
    log "macOS $MACOS_MAJOR may have bundled PHP in /usr/bin - scanning system paths"
    SKIP_SEALED=0
  fi
  for d in /System /bin /sbin /Library/Apple /usr; do
    if path_within "$TARGET_PATH" "$d" && ! path_within "$TARGET_PATH" /usr/local; then
      SKIP_SEALED=0
    fi
  done
fi
if [ "$SKIP_CLOUD" -eq 1 ]; then
  case "$TARGET_PATH/" in
    */Library/CloudStorage/*|*/Library/Mobile\ Documents/*) SKIP_CLOUD=0 ;;
  esac
fi

PRUNE=( -path /System/Volumes -o -path /dev -o -path "$OUTPUT_DIR_REAL" -o -path "$WORK_DIR_REAL" )
if [ "$SKIP_SEALED" -eq 1 ]; then
  # find's -path * also matches "/", hence both /usr/local exclusions
  PRUNE+=( -o -path /System -o -path /bin -o -path /sbin -o -path /Library/Apple
           -o \( -path '/usr/*' ! -path /usr/local ! -path '/usr/local/*' \) )
  log "Skipping sealed system paths (use -S to include)"
fi
# -x: find prints resolved paths, so an existing folder is resolved like
# TARGET_PATH (/tmp -> /private/tmp). A skip that is or contains TARGET_PATH
# would prune the whole walk, so like the other skips it is turned off.
# ${a[@]+"${a[@]}"}: bash 3.2 (macOS) calls an empty array unbound under set -u
for d in ${EXCLUDE_DIRS[@]+"${EXCLUDE_DIRS[@]}"}; do
  if [ -d "$d" ]; then d="$(cd "$d" && pwd -P)"; fi
  # $d unquoted on purpose: it may be a pattern such as */node_modules
  # shellcheck disable=SC2254
  case "$TARGET_PATH/" in ${d%/}/*) log "Not skipping $d (-x): it contains $TARGET_PATH"; continue ;; esac
  PRUNE+=( -o -path "$d" )
  log "Skipping $d (-x)"
done
DATALESS=()
if [ "$SKIP_CLOUD" -eq 1 ]; then
  PRUNE+=( -o -path '*/Library/CloudStorage' -o -path '*/Library/Mobile Documents' )
  # iCloud "Desktop & Documents" leaves online-only files outside those folders.
  # An unknown flag name is a fatal find error, so probe it first (older macOS).
  if find / -maxdepth 0 -flags +dataless >/dev/null 2>&1; then
    DATALESS=( ! -flags +dataless )
  fi
  log "Skipping cloud-drive folders and online-only files (use -C to include)"
fi
# Files at/over the cap are printed with a SKIPPED_SIZE tag, split out below
SIZE_TEST=( -print )
if [ "$MAX_MB" -gt 0 ]; then
  SIZE_TEST=( \( -size -"$((MAX_MB * 1048576))"c -print -o -exec printf 'SKIPPED_SIZE\t%s\n' {} + \) )
  log "Skipping files of ${MAX_MB} MB or more (use -m 0 to include)"
fi

SCAN_LIST="${WORK_DIR}/scan_list.txt"
FIND_LIST="${WORK_DIR}/find_list.txt"
log "Listing files under $TARGET_PATH (skipping other mounts)"
nice -n 10 find "$TARGET_PATH" -xdev \( "${PRUNE[@]}" \) -prune \
  -o -type f ${NONEMPTY[@]+"${NONEMPTY[@]}"} ${DATALESS[@]+"${DATALESS[@]}"} \
  "${SIZE_TEST[@]}" >"$FIND_LIST" 2>>"$LOG_FILE" || true  # non-zero on permission errors

TAB=$'\t'
SIZE_SKIPPED="$(grep -c "^SKIPPED_SIZE${TAB}" "$FIND_LIST" || true)"
if [ "$SIZE_SKIPPED" -gt 0 ]; then
  sed -n "s/^SKIPPED_SIZE${TAB}/skipped (>= ${MAX_MB} MB): /p" "$FIND_LIST" >>"$LOG_FILE"
  log "Skipped $SIZE_SKIPPED file(s) of ${MAX_MB} MB or more (listed in $LOG_FILE)"
fi
if [ "$SKIP_NONBINARY" -eq 1 ]; then
  # Extension lookup in awk, ~3x faster than macOS grep -Eiv with a 100-way
  # alternation (20 s vs 64 s for 4.1M paths) and the same result
  awk -v exts="$NONBINARY_EXTS" '
    BEGIN { n = split(exts, a, " "); for (i = 1; i <= n; i++) skip[a[i]] = 1 }
    /^SKIPPED_SIZE\t/ { next }
    { f = $0; sub(/.*\//, "", f)
      if (f == "php_version.h") { print; next }
      if (match(f, /\.[^.]*$/) && (tolower(substr(f, RSTART + 1)) in skip)) next
      print }' "$FIND_LIST" >"$SCAN_LIST"
  NONBINARY_SKIPPED=$(( $(wc -l <"$FIND_LIST") - SIZE_SKIPPED - $(wc -l <"$SCAN_LIST") ))
  log "Skipped $NONBINARY_SKIPPED non-executable file type(s) (use -E to include)"
else
  grep -v "^SKIPPED_SIZE${TAB}" "$FIND_LIST" >"$SCAN_LIST" || true
fi
log "Found $(wc -l <"$SCAN_LIST" | tr -d ' ') file(s) to scan"

# ---- scan -----------------------------------------------------------------
log "Scanning with $THREADS thread(s) at low priority..."
log "Results: $RESULT_FILE"
SCAN_RC=0
nice -n 10 "$YR" scan --scan-list --print-meta --print-strings --threads "$THREADS" \
  --output-format "$OUTPUT_FORMAT" \
  "$RULE_FILE" "$SCAN_LIST" >"$RESULT_FILE" 2>>"$LOG_FILE" || SCAN_RC=$?

# find and yr report per-file errors (e.g. permission denied) on stderr; yr still
# scans the rest and exits 0, so non-zero means the scan itself failed
if [ "$SCAN_RC" -ne 0 ]; then
  log "ERROR: yr exited with code $SCAN_RC (see $LOG_FILE)"
  exit 4
fi

if [ -n "$SUMMARY_FILE" ]; then
  awk -f "$VERSIONS_AWK" "$RESULT_FILE" | sort -u >"$SUMMARY_FILE"
  log "Versions: $SUMMARY_FILE ($(wc -l <"$SUMMARY_FILE" | tr -d ' ') path(s))"
fi

if [ "$KEEP_BINARY" -eq 1 ]; then
  mkdir -p "${OUTPUT_DIR}/bin"
  cp "$YR" "${OUTPUT_DIR}/bin/yr"
  log "Kept yr binary at ${OUTPUT_DIR}/bin/yr"
fi

if [ -s "$LOG_FILE" ]; then
  log "$(wc -l <"$LOG_FILE" | tr -d ' ') skip/warning/error line(s) in $LOG_FILE"
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
