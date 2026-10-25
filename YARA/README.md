# YARA: PHP and Node.js install detection + version

Find every PHP and Node.js install on a machine and report its version, on
Linux, Windows and macOS - **without running anything**. Node.js includes Node
embedded in other software: Electron apps, single-executable applications,
vercel/pkg builds and apps that bundle `libnode`.

- [`php/`](php/README.md): PHP rules, branch rules, running-PHP detection
- [`node/`](node/README.md): Node.js and Electron rules

## Files

| File | What it's for |
|---|---|
| `is_executable.yar` | The executable header check every PHP and Node.js rule is gated on - the one place to edit it. On its own it reports the files that pass. |
| `sync_rules.py` | Copies `is_executable.yar` into `php/php_detect.yar`, `node/node_detect.yar` and the PHP branch rules, and embeds both rule files and `versions.awk` in the three scan scripts. `--check` reports copies that are out of date. |
| `versions.awk` | Turns `yara -s` / `yr scan -s` output of both rule files into the [summary](#summary-format). |
| `make_bigfix_content.py` | Generates the BigFix tasks and analysis (see [BigFix](#bigfix)) from the three scan scripts. |
| `php/` | PHP rules: [php/README.md](php/README.md) |
| `node/` | Node.js / Electron rules: [node/README.md](node/README.md) |

The rule files use no YARA modules (`pe`, `elf`, `macho`), so they work in
embedded engines built without them, and their rule names don't collide - load
them together or separately.

## Executable header check

Every PHP and Node.js rule requires a real executable, shared library or
loadable module, checked from fixed header fields only (`is_executable.yar`, no
modules):

| Format | Passes | Rejected |
|---|---|---|
| ELF | `e_type` EXEC or DYN (incl. PIE), either byte order | `.o` files, core dumps |
| PE | `MZ` + `PE\0\0` at `e_lfanew` | files that only start with `MZ` |
| Mach-O 32/64 | `filetype` EXECUTE, DYLIB or BUNDLE (PHP extensions, Node addons), either byte order | `.o` files, core dumps, dSYM debug symbols, kexts |
| Mach-O universal (`CAFEBABE` / `CAFEBABF`) | 1-19 architectures, and the first slice passes the Mach-O check | universal `.o` files, static libraries (`.a`) and dSYMs; Java `.class` files (same magic) |

YARA-X skips the pattern search of a file whose header fails the check, so
non-executables of any size cost about one header read.

To change the check, edit `is_executable.yar` and run `python3 sync_rules.py`.
It copies the condition into `php/php_detect.yar`, `node/node_detect.yar` and the
PHP branch rules, then embeds both rule files and `versions.awk` in the scan
scripts. CI fails if a copy is out of date (`sync_rules.py --check`) or a rule
file doesn't compile. All files involved must use LF line endings.

## Summary format

`versions.awk` (and its PowerShell port in the Windows script) writes one line
per product found in a file, tab-separated because paths contain spaces (example, from a Linux server and a Mac):

```text
path<TAB>product<TAB>version
```

```text
/usr/bin/php8.3	php	8.3.6
/usr/local/bin/node	node	22.23.4
/Applications/Visual Studio Code.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Electron Framework	node	24.21.0
/Applications/Visual Studio Code.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Electron Framework	electron	43.7.7
```

| Product | From rules | Version from |
|---|---|---|
| `php` | `PHP_*` | `$ver` (`X-Powered-By: PHP/...`) or `$pv` (Windows `ProductVersion`) |
| `node` | `Node_*` | `$ver` (`node.js/v...`); when no `$ver` matched, `$rel` (the `nodejs.org/download/release/v...` URL, vercel/pkg builds) |
| `electron` | `Node_Electron_Version` | `$electron` (`Electron/...`) |

- An Electron framework gets **two lines**: its embedded Node and Electron.
- A file that matched only a broad rule gets version `unknown`: PHP extensions
  with no version string, and for Node native addons (`.node`), the distro
  `node` launchers that load `libnode` (the version is in `libnode` next to
  them) and Bun-compiled executables. Expect many `node unknown` lines: every
  native addon in every `node_modules` is one.
- Paths with control characters are written bash `$'...'` quoted, so a raw tab
  never appears inside a path.

```bash
yr scan --recursive --print-strings php/php_detect.yar node/node_detect.yar /opt | awk -f versions.awk | sort -u
```

## Scan scripts

[`bash/yara_x_scan_macos.sh`](../bash/yara_x_scan_macos.sh) (macOS),
[`bash/yara_x_scan_linux.sh`](../bash/yara_x_scan_linux.sh) (Linux, all local disk
filesystems) and [`powershell/yara_x_scan_windows.ps1`](../powershell/yara_x_scan_windows.ps1)
(Windows, all local fixed drives; Windows PowerShell 5.1 and PowerShell 7) are
self-contained: each downloads `yr`, checks its SHA256, and scans with the PHP
and Node.js rules embedded as one rule file, so both are found in **one pass**.
A combined scan costs about the same as either rule set alone: both share the
header check, so the same files are opened, and `yr` searches every pattern in
a single pass over each file. They write the full `yr` output and the
[summary](#summary-format). Defaults aim at an unattended background scan:

- **1 `yr` thread at low priority** (`nice 10`, `ionice` on Linux where usable,
  BelowNormal on Windows). `-T 2` (bash) / `-Threads 2` (PowerShell) finishes
  about 1.5-2x sooner at about twice the peak CPU.
- **Skipped without opening:** files that can't start with an executable header
  (images, media, archives, documents, source/text, C headers, logs, databases,
  Xcode/SDK data, packages, debug symbols, ...), empty files, files of 512 MB or
  more (`-m` / `-MaxMB`), and folders that can't hold an install: containers and
  snapshots (Linux), the sealed system volume on macOS 12+, online-only iCloud /
  cloud files, and on Windows `WinSxS`, `servicing`, the .NET assembly caches,
  Defender definitions and the BigFix Console cache. `Program Files\WindowsApps`
  is scanned (MSIX / Store packages are installed software).
- **Scanning a skipped folder:** target it (`-t /var/lib/docker`,
  `-Path C:\Windows\WinSxS`); a skip that contains the target is turned off.
  `-A` (bash) / `-NoSkips` (PowerShell) turns off all the default skips at once,
  including the size cap unless `-m` / `-MaxMB` is given. Empty files and
  online-only cloud files are still skipped with `-A` / `-NoSkips` (reading
  cloud files would download them); on macOS, targeting a cloud folder with
  `-t` reads it.
- **Extra exclusions:** `-x DIR` (bash, repeatable, also a find `-path` pattern)
  or `-ExcludePath A,B` (PowerShell). An exclusion that contains the scan target
  is ignored.
- **Reusing the download:** `-k` / `-KeepArchive` keeps the `yr` release archive
  in the output folder; pass that folder back with `-a` / `-YaraXArchive` and its
  SHA256 is checked again.
- **Unusual file names (Linux, macOS):** `yr` reads its file list one UTF-8 path
  per line, so files whose paths contain control characters (newline, tab, ...)
  or, on Linux, aren't valid UTF-8 are scanned as copies in the work folder and
  reported as bash `$'...'` quoted paths (e.g. `$'/opt/new\nline/php'`). Windows
  file names can't contain either.

Measured cost (single runs, cold cache, 1 thread): ~90 s for a test Mac mini
(74k files sent to `yr`), ~8 min for a developer laptop (1.36M files), a few
seconds for a Linux server image. On Windows almost all of the time is Microsoft
Defender scanning each file the scan opens: ~15 min on a Server 2022 VM (111k
files), with Defender using about one core while `yr` stays mostly idle. Opening
fewer files is what speeds Windows up; 2 threads lets Defender check two files at
once (~8 min, both cores busy).


## BigFix

`make_bigfix_content.py` turns the three scan scripts into BigFix content in a
[bigfix-content](https://github.com/jgstew/bigfix-content) checkout next to this repo:

| File | What it does |
|---|---|
| `fixlet/Scan for PHP and Node.js Installs with YARA-X - macOS.bes` | Prefetches the `yr` archive for the CPU, copies it, the embedded script and a small wrapper to `__BESData/__Global/yara_runtime_scan`, and starts the wrapper with `run`. The wrapper scans in the background and copies the [summary](#summary-format) to `__BESData/__Global/Logs/yara_results_runtimes.text` (console output: `yara_scan_runtimes.log`). |
| `fixlet/Scan for PHP and Node.js Installs with YARA-X - Linux.bes` | Same, Linux x86_64 / aarch64. |
| `fixlet/Scan for PHP and Node.js Installs with YARA-X - Windows.bes` | Same, Windows 10 / Server 2016+ x64, 64-bit PowerShell 5.1+. |
| `analyses/PHP and Node.js Installs from YARA-X Scan - Universal.bes` | Reports a summary once a day: the distinct PHP, Node.js and Electron versions, the number of PHP and Node.js files (Node.js files include native addons), and the scan time. |

`run` (not `wait`) keeps the BigFix agent free for other actions during the scan,
and the work folder isn't `__Download` (the client clears it when the action ends).
The tasks are relevant again once the results file is a day old, but not while a
scan is running (`scan.running` marker, ignored after 12 hours). The scripts get
the prefetched archive with `-a` (bash) / `-YaraXArchive` (PowerShell) and still
check its SHA256. After changing a script or a rule (run `python3 sync_rules.py`
first for a rule), regenerate:

```bash
python3 make_bigfix_content.py
```

