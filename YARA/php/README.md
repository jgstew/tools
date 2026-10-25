# YARA: PHP install detection + version

Find every PHP install on a machine (package-managed or one-off: XAMPP, WAMP,
Laragon, MAMP, cPanel EA-PHP, Remi SCL, phpbrew, static builds, …) and report
its version, on Linux, Windows and macOS - **without running PHP**.

Detection is intentionally **broad**: it is better to flag something PHP-related
that turns out to be uninteresting than to miss an install. Tighten later from
real results.

## Files

| File | What it's for |
|---|---|
| `php_detect.yar` | Main rules. Detects PHP and carries the **exact version** in the matched string (`yara -s`). |
| `php_version_branches.yar` | One rule per branch (`PHP_8_2`, `PHP_7_4`, …). The **rule name is the version** - for engines that only report rule names (osquery, EDRs). Generated. |
| `gen_php_branches.py` | Generates `php_version_branches.yar`. Edit this, not the `.yar`. |
| `detect_running_php.md` | Which PHP is running / listening on a port: commands per OS and BigFix client relevance, with tested results. |
| `gen_running_php_relevance.py` | Generates the one cross-platform relevance statement in `detect_running_php.md` that lists running and listening PHP. It flags likely PHP with evidence and adds versions from the `php` lines of `yara_results_runtimes.text`. |

The header check (`../is_executable.yar`), `../sync_rules.py`, the summary
filter (`../versions.awk`), the scan scripts and the BigFix content are shared
with the Node.js rules: see [../README.md](../README.md).

Both `.yar` files use no YARA modules (`pe`, `elf`, `macho`), so they work in
embedded engines built without them, and their rule names don't collide - load
them together or separately (or with `../node/node_detect.yar`).

## Rules in `php_detect.yar`

| Rule | Confidence | Matches | Version from |
|---|---|---|---|
| `PHP_Runtime_Version` | high | PHP core: `php`, `php-cgi`, `php-fpm`, `phpdbg`, `libphp*.so`, `php*ts.dll`, `php8.dll`, statically embedded PHP | `$ver` = `X-Powered-By: PHP/<version>` - a compile-time literal, present even with `expose_php=Off`. Includes distro suffix, e.g. `8.1.2-1ubuntu2.27`. |
| `PHP_Windows_VersionInfo` | high | Any Windows PE whose version resource says `ProductName = PHP`: `php.exe`, `php-cgi.exe`, `php-win.exe`, SAPI DLLs, `ext\php_*.dll` | `$pv` = `ProductVersion` |
| `PHP_Binary_Broad` | medium | Catch-all: any ELF/PE/Mach-O with any PHP marker (version string, `Zend Engine v`, `API2xxxxxxx,NTS/TS` build ID, PHP version resource, `The PHP Group` + `php.ini`). Includes Linux extensions (`.so`). | - (use the branch rules or the API table below) |

Every rule is gated on the shared executable header check, see
[../README.md](../README.md#executable-header-check).

On Windows the `X-Powered-By` string lives in `php7ts.dll` / `php8.dll` / `php8ts.dll`,
not in `php.exe` (except 8.5+) - `php.exe` is caught by its version resource instead.

`php-config` and `main/php_version.h` (source builds, `-dev` packages) are no
longer matched: the runtime rules already find the PHP binary itself, the text
rule matched any small file that happened to contain those strings, and it
forced every file under 64 KB to be read in full.

## Usage

### Exact versions (YARA CLI)

`yara` takes **one** target per run (every earlier argument is read as a rules file).

```bash
yara -s -r php_detect.yar /opt 2>/dev/null | awk -f ../versions.awk | sort -u
```

```text
/opt/remi/php82/root/usr/bin/php    php    8.2.34      (illustrative; tab-separated)
/opt/lampp/bin/php                  php    8.1.2
```

YARA-X (`yr`) works the same; the awk filter also handles its `--print-meta` output.
The [scan scripts](../README.md#scan-scripts) embed `php_detect.yar` together
with the Node.js rules and do this as a self-contained whole-machine scan on
macOS, Linux and Windows.

```bash
yr scan --recursive --print-strings php_detect.yar /opt | awk -f ../versions.awk | sort -u
```

Windows (same flags; awk via Git Bash/WSL, or read the `$ver:` / `$pv:` lines directly):

```bat
yara64.exe -s -r php_detect.yar C:\
```

Raw `-s` output looks like this; `$pv` is UTF-16 so yara prints escaped NULs:

```text
PHP_Runtime_Version /usr/bin/php8.1
0x413030:$ver: X-Powered-By: PHP/8.1.2-1ubuntu2.27
PHP_Windows_VersionInfo C:\php\php.exe
0x21742:$pv: P\x00r\x00o\x00d\x00u\x00c\x00t\x00V\x00e\x00r\x00s\x00i\x00o\x00n\x00\x00\x008\x00.\x002\x00.\x003\x004\x00
```

### Branch only (rule-name based engines)

```bash
yara -r php_version_branches.yar /usr
```

```text
PHP_8_4 /usr/local/bin/php
PHP_8_4 /usr/local/lib/php/extensions/no-debug-non-zts-20240924/opcache.so
```

`PHP_Branch_Unknown` = looks like PHP but no branch rule recognised it (a new
branch, or an odd build). Review, add to `gen_php_branches.py`, regenerate
(`python3 ../sync_rules.py` also does this):

```bash
python3 gen_php_branches.py > php_version_branches.yar
```

Example with osquery's `yara` table (it returns rule names, not matched text):

```sql
SELECT path, matches FROM yara
WHERE path LIKE '/opt/%%'
  AND sigfile = '/var/osquery/yara/php_version_branches.yar'
  AND matches != '';
```

### Where to scan

Whole-filesystem scans work but are slow. Typical PHP locations:

| OS | Paths |
|---|---|
| Linux | `/usr/bin`, `/usr/sbin`, `/usr/lib*/apache2/modules`, `/usr/lib*/httpd/modules`, `/usr/local`, `/opt` (Remi SCL, cPanel `ea-php*`, Plesk, LAMPP), `/home/*/.phpbrew`, `/home/*/.asdf` |
| macOS | `/opt/homebrew`, `/usr/local`, `/opt/local` (MacPorts), `/Applications/MAMP`, `~/Library/Application Support/Herd` |
| Windows | `C:\php*`, `C:\xampp`, `C:\wamp*`, `C:\laragon`, `C:\tools`, `C:\Program Files\PHP`, `C:\Program Files (x86)` |

Add `-p <threads>` and an `--timeout` for big trees; skip `/proc`, `/sys`, network mounts.

## API build ID → branch

`PHP_Binary_Broad` matches extensions via the `API2xxxxxxx,NTS|TS` build ID; it
is also the Linux extension directory name (`no-debug-non-zts-20220829`).

| API | Branch | | API | Branch |
|---|---|---|---|---|
| 20090626 | 5.3 ¹ | | 20190902 | 7.4 |
| 20100525 | 5.4 ¹ | | 20200930 | 8.0 |
| 20121212 | 5.5 ¹ | | 20210902 | 8.1 |
| 20131226 | 5.6 | | 20220829 | 8.2 |
| 20151012 | 7.0 | | 20230831 | 8.3 |
| 20160303 | 7.1 | | 20240924 | 8.4 |
| 20170718 | 7.2 | | 20250925 | 8.5 |
| 20180731 | 7.3 | | | |

¹ From PHP source; not verified against a sample (no images available).

## Tested

YARA 4.5.4 (yara-python) and YARA-X (Python bindings) gave identical rule
matches on every file; the YARA 4.5.2 CLI (Debian trixie) + `php_versions.awk`
(now `../versions.awk`) produced the same versions. Every PHP binary below was detected with the
correct version:

| Source | OS / format | Versions |
|---|---|---|
| Official Docker images (`php:*`) | Linux ELF, glibc + musl (Alpine) | 5.6.40, 7.4.33 (incl. `libphp7.so`), 8.2.34 (`php-fpm`), 8.4.26 |
| Ubuntu 22.04 `php8.1-cli`, `libapache2-mod-php8.1` | Linux ELF | 8.1.2-1ubuntu2.27 |
| Rocky Linux 9 `php-cli`, `php-fpm` | Linux ELF | 8.0.30 |
| windows.php.net zips (TS + NTS, vc15/vs16/vs17) | Windows PE | 7.4.33, 8.2.34, 8.5.11 - all `.exe`, SAPI DLLs, every `ext\php_*.dll` |
| conda-forge `php` | macOS Mach-O arm64 | 8.5.9 |
| static-php.dev CLI builds | macOS Mach-O x86_64 | 8.3.32, 8.4.23, 8.5.8 |
| Debian 12 `php8.2-cli`; Ubuntu 24.04 `php8.3-cli`, `php8.3-fpm`, `libapache2-mod-php8.3` | Linux ELF (aarch64) | 8.2.35, 8.3.6 |
| windows.php.net zip (NTS vs16 x64) | Windows PE | 8.3.36 - `.exe`, SAPI DLLs, every `ext\php_*.dll` |

Not matched (correct): third-party DLLs shipped in the Windows zip (OpenSSL,
ICU, libpq, …), `deplister.exe`, a log file containing an `X-Powered-By: PHP/`
header, non-PHP binaries.

False-positive sweep: both rule files over a developer Mac's `/usr`,
`/opt/homebrew` and `/Applications` (813,213 files, incl. Electron apps and .NET
assemblies) - **0 hits**. An earlier version of the
branch rules matched `ProductVersion 7.0.*` in any PE, flagging every .NET 7
DLL as `PHP_7_0`; branch rules now require `ProductName = PHP` for that check.

## Limitations

- **Distro backports.** Debian/RHEL patch security fixes into old version numbers
  (`8.0.30` on Rocky may be patched beyond upstream 8.0.30). For packaged installs,
  compare against the package manager's version, not upstream CVE ranges.
- **Linux extensions** (`*.so`) carry no full version - only the branch (via the
  API build ID / branch rules).
- **Packed/compressed binaries** (UPX, self-extracting installers, `.zip`/`.msi`
  not yet extracted) won't match until unpacked. For example, static-php.dev's
  Linux CLI builds are UPX-packed and are not detected; its macOS builds are not
  packed and are.
- **Containers.** A host scan doesn't look inside image layers; scan an exported
  filesystem (`docker export`) or the container's merged rootfs.
- **Broad = some noise.** `PHP_Binary_Broad` can flag non-PHP tools that embed PHP
  strings (IDEs, scanners with PHP fingerprints). Use `PHP_Runtime_Version` /
  `PHP_Windows_VersionInfo` for the authoritative list.
