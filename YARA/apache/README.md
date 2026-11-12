# YARA: Apache httpd + mod_http2 detection + version

Find Apache HTTP Server installs and `mod_http2` modules on Linux, Windows and
macOS, and report their version, **without running anything**. Signatures are
based on jeffschafer's Apache mod_http2 scanner.

The header check (`../is_executable.yar`), `../sync_rules.py`, the summary
filter (`../versions.awk`, products `apache` and `mod_http2`), the scan scripts
and the BigFix content are shared with the PHP and Node.js rules: see
[../README.md](../README.md). The scan scripts look for all three in one pass.

## Files

| File | What it's for |
|---|---|
| `apache_detect.yar` | The rules. Its `Apache_Detect_IsExecutable` is copied from `../is_executable.yar` by `../sync_rules.py`. |

## Rules in `apache_detect.yar`

| Rule | Matches | Version from |
|---|---|---|
| `Apache_HTTPD_Version` | The file holding the httpd core: `httpd` on Linux and macOS, `libhttpd.dll` on Windows | `$ver` = `Apache/<version>` |
| `Apache_HTTP2_Module` | `mod_http2.so`, or an httpd with mod_http2 built in | `$_module_ver` = bare `2.x.y` string, a **candidate** only |

## Signatures

| Marker | Where | Used for |
|---|---|---|
| `Apache/<version>` | `AP_SERVER_BASEVERSION`, the server banner | httpd version. Also in modules built against httpd (`mod_ssl`, `mod_proxy`), so it only counts together with the core marker. |
| `\0ServerTokens\0`, `Could not reliably determine the server's fully qualified domain name` | the core's directive table and its `AH00558` error message | marks the core: in httpd / apache2, in none of the modules (Ubuntu 24.04, macOS 14). `ServerTokens` is matched only as a whole C string: `mod_security2` has it inside a message, and its `ModSecurity for Apache/2.9.7` banner matches the version string. `AH00109: ap_get_server_name: Invalid UCN Option` was tried first, but Ubuntu's `apache2` doesn't have it. |
| `mod_http2_init_counter`, `mod_http2 (v%s, feats=` | `modules/http2/mod_http2.c` | marks mod_http2. Not `http2_module`: it is also inside `proxy_http2_module` (`mod_proxy_http2.so`). |
| `\0` `2.x.y` `\0`, or with a `-` suffix (`2.0.26-git`, RHEL 9) | `MOD_HTTP2_VERSION` | candidate mod_http2 version. The same mod_http2 version ships with more than one httpd release, so don't treat it as proof of a version without package or hash evidence. |

## Usage

```bash
yr scan --recursive --print-strings apache/apache_detect.yar /usr
```

## Tested

Each row is a real scan with the scan script for that OS. The httpd version
was checked against `httpd -v` / `apache2 -v` (Linux, macOS) or the
`libhttpd.dll` version resource (Windows).

| Platform | httpd | mod_http2 | Not reported (correctly) |
|---|---|---|---|
| macOS 14 (arm64), bundled, `-t /` with the sealed-volume skip on | `/usr/sbin/httpd` 2.4.67 (universal) | 2.0.39 | `mod_ssl`, `mod_proxy`, `mod_proxy_http`, the rest of `/usr` outside `/usr/local`; nothing else under `/Applications`, `/opt/homebrew` |
| Ubuntu 24.04 (x86_64 and arm64, Docker), `apache2-bin`, `-t /` | `/usr/sbin/apache2` 2.4.58 | 2.0.42 | `mod_ssl`, `mod_proxy_http2` and every other module |
| Ubuntu 26.04 (arm64, Docker), `-t /` | `/usr/sbin/apache2` 2.4.66 | 2.0.42 | every other module |
| Debian 12 (arm64, Docker), `-t /` | `/usr/sbin/apache2` 2.4.71 | 2.0.42 | every other module |
| Rocky Linux 9 (arm64) and UBI 9 (x86_64), Docker, `httpd` + `mod_http2`, `-t /` | `/usr/sbin/httpd` 2.4.62 | 2.0.26-git (separate package) | every other module |
| Amazon Linux 2023 (x86_64, Docker), `-t /` | `/usr/sbin/httpd` 2.4.69 | 2.0.42 | every other module |
| openSUSE Leap 15 (arm64, Docker), `-t /` | `/usr/sbin/httpd-prefork` 2.4.66 | 2.0.35 | the `/usr/sbin/httpd` and `/usr/lib64/apache2/mod_http2.so` symlinks (alternatives; symlinks aren't scanned, their targets are) |
| Windows Server 2022, Apache Lounge `httpd-2.4.71-261112-Win64-VS18.zip` | `bin\libhttpd.dll` 2.4.71 (`httpd.exe` is a launcher) | 2.0.42 | `httpd.exe`, `mod_ssl.so`, `mod_proxy_http2.so` and every other module |

Not tested yet: httpd 2.2, an httpd with mod_http2 built in, XAMPP / WAMP
builds.
