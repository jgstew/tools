# Detecting running / listening PHP (Linux, macOS, Windows)

The YARA scans in this folder answer "which PHP builds are on disk, and which
version is each one" (`path<TAB>version`, see [README](README.md)). This page
answers the next question: **which of them is actually running, and which is
serving on a network port**, from the command line and from BigFix client
relevance. Every command and relevance statement below was run; what wasn't is
marked **not tested**. Tested 2026-10-21. In sample output, test folders are
shortened to `<testdir>` (macOS) and `C:\phprun` (Windows).

## Summary

- **The listening process is often not called `php`.** Find listeners with their
  owning PID, then decide whether that process *is* PHP (exe path) or *hosts*
  PHP (a loaded `libphp*.so` / `php*.dll`). The name alone misses mod_php and
  renamed binaries.
- **Version per port:** join the listener's exe path (or loaded PHP library
  path) to the YARA list. On Windows the PE version resource gives the version
  directly; on Linux, YARA-scanning `/proc/<pid>/exe` gives the version of what
  is *running* (it also covers containers and binaries replaced by an upgrade).
- **BigFix relevance can do a lot of this** on all three platforms
  (`sockets of network` → `process of <socket>` → `image file`), and can join to
  `yara_results_php.text` directly. It **cannot** see loaded modules on Windows or
  macOS (mod_php, `php8apache2_4.dll` in `httpd.exe`), command lines on Windows or
  macOS, or unix sockets on macOS. Linux relevance covers mod_php and
  containers by reading `/proc/<pid>/maps` and `/proc/<pid>/net/tcp` as files.
  [Statement 7](#7-one-statement-for-all-platforms-running-and-listening-php-best-effort)
  is a single statement for all platforms. It flags likely PHP with
  per-line evidence and adds versions when YARA results exist.
- **Recommended:** a small per-OS script (like the YARA tasks) that writes
  `port<TAB>pid<TAB>exe<TAB>php_file<TAB>version` to a results file for an analysis,
  plus the relevance join as a no-script quick win. See
  [Recommended approach](#recommended-approach).

## What counts as "PHP running / listening"

| # | Case | Who owns the port | How to recognise PHP |
|---|---|---|---|
| 1 | PHP CLI as its own server: `php -S`, ReactPHP / Workerman / Swoole-style `stream_socket_server` loops | `php` | exe is PHP |
| 2 | php-fpm (TCP `127.0.0.1:9000` or a unix socket); the web port belongs to nginx/Apache in front | `php-fpm` (master + workers) | exe is PHP |
| 3 | php-cgi / FastCGI (`php-cgi -b`, IIS FastCGI) | `php-cgi` (IIS: port 80/443 is `System`, PID 4) | exe is PHP |
| 4 | mod_php: PHP is a library inside the web server | `apache2` / `httpd` / `httpd.exe` | loaded `libphp*.so` / `php*ts.dll` / `php8.dll` |
| 5 | FrankenPHP, renamed or static builds | `frankenphp`, or any name | exe or loaded library is PHP; renamed: only by path/content |

### Which method catches which case

Tested results (✓ caught, ✗ missed, — not applicable). "Name" = owning process
name contains `php`; "Exe → YARA" = exe path found in the YARA list;
"Modules" = PHP library or extension in the process's loaded images.

| Method | 1 CLI server | 2 php-fpm TCP | 2 php-fpm unix | 3 php-cgi | 4 mod_php / DLL host | 5 FrankenPHP | 5 renamed `php` |
|---|---|---|---|---|---|---|---|
| Socket owner name (`ss`/`lsof`/`netstat`/`Get-NetTCPConnection`) | ✓ | ✓ | ✓ `ss -lxp`, `lsof -U` only | ✓ | ✗ (`apache2`) | ✓ | ✗ |
| Exe path → YARA list (script or relevance join) | ✓ | ✓ | ✓ | ✓ | ✗ (exe is the web server) | ✓ | ✓ |
| Loaded modules (Linux `/proc/<pid>/maps`, Windows `Get-Process -Module` / `tasklist /m`, macOS `lsof -d txt`) | ✓ | ✓ | ✓ | ✓ | ✓ Linux, ✓ Windows (simulated), macOS **not tested** | ✓ Docker image (`libphp.so`); static build: exe only | ✓ Linux (`/php/extensions/*.so`), ✓ Windows (`php8.dll`); ✗ macOS static |
| Windows PE `ProductName = PHP` on exe / module | ✓ | — | — | ✓ | ✓ via module version | **not tested** | ✓ |
| YARA on `/proc/<pid>/exe` (+ `/proc/<pid>/root/<libphp>`) | ✓ | ✓ | ✓ | ✓ | ✓ (scan the mapped `libphp.so`) | ✓ | ✓ |

RoadRunner (not tested): the port belongs to the Go binary `rr`, and PHP workers
are child `php` processes talking over pipes. Look for `php` children of the
listener (`ppid`), not for a PHP listener. Swoole/OpenSwoole (not tested) run as
`php` with `swoole.so` loaded, so they fall under case 1.

## Linux

Tested in Docker on an Apple Silicon Mac (arm64 images, Docker Desktop VM),
with a Debian 12 helper container (`iproute2`, `lsof`, `net-tools`, `procps`,
`yara` 4.2.3) sharing the target's PID + network namespaces
(`--pid=container:X --net=container:X --cap-add SYS_PTRACE`), and from the VM
host namespaces (`--pid=host --net=host --privileged`).

| Container | Image | What listened |
|---|---|---|
| cli | `php:8.5-cli` (PHP 8.5.12, Debian 13) | `php -S :8080`, `php -r` stream server `:8081`, `webd -S :8082` (copy of `php`), `php-cgi -b 127.0.0.1:9001` |
| fpm | `php:8.4-fpm` (8.4.27) | php-fpm TCP `:9000` + second pool on unix socket `/run/php-fpm-sock.sock` |
| fpm-alpine | `php:8.3-fpm-alpine` (8.3.36, Alpine 3.24, busybox) | same as fpm |
| apache | `php:8.4-apache` (8.4.27, mod_php) | `apache2 :80` |
| frankenphp | `dunglas/frankenphp` (8.5.12) | `frankenphp :80, :443, 127.0.0.1:2019` |

### Commands

```bash
ss -ltnp          # TCP listeners + every process holding the socket
ss -lxp           # unix-socket listeners (php-fpm sockets)
lsof -nP -iTCP -sTCP:LISTEN
lsof -nP -U       # unix sockets
netstat -tlnp     # net-tools; shows only ONE pid per socket
```

```text
$ ss -ltnp                                             (cli container)
LISTEN 0 32    0.0.0.0:8081   0.0.0.0:*  users:(("php",pid=9,fd=3))
LISTEN 0 4096  0.0.0.0:8080   0.0.0.0:*  users:(("php",pid=8,fd=4))
LISTEN 0 4096  0.0.0.0:8082   0.0.0.0:*  users:(("webd",pid=11,fd=4))
LISTEN 0 128 127.0.0.1:9001   0.0.0.0:*  users:(("php-cgi",pid=10,fd=4))

$ ss -ltnp ; ss -lxp                                   (fpm container)
LISTEN 0 4096  *:9000  *:*  users:(("php-fpm",pid=8,fd=13),("php-fpm",pid=7,fd=12),("php-fpm",pid=1,fd=9))
u_str LISTEN 0 4096 /run/php-fpm-sock.sock 6356826 * 0 users:(("php-fpm",pid=9,fd=15),("php-fpm",pid=1,fd=10))

$ netstat -tlnp                                        (fpm container: master only)
tcp6  0  0 :::9000  :::*  LISTEN  1/php-fpm: master p

$ lsof -nP -iTCP -sTCP:LISTEN                          (apache container)
apache2   1     root  3u IPv4 6363202 0t0 TCP *:80 (LISTEN)
apache2  17 www-data  3u IPv4 6363202 0t0 TCP *:80 (LISTEN)
```

Then, per PID:

```bash
readlink /proc/<pid>/exe                         # exe path (ends in " (deleted)" if replaced on disk)
tr '\0' ' ' < /proc/<pid>/cmdline                # command line (php-fpm rewrites it: "php-fpm: pool www")
awk '{print $6}' /proc/<pid>/maps | grep -iE '/libphp|/php/extensions/' | sort -u   # mod_php, FrankenPHP, extensions
```

```text
apache2 (pid 1)     /usr/lib/apache2/modules/libphp.so  /usr/local/lib/php/extensions/no-debug-non-zts-20240924/opcache.so ...
frankenphp (pid 1)  /usr/local/bin/frankenphp  /usr/local/lib/libphp.so  .../no-debug-zts-20250925/sodium.so
webd (pid 11)       /usr/local/lib/php/extensions/no-debug-non-zts-20250925/sodium.so    <- renamed php, found only by its extension
```

The FrankenPHP Docker image links `libphp.so` dynamically; the standalone
FrankenPHP binaries are static (PHP inside the exe), so only the exe matches.

### No `ss`/`lsof`/`netstat`: `/proc` only

The official `php:*` Debian images ship none of them (only `ps`); Alpine has
busybox `netstat`/`lsof`. This script needs only POSIX `sh`, `awk` and
`readlink`; tested with mawk (Debian 13), busybox (Alpine 3.24) and from the host
namespaces. It walks **every network namespace** (`/proc/<pid>/net/tcp*`), so it
also finds listeners inside containers when run on the host.

```sh
#!/bin/sh
# php_listeners_proc.sh - listening TCP + unix sockets -> PID -> exe -> PHP evidence,
# from /proc only (no ss/lsof/netstat). POSIX sh + awk (busybox, mawk, gawk).
# Reads every network namespace (/proc/<pid>/net/*), so listeners inside
# containers show up too. Run as root (in a container: also CAP_SYS_PTRACE).
# Output (TSV): proto  local_address  pid  mnt(host|ctr)  exe  php_evidence
P=${PROC:-/proc}

# 1. socket inode -> pid ("inode pid"), from every process's fd links
inodes=$(for fd in "$P"/[0-9]*/fd/*; do
  l=$(readlink "$fd" 2>/dev/null) || continue
  case $l in socket:\[*) p=${fd#"$P"/}; i=${l#socket:[}; echo "${i%]} ${p%%/*}";; esac
done | sort -u)

# 2. one pid per network namespace; fall back to our own if ns links are unreadable
nets=$(for d in "$P"/[0-9]*; do
  n=$(readlink "$d/ns/net" 2>/dev/null) && echo "$n ${d#"$P"/}"
done | sort -u -k1,1 | awk '{print $2}')
[ -n "$nets" ] || nets=self

# 3. listening sockets in every netns: "proto local inode"
socks=$(for pid in $nets; do
  awk '
function h2d(h,  i,n,c){n=0;h=toupper(h);for(i=1;i<=length(h);i++){c=index("0123456789ABCDEF",substr(h,i,1))-1;n=n*16+c};return n}
function v4(h){return h2d(substr(h,7,2))"."h2d(substr(h,5,2))"."h2d(substr(h,3,2))"."h2d(substr(h,1,2))}
function v6(h,  w,o,g,s){if(h ~ /^0+$/)return "::";s="";for(w=0;w<4;w++){g=substr(h,w*8+1,8);o=substr(g,7,2)substr(g,5,2)substr(g,3,2)substr(g,1,2);s=s (s==""?"":":") tolower(substr(o,1,4)) ":" tolower(substr(o,5,4))};return s}
FNR==1{next}
FILENAME ~ /tcp6$/ && $4=="0A"{split($2,a,":");print "tcp6 ["v6(a[1])"]:"h2d(a[2]),$10}
FILENAME ~ /tcp$/  && $4=="0A"{split($2,a,":");print "tcp "v4(a[1])":"h2d(a[2]),$10}
FILENAME ~ /unix$/ && $4=="00010000"{print "unix",($8==""?"@anon":$8),$7}
' "$P/$pid/net/tcp" "$P/$pid/net/tcp6" "$P/$pid/net/unix" 2>/dev/null
done | sort -u)

hostmnt=$(readlink "$P/1/ns/mnt" 2>/dev/null)

# 4. join on inode, then describe each owning pid
echo "$socks" | while read -r proto addr inode; do
  [ -n "$inode" ] || continue
  echo "$inodes" | awk -v i="$inode" '$1==i{print $2}' | while read -r pid; do
    exe=$(readlink "$P/$pid/exe" 2>/dev/null || echo "?")
    mnt=host; [ "$(readlink "$P/$pid/ns/mnt" 2>/dev/null)" = "$hostmnt" ] || mnt=ctr
    ev=$(awk '{print $6}' "$P/$pid/maps" 2>/dev/null |
         grep -iE '/libphp[^/]*\.so|/php/extensions/|/(php|php-fpm|php-cgi|frankenphp)[0-9.]*( \(deleted\))?$' |
         sort -u | tr '\n' ' ')
    case ${exe##*/} in php*|*php) ev="exe ${ev}";; esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$proto" "$addr" "$pid" "$mnt" "$exe" "${ev:--}"
  done
done
```

Run from the Docker VM's host namespaces (all five containers; one line per PID
per socket, trimmed):

```text
tcp   0.0.0.0:80               69423  ctr  /usr/sbin/apache2           /usr/lib/apache2/modules/libphp.so ...
tcp   0.0.0.0:8080             69293  ctr  /usr/local/bin/php          exe /usr/local/bin/php ...
tcp   0.0.0.0:8082             69296  ctr  /usr/local/bin/webd         /usr/local/lib/php/extensions/no-debug-non-zts-20250925/sodium.so
tcp   127.0.0.1:9001           69295  ctr  /usr/local/bin/php-cgi      exe /usr/local/bin/php-cgi ...
tcp6  [::]:443                 67506  ctr  /usr/local/bin/frankenphp   exe /usr/local/bin/frankenphp /usr/local/lib/libphp.so ...
tcp6  [::]:9000                69328  ctr  /usr/local/sbin/php-fpm     exe ... /usr/local/sbin/php-fpm
unix  /run/php-fpm-sock.sock   69343  ctr  /usr/local/sbin/php-fpm     exe ... /usr/local/sbin/php-fpm
```

### Exact version of what is running

YARA-scan the running image through `/proc`, so the path doesn't have to exist in
your mount namespace and a replaced binary still scans as the old one:

```bash
yara -s php_detect.yar /proc/<pid>/exe | awk -f php_versions.awk
yara -s php_detect.yar /proc/<pid>/root/usr/lib/apache2/modules/libphp.so | awk -f php_versions.awk   # path from maps
```

Tested from the host namespaces against every listener above: `php`, `webd`,
`php-cgi`, FrankenPHP → 8.5.12; php-fpm → 8.4.27 and 8.3.36; Apache: `apache2`
exe → no match, mapped `libphp.so` → 8.4.27.

**Upgraded but not restarted.** In a test the `php` binary was replaced on disk
while `php -S` kept running: `/proc/<pid>/exe` read `/usr/local/bin/php (deleted)`
and scanned as 8.5.12, while the new file at the same path scanned as the new
version. A path join against an on-disk YARA list reports the **new** version for
an **old** process here; flag `(deleted)` exes, or scan `/proc/<pid>/exe`.

### Privileges and caveats (Linux)

- **Root needed** to map sockets to processes of other users: as `www-data` the
  `/proc` script returned nothing (php-fpm and Apache workers are non-dumpable,
  so their `/proc/<pid>/fd` is root-only). `/proc/net/tcp` (ports, no owner) is
  world-readable.
- **Inside a container, root also needs `CAP_SYS_PTRACE`** (not in Docker's default
  set) to read other UIDs' `/proc/<pid>/fd` and `exe`: without it, only PID 1's
  sockets were found.
- **Containers vs host:** host `ss`/`netstat`/`/proc/net/tcp` do **not** show
  listeners in container network namespaces (tested: nothing from the five
  containers). The processes are visible in host `ps`. Use per-PID
  `/proc/<pid>/net/tcp*` (the script above) or `nsenter -t <pid> -n ss -ltnp`.
  Published ports (`-p 8080:80`) show up on the host as `dockerd`/`docker-proxy`,
  not PHP. Exe paths are container-internal; reach the file via
  `/proc/<pid>/root/<path>`.
- **netstat -p shows one PID per socket** (php-fpm master); `ss -p` and `lsof`
  show every holder.
- **Emulated binaries:** amd64 containers on Apple Silicon (Rosetta) report
  `/proc/<pid>/exe` = `/run/rosetta/rosetta` and `netstat` program `rosetta`; `ss`
  and `lsof` still show `php` (from `comm`). Likely the same for qemu-user
  binfmt (not tested). Native hosts are not affected.

## macOS

Tested on an Apple Silicon Mac (macOS 14.6, non-root; `sudo` not available) with
the FrankenPHP 8.5.11 macOS binary (static PHP): `frankenphp php-server` on
`127.0.0.1:18083`, `frankenphp php-cli srv.php` (a `stream_socket_server` loop) on
`:18081`, and a renamed copy `webd php-server` on `:18082`. Formats were checked
read-only on an Intel Mac (macOS 15.7, with `sudo`).

The conda-forge PHP 8.5.9 build could not be started: it needs ~12 dylibs from
other conda packages (ICU, libpq, libxml2, ...), which were not installed. So
`php -S`, `php-cgi`, php-fpm and mod_php were **not tested on macOS**; the
commands are the same as for FrankenPHP.

### Commands

```bash
netstat -anv -p tcp | awk '$6=="LISTEN"'   # every user's PID, no root needed
lsof -nP -iTCP -sTCP:LISTEN                # own processes only, unless root
lsof +c0 -nP -iTCP -sTCP:LISTEN            # full command names (default truncates to 9 chars)
ps -o comm= -p <pid>                       # full exe path, any user, no root needed
lsof -nP -a -p <pid> -d txt                # exe + loaded non-shared-cache images (libphp.so would be here); root for other users
vmmap <pid>                                # also lists images; root for other users
```

```text
$ lsof -nP -iTCP -sTCP:LISTEN
frankenph 49908 <user>  6u IPv4 0xa4968d88690d7433 0t0 TCP 127.0.0.1:18081 (LISTEN)
webd      49909 <user>  8u IPv4 0x19b38d04b9c51d60 0t0 TCP 127.0.0.1:18082 (LISTEN)
frankenph 49966 <user>  8u IPv4 0x8d0bddc825443101 0t0 TCP 127.0.0.1:18083 (LISTEN)

$ netstat -anv -p tcp            (macOS 14: pid is field 9)
Proto Recv-Q Send-Q  Local Address    Foreign Address  (state)  rhiwat  shiwat    pid   epid ...
tcp4       0      0  127.0.0.1.18083  *.*              LISTEN   131072  131072  49966      0 ...
```

**`netstat -anv` columns differ by release:** macOS 15 adds `rxbytes txbytes`
before `rhiwat`, so the PID is field 11 there and field 9 on macOS 14. Find the
column from the header. The header has two two-word names (`Local Address`,
`Foreign Address`), so the data field is the header index minus 2:

```sh
#!/bin/sh
# php_listeners_macos.sh - listening TCP sockets -> PID -> exe -> PHP evidence (macOS).
# netstat -anv shows every user's PIDs without root; lsof (loaded images) needs root for other users.
# Output (TSV): local_address  pid  exe  php_evidence
netstat -anv -p tcp | awk '
  /^Proto/ { for (i = 1; i <= NF; i++) if ($i == "pid") c = i - 2; next }   # header has 2 two-word columns
  $6 == "LISTEN" && c { print $4, $c }' | sort -u |
while read -r addr pid; do
  exe=$(ps -o comm= -p "$pid" 2>/dev/null)
  ev=$(lsof -nP -a -p "$pid" -d txt -Fn 2>/dev/null | sed -n 's/^n//p' |
       grep -iE '/libphp[^/]*\.so|/php/extensions/|/(php|php-fpm|php-cgi|frankenphp)[0-9.]*$' | sort -u | tr '\n' ' ')
  case ${exe##*/} in php*|*php) ev="exe ${ev}";; esac
  printf '%s\t%s\t%s\t%s\n' "$addr" "$pid" "${exe:-?}" "${ev:--}"
done
```

```text
*.22              1      /sbin/launchd                  -
127.0.0.1.18082   54048  <testdir>/webd                 -          <- renamed: only the YARA join finds it
127.0.0.1.18083   53745  <testdir>/frankenphp           exe <testdir>/frankenphp
```

Tested on both Macs (macOS 14 non-root, macOS 15 as root).

### Privileges and caveats (macOS)

- `netstat -anv` PIDs and `ps -o comm=` exe paths work for every user's process
  **without root** (tested macOS 14). `lsof` without root lists only your own
  sockets (the macOS 15 Mac returned 0 lines as a normal user, all of them with
  `sudo`), and loaded-image listing for other users' processes needs root.
- `lsof -d txt` lists the exe and loaded images that aren't in the dyld shared
  cache (seen: `/usr/lib/libobjc-trampolines.dylib`). A Homebrew `libphp.so`
  loaded into `httpd` should appear there; **not tested** (no mod_php build).
- Static PHP (FrankenPHP standalone) has no PHP library to find; only the exe
  path (YARA join) or the name identifies it.

## Windows

Tested on Windows Server 2022 (10.0.20348, Windows PowerShell 5.1, elevated
over SSH) with the windows.php.net zips. The 8.5.11 build would not start (its
VC++ runtime 14.44 is newer than the host's 14.36, and nothing was installed), so
these ran:

| Port | Process | Build |
|---|---|---|
| 127.0.0.1:18080 | `php.exe -S` | 8.2.34 NTS |
| 127.0.0.1:18081 | `php.exe srv.php` (`stream_socket_server` loop) | 7.4.33 TS |
| 0.0.0.0:18082 | `webd.exe -S` (copy of `php.exe`) | 8.2.34 NTS |
| 127.0.0.1:19000 | `php-cgi.exe -b` | 8.2.34 NTS |
| 127.0.0.1:18084 | `powershell.exe` with `php7ts.dll` loaded (`LoadLibrary`) and a `TcpListener` | 7.4.33 TS — **simulates** `httpd.exe` + `php7apache2_4.dll` |

No Apache and no IIS on the host (`Web-Server` feature: Available, not
installed), so real mod_php on Windows and IIS FastCGI were **not tested**.

### Commands

```powershell
# Listening ports -> process -> exe -> PHP evidence -> version (elevated)
$procs = @{}; Get-CimInstance Win32_Process | ForEach-Object { $procs[[int]$_.ProcessId] = $_ }
$phpDll = '^(php\d*(ts)?\.dll|php\d*apache2_4\.dll)$'
Get-NetTCPConnection -State Listen | Sort-Object LocalAddress, LocalPort -Unique | ForEach-Object {
    $p = $procs[[int]$_.OwningProcess]; $exe = $p.ExecutablePath; $ev = @(); $ver = $null
    if ($exe -and (Test-Path -LiteralPath $exe)) {
        $vi = (Get-Item -LiteralPath $exe).VersionInfo
        if ($vi.ProductName -eq 'PHP') { $ev += 'exe'; $ver = $vi.ProductVersion }
    }
    try {
        foreach ($m in (Get-Process -Id $_.OwningProcess -ErrorAction Stop).Modules | Where-Object { $_.ModuleName -match $phpDll }) {
            $ev += $m.FileName; if (-not $ver) { $ver = $m.FileVersionInfo.ProductVersion }
        }
    } catch { }
    if ($ev) {
        [pscustomobject]@{ Address = "$($_.LocalAddress):$($_.LocalPort)"; PID = $_.OwningProcess; Name = $p.Name
            Exe = $exe; PHP = $ev -join '; '; Version = $ver; Parent = $p.ParentProcessId; CommandLine = $p.CommandLine }
    }
}
```

```text
Address          PID Name           Version
-------          --- ----           -------
127.0.0.1:18080 9836 php.exe        8.2.34
127.0.0.1:18081  652 php.exe        7.4.33
0.0.0.0:18082   2396 webd.exe       8.2.34     <- renamed; PE ProductName is still "PHP"
127.0.0.1:18084 7044 powershell.exe 7.4.33     <- not PHP by name or exe; php7ts.dll loaded
127.0.0.1:19000 6572 php-cgi.exe    8.2.34
```

`PHP` column (same run): `exe; ...\php-8.2.34-nts-Win32-vs16-x64\php8.dll` for
the PHP exes, and only `...\php-7.4.33-Win32-vc15-x64\php7ts.dll` for
`powershell.exe`. The table came from an earlier draft of the snippet with the
same logic; the snippet as printed was then run on its own against a renamed
`webd.exe -S` and returned `127.0.0.1:18082  webd.exe  8.2.34  exe; ...\php8.dll`.

Older tools give the same data:

```bat
netstat -ano | findstr LISTENING          :: PID per port
netstat -abno                             :: + image name, needs elevation
tasklist /m php7ts.dll                    :: which processes have a PHP DLL loaded
tasklist /m php8.dll
netsh http show servicestate              :: http.sys (IIS, WinRM) URL registrations and their request-queue PIDs
```

```text
> tasklist /m php7ts.dll
php.exe                        652 php7ts.dll
powershell.exe                7044 php7ts.dll
> tasklist /m php8.dll
php.exe                       9836 php8.dll
php-cgi.exe                   6572 php8.dll
webd.exe                      2396 php8.dll
> netstat -abno
  TCP    0.0.0.0:18082          0.0.0.0:0              LISTENING       2396
 [webd.exe]
```

### IIS / http.sys (not tested; no IIS on the test host)

With IIS the web port is opened by the kernel (`http.sys`) and shows as PID 4
`System` (seen on the host for WinRM `:5985`, `:47001` and `:5357`, both in
`Get-NetTCPConnection` and in relevance). With IIS FastCGI, `php-cgi.exe` runs as
children of `w3wp.exe` and does not listen on TCP itself. So:

1. `netsh http show servicestate` → registered URLs and the request-queue
   process IDs (the `w3wp.exe` worker per app pool).
2. `php-cgi.exe` processes whose parent is `w3wp.exe`
   (`Win32_Process.ParentProcessId`) → exe path → PE version.
3. Configured but idle handlers: `<fastCgi><application fullPath="...php-cgi.exe">`
   in `%windir%\System32\inetsrv\config\applicationHost.config`.

### Privileges and caveats (Windows)

- Only elevated sessions were tested (the SSH logon is elevated; `runas /trustlevel`
  does nothing over SSH). `netstat -b` itself says it fails without sufficient
  permissions. Expect `Win32_Process.ExecutablePath`/`CommandLine` and
  `Get-Process -Module` to be empty or access-denied for other users' and
  service processes when not elevated: **not tested**.
- `Get-Process -Module` from 64-bit PowerShell lists modules of 64-bit processes;
  for a 32-bit `httpd.exe` use `tasklist /m` (not tested).
- Server vs client: `Get-NetTCPConnection` and `Get-CimInstance` exist on both;
  the PowerShell commands were only run on Server 2022. On the Windows 11
  endpoint only the relevance below was run.
- Windows containers: not tested.

## BigFix client relevance

Inspectors found with `uvx bigfix-relevance-analyzer --dialect client --search`
and the analyzer's inspector tables; every statement below passed
`uvx bigfix-relevance-analyzer --dialect client` and was evaluated with
`uvx bigfix-remote-client-relevance`.

| Inspector | Windows | macOS | Linux |
|---|---|---|---|
| `sockets of network`, `local address`/`local port`/`tcp`/`udp`/`tcp state of <socket>`, `listening of <tcp state>`, `process of <socket>` | ✓ | ✓ | ✓ (agent's own network namespace only) |
| `name`, `pid`, `ppid`, `image file of <process>` | ✓ | ✓ | ✓ (`image file` only if the path exists in the agent's mount namespace) |
| `command line arguments of <process>` | ✗ "not defined" | ✗ "not defined" | ✓ |
| loaded modules of a process | ✗ none | ✗ none | read `/proc/<pid>/maps` as a file ✓ |
| unix sockets | — | ✗ (`socket files` "not defined") | `/proc/net/unix` as a file ✓, `socket files of folder` ✓ |
| `version block` (`ProductName`, `ProductVersion`) | ✓ | ✗ | ✗ |

`process of <socket>` returns one PID per socket (for php-fpm and Apache, one
worker). System (PID 4) and some protected processes have no `image file`;
guard with `| "?"` or `exists image files of ...`.

Where it ran:

| Target | Agent / qna | Notes |
|---|---|---|
| This Mac, macOS 14.6 arm64 (`--local`) | 11.0.6.137 | FrankenPHP listeners |
| Intel Mac, macOS 15.7 (SSH) | 11.0.7.61 | read-only; no PHP |
| Windows Server 2022 (SSH) | 11.0.7.61 | PHP listeners above |
| Windows 11 endpoint (Fast Query) | 11.0.5.203 | read-only; no PHP |
| Linux containers: Debian 12, Ubuntu 24.04/26.04, Rocky 9, UBI 9, Amazon Linux 2023, openSUSE Leap 15 (arm64 + x86_64) | 11.0.7.61 | no PHP; statements evaluate without error |
| qna from the Ubuntu arm64 image, run **inside** / **beside** the PHP test containers | 11.0.7.61 | Linux PHP listeners above |

### 1. All listening TCP ports with owning process (all platforms)

```relevance
(local address of it as string & ":" & local port of it as string & " pid=" & (pid of process of it as string | "?") & " name=" & (name of process of it | "?") & " path=" & (pathname of image file of process of it | "?")) of sockets whose (tcp of it and listening of tcp state of it) of network
```

```text
macOS (this Mac):      127.0.0.1:18083 pid=49966 name=frankenphp path=<testdir>/frankenphp
                       127.0.0.1:18082 pid=49909 name=webd path=<testdir>/webd
Windows Server 2022:   445 pid=4 name=System path=?      22 pid=2128 name=sshd.exe path=C:\Windows\System32\OpenSSH\sshd.exe
Linux (inside cli):    0.0.0.0:8082 pid=11 name=webd path=/usr/local/bin/webd
Linux (inside apache): 0.0.0.0:80 pid=1 name=apache2 path=/usr/sbin/apache2
Linux (beside cli):    0.0.0.0:8080 pid=8 name=php path=?        <- exe path not in qna's own filesystem
```

IPv6 sockets print as `0:0:0:0:0:0:0:0:9000`. Expect duplicate lines (IPv4 +
IPv6, or several sockets on one port); wrap in `unique values of` as in 2.

### 2. Listeners whose process looks like PHP by name (all platforms)

```relevance
unique values of (local address of it as string & ":" & local port of it as string & " pid=" & pid of process of it as string & " " & (pathname of image file of process of it | name of process of it)) of sockets whose (tcp of it and listening of tcp state of it and exists (processes of it) whose (name of it as lowercase contains "php" or exists image files whose (name of it as lowercase contains "php") of it)) of network
```

```text
macOS:    127.0.0.1:18081 pid=49908 <testdir>/frankenphp
          127.0.0.1:18083 pid=49966 <testdir>/frankenphp
Windows:  127.0.0.1:18080 pid=9836 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php.exe
          127.0.0.1:18081 pid=652  C:\phprun\php-7.4.33-Win32-vc15-x64\php.exe
          127.0.0.1:19000 pid=6572 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php-cgi.exe
```

Misses the renamed `webd` and the DLL host, as expected. Cheap; good for a quick
"anything PHP-ish listening?" property.

### 3. Listening port → PHP version, joined to the YARA results (all platforms)

Joins each listener's exe path to `path<TAB>version` lines in
`__BESData/__Global/Logs/yara_results_php.text` (written by the existing YARA
tasks). `%09` is a tab.

```relevance
unique values of (item 0 of it & " " & item 1 of it & " version=" & following text of first "%09" of item 2 of it) of ((local port of it as string, pathnames of image files of processes of it, lines of files whose (name of it as lowercase starts with "yara_results_php.text") of folders "Logs" of folders "__Global" of data folders of client) of sockets whose (tcp of it and listening of tcp state of it and exists image files of processes of it) of network) whose (item 2 of it as lowercase starts with (item 1 of it as lowercase & "%09"))
```

Tested with the results file path replaced by the file each OS's scan script
produced over the test binaries:

```text
macOS:    18081 <testdir>/frankenphp version=8.5.11
          18082 <testdir>/webd version=8.5.11              <- renamed binary, found via YARA
          18083 <testdir>/frankenphp version=8.5.11
Windows:  18080 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php.exe version=8.2.34
          18081 C:\phprun\php-7.4.33-Win32-vc15-x64\php.exe version=7.4.33
          18082 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\webd.exe version=8.2.34
          19000 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php-cgi.exe version=8.2.34
Linux:    8080 /usr/local/bin/php version=8.5.12          (qna inside the cli container)
          8082 /usr/local/bin/webd version=8.5.12
          9001 /usr/local/bin/php-cgi version=8.5.12
```

With the real `data folders of client` path it returned no answers on the macOS
15 Mac and the Windows 11 endpoint, whose results files exist with 0 lines (no
PHP), and on every other target (no results file). Misses mod_php / DLL hosts
(exe is the web server) on every platform; on Linux use 5 instead.

Running but not listening (cron jobs, queue workers, php-fpm without TCP):

```relevance
unique values of (item 0 of it as string & " " & item 1 of it & " version=" & following text of first "%09" of item 2 of it) of ((pid of it, pathnames of image files of it, lines of files whose (name of it as lowercase starts with "yara_results_php.text") of folders "Logs" of folders "__Global" of data folders of client) of processes) whose (item 2 of it as lowercase starts with (item 1 of it as lowercase & "%09"))
```

Evaluated on all targets without error (no answers: no PHP running where a
results file exists). Cost grows with processes × result lines; keep it in an
analysis, not in fixlet applicability.

### 4. Windows: version straight from the PE resource (no YARA needed)

```relevance
unique values of (local address of it as string & ":" & local port of it as string & " pid=" & pid of process of it as string & " " & pathname of image file of process of it & " ProductVersion=" & (value "ProductVersion" of version block 1 of image file of process of it as string)) of sockets whose (tcp of it and listening of tcp state of it and exists image files whose (value "ProductName" of version block 1 of it as string = "PHP") of processes of it) of network
```

```text
0.0.0.0:18082 pid=2396 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\webd.exe ProductVersion=8.2.34
127.0.0.1:18080 pid=9836 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php.exe ProductVersion=8.2.34
127.0.0.1:18081 pid=652 C:\phprun\php-7.4.33-Win32-vc15-x64\php.exe ProductVersion=7.4.33
127.0.0.1:19000 pid=6572 C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php-cgi.exe ProductVersion=8.2.34
```

Catches renamed `php.exe`. Windows 11: no answers, no error. Other platforms:
`The operator "version block" is not defined`, so keep it in a Windows-only
property (or behind `if windows of operating system`). Misses the DLL host
(`powershell.exe` / `httpd.exe`): relevance has no loaded-module list on Windows.

### 5. Linux: mod_php and everything else via `/proc/<pid>/maps`

Client relevance reads `/proc` files as ordinary files. Joining every mapped file
of each listener to the YARA results catches mod_php, FrankenPHP and renamed
binaries:

```relevance
unique values of (item 0 of it & " pid=" & item 1 of it & " " & item 2 of it & " version=" & following text of first "%09" of item 3 of it) of ((local port of it as string, pid of process of it as string, unique values of ("/" & following text of first "/" of it) of lines whose (it contains "/") of file ("/proc/" & pid of process of it as string & "/maps"), lines of files whose (name of it as lowercase starts with "yara_results_php.text") of folders "Logs" of folders "__Global" of data folders of client) of sockets whose (tcp of it and listening of tcp state of it) of network) whose (item 3 of it starts with (item 2 of it & "%09"))
```

```text
apache:  80 pid=1 /usr/lib/apache2/modules/libphp.so version=8.4.27        (24 ms)
         80 pid=1 /usr/local/lib/php/extensions/no-debug-non-zts-20240924/opcache.so version=unknown
cli:     8082 pid=11 /usr/local/bin/webd version=8.5.12
         8082 pid=11 /usr/local/lib/php/extensions/no-debug-non-zts-20250925/sodium.so version=unknown
```

Extensions come back as `unknown` (no version string; see README); filter them
with `whose (item 3 of it does not end with "%09unknown")` if unwanted.

Without a results file, just the evidence:

```relevance
(pid of process of it as string & " " & local port of it as string & " " & (concatenation ";" of unique values of ("/" & following text of first "/" of it) of lines whose (it as lowercase contains "php") of file ("/proc/" & (pid of process of it as string) & "/maps"))) of sockets whose (tcp of it and listening of tcp state of it) of network
```

```text
21 80 /usr/lib/apache2/modules/libphp.so;/usr/local/lib/php/extensions/no-debug-non-zts-20240924/opcache.so;...
```

### 6. Linux: listeners inside containers, from the host agent

`sockets of network` sees only the agent's own network namespace: from the
Docker VM host it listed `dockerd`, `rpcbind` and `rpc.statd`, **none** of the
container listeners. `processes` does see container processes, and each
process's `/proc/<pid>/net/tcp*` is its namespace's socket table:

```relevance
(pid of it as string & " " & name of it & " ports=" & concatenation "," of unique values of (hexadecimal integer (following text of first ":" of preceding text of first " " of following text of first ": " of it) as string) of lines whose (it contains " 0A ") of files ("/proc/" & pid of it as string & "/net/tcp"; "/proc/" & pid of it as string & "/net/tcp6")) of processes whose (name of it as lowercase contains "php")
```

```text
67506 frankenphp ports=2019,443,80
69293 php ports=8080,8081,8082,9001
69328 php-fpm ports=9000
```

Caveats: the ports are those listening **in that process's namespace**, not
necessarily owned by that process (all four processes in the cli container
report all four ports). ` 0A ` (LISTEN state) is a text match. From the host,
`image file of <process>` fails for container processes (the path isn't in the
host filesystem; `/proc/<pid>/root/<path>` exists) and `command line arguments`
works.

Linux extras that were tested:

```relevance
(pid of it as string & " " & name of it & " | " & concatenation " " of command line arguments of it) of processes whose (name of it as lowercase contains "php")
```

```text
69293 php | -S 0.0.0.0:8080 -t /tmp
69295 php-cgi | -b 127.0.0.1:9001
69328 php-fpm |                          <- php-fpm rewrites its argv ("php-fpm: pool www")
```

```relevance
(following text of last " " of it) of lines whose (it contains " 00010000 " and it as lowercase contains "php") of file "/proc/net/unix"
```

```text
/run/php-fpm-sock.sock
```

`(pathname of it) of socket files of folders ("/run"; "/run/php"; "/var/run/php")`
also returned `/run/php-fpm-sock.sock`. Nothing in relevance maps a unix socket
to its PID (that needs the `/proc/<pid>/fd` link targets); pair it with
`processes whose (name of it = "php-fpm")`.

### 7. One statement for all platforms: running and listening PHP, best effort

One statement that runs unchanged on Windows, macOS and Linux. It lists every
listening socket (`address:port`) and every process (`running`) that looks like
PHP, with an `evidence=` list saying why, so likely positives show even
without a YARA scan. When `yara_results_php.text` is present it adds `yara`
evidence (finds renamed binaries) and fills in `version=`. Output per line:

```text
<address:port | running> pid=<pid> name=<name> path=<exe> evidence=<list> version=<versions> libphp=<mapped libphp paths>
```

| Evidence | Meaning | Platforms | Strength |
|---|---|---|---|
| `name` | process name contains `php` (`php`, `php-fpm`, `php-cgi`, `frankenphp`) | all | strong |
| `path` | exe path contains `php` (e.g. `C:\php\`, `/opt/remi/php82/`) | all | weak alone |
| `pe` | exe's version resource has `ProductName` = `PHP` (also gives `version=`) | Windows | confirmed |
| `libphp` | `libphp*.so` mapped (mod_php, FrankenPHP); paths in `libphp=` | Linux | confirmed |
| `php-ext` | a `/php/extensions/` module mapped (renamed `php`) | Linux | strong |
| `yara` | exe path is in `yara_results_php.text` (also gives `version=`) | all | confirmed |
| `httpd-conf` | `httpd`/`apache*` with `LoadModule php` in `../conf/*.conf` or `../conf/extra/*.conf` (Windows/XAMPP-style layout) | all | likely |
| `webserver-modules-unknown` | `httpd`/`apache*` whose loaded modules can't be read (Windows, macOS, or an unreadable Linux process) | all | possible |

`version=` comes from the Windows PE resource, the YARA line for the exe, or (Linux)
the YARA line for any mapped file such as `libphp.so`; `unknown` lines (extensions)
are skipped.

Generated by [`gen_running_php_relevance.py`](gen_running_php_relevance.py); edit
the pieces there, not this one-liner. Pass a results-file path to test against a
file other than `__BESData/__Global/Logs/yara_results_php.text`:

```bash
python3 gen_running_php_relevance.py > running_php.rel
python3 gen_running_php_relevance.py /tmp/yara_results_php.text > running_php_test.rel
```

```relevance
unique values of (item 1 of it & " pid=" & (pid of item 2 of it as string) & " name=" & (name of item 2 of it | "") & " path=" & (pathname of image file of item 2 of it | "?") & " evidence=" & item 3 of it & " version=" & concatenation "," of unique values of (((if (windows of operating system) then concatenation "," of (value "ProductVersion" of version block 1 of it as string) of image files whose (value "ProductName" of version block 1 of it as string = "PHP") of item 2 of it else "") ; (following text of first "%09" of item 1 of it) of ((it as lowercase) of pathnames of image files of item 2 of it, substrings separated by "%0a" of item 0 of it) whose (item 1 of it starts with (item 0 of it & "%09")) ; (following text of first "%09" of item 1 of it) of (unique values of (("/" & following text of first "/" of it) as lowercase) of lines whose (it contains "/") of files ("/proc/" & (pid of item 2 of it as string) & "/maps") whose (exists folder (pathname of parent folder of it & "/root")), substrings separated by "%0a" of item 0 of it) whose (item 1 of it starts with (item 0 of it & "%09"))) whose (it != "" and it != "unknown")) & " libphp=" & concatenation ";" of unique values of ("/" & following text of first "/" of it) of lines whose (it as lowercase contains "/libphp") of files ("/proc/" & (pid of item 2 of it as string) & "/maps") whose (exists folder (pathname of parent folder of it & "/root"))) of ((item 0 of it, item 1 of it, item 2 of it, concatenation "," of ((if ((name of item 2 of it | "") as lowercase contains "php") then "name" else "") ; (if (exists pathnames whose (it as lowercase contains "php") of image files of item 2 of it) then "path" else "") ; (if (windows of operating system) then (if (exists image files whose (value "ProductName" of version block 1 of it as string = "PHP") of item 2 of it) then "pe" else "") else "") ; (if (exists lines whose (it as lowercase contains "/libphp") of files ("/proc/" & (pid of item 2 of it as string) & "/maps") whose (exists folder (pathname of parent folder of it & "/root"))) then "libphp" else "") ; (if (exists lines whose (it as lowercase contains "/php/extensions/") of files ("/proc/" & (pid of item 2 of it as string) & "/maps") whose (exists folder (pathname of parent folder of it & "/root"))) then "php-ext" else "") ; (if (exists (item 0 of it, (it as lowercase) of pathnames of image files of item 2 of it) whose (item 0 of it contains ("%0a" & item 1 of it & "%09"))) then "yara" else "") ; (if ((name of item 2 of it | "") as lowercase starts with "httpd" or (name of item 2 of it | "") as lowercase starts with "apache") then (if (exists lines whose (it as lowercase contains "loadmodule php") of files whose (name of it as lowercase ends with ".conf") of (folders "conf" of it; folders "extra" of folders "conf" of it) of parent folders of parent folders of image files of item 2 of it) then "httpd-conf" else "") else "") ; (if (((name of item 2 of it | "") as lowercase starts with "httpd" or (name of item 2 of it | "") as lowercase starts with "apache") and not exists files ("/proc/" & (pid of item 2 of it as string) & "/maps") whose (exists folder (pathname of parent folder of it & "/root"))) then "webserver-modules-unknown" else "")) whose (it != "")) of ((item 0 of it, item 0 of item 1 of it, item 1 of item 1 of it) of (("%0a" & concatenation "%0a" of (it as string as lowercase) of lines of files whose (name of it as lowercase starts with "yara_results_php.text") of folders "Logs" of folders "__Global" of data folders of client & "%0a"), ((local address of it as string & ":" & local port of it as string, processes of it) of sockets whose (tcp of it and listening of tcp state of it) of network ; ("running", it) of processes)))) whose (item 3 of it != "")
```

How it holds up across platforms:

- Windows-only `version block` sits in untaken `if (windows of operating system)`
  branches, so macOS and Linux never see it.
- `/proc/<pid>/maps` is read only when `/proc/<pid>/root` resolves, which needs the
  same ptrace access. An unreadable `maps` is a fatal "File error … Permission
  denied" for the whole expression, which `exists` and `|` don't absorb (seen on
  a non-root evaluator and as root in a container without `CAP_SYS_PTRACE`).
- `name` and `process of <socket>` are guarded or plural: some Windows processes
  have no name, and some sockets have no owning process.
- In `first (X) of Y`, an `it` inside `X` is rebound to `Y` (the analyzer's
  `--verbose` "it bindings" shows this). The version lookup therefore splits the
  results into lines (`substrings separated by "%0a"`) and matches with `starts
  with`.
- It is long (analyzer complexity ~1,440; the default lint ceiling is 550, so lint it with `--max-score 2000`) and
  reads `/proc/<pid>/maps` for every Linux process. Keep it in an analysis
  property, not fixlet applicability.

Tested results (results-file path swapped for the test file where "with YARA"):

```text
Windows Server 2022, no YARA results
0.0.0.0:18082 pid=3880 name=webd.exe path=C:\phprun\php-8.2.34-nts-Win32-vs16-x64\webd.exe evidence=path,pe version=8.2.34 libphp=
127.0.0.1:18080 pid=8260 name=php.exe path=C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php.exe evidence=name,path,pe version=8.2.34 libphp=
127.0.0.1:18084 pid=6920 name=httpd.exe path=C:\phprun\apache\bin\httpd.exe evidence=path,httpd-conf,webserver-modules-unknown version= libphp=
127.0.0.1:19000 pid=3788 name=php-cgi.exe path=C:\phprun\php-8.2.34-nts-Win32-vs16-x64\php-cgi.exe evidence=name,path,pe version=8.2.34 libphp=
running pid=9140 name=php.exe path=C:\phprun\php-7.4.33-Win32-vc15-x64\php.exe evidence=name,path,pe version=7.4.33 libphp=
Windows, with YARA: same lines, evidence gains ",yara"

macOS 14, no YARA results
127.0.0.1:18083 pid=60782 name=frankenphp path=<testdir>/frankenphp evidence=name,path version= libphp=
running pid=60870 name=httpd path=<testdir>/apache/bin/httpd evidence=httpd-conf,webserver-modules-unknown version= libphp=
macOS 14, with YARA
127.0.0.1:18082 pid=60783 name=webd path=<testdir>/webd evidence=yara version=8.5.11 libphp=
127.0.0.1:18083 pid=60782 name=frankenphp path=<testdir>/frankenphp evidence=name,path,yara version=8.5.11 libphp=

Linux (qna as root inside php:8.5-cli / php:8.4-apache), no YARA results
0.0.0.0:8082 pid=9 name=webd path=/usr/local/bin/webd evidence=php-ext version= libphp=
127.0.0.1:9001 pid=10 name=php-cgi path=/usr/local/bin/php-cgi evidence=name,path,php-ext version= libphp=
0.0.0.0:80 pid=22 name=apache2 path=/usr/sbin/apache2 evidence=libphp,php-ext version= libphp=/usr/lib/apache2/modules/libphp.so
Linux, with YARA
0.0.0.0:8082 pid=9 name=webd path=/usr/local/bin/webd evidence=php-ext,yara version=8.5.12 libphp=
0.0.0.0:80 pid=22 name=apache2 path=/usr/sbin/apache2 evidence=libphp,php-ext version=8.4.27 libphp=/usr/lib/apache2/modules/libphp.so
Linux, root without CAP_SYS_PTRACE (Apache workers unreadable)
running pid=18 name=apache2 path=? evidence=webserver-modules-unknown version= libphp=
```

Also evaluated with the real results-file path on every inventory target
(macOS 14/15, Windows Server 2022, Windows 11 via Fast Query, the RHEL online
evaluator as non-root, and 9 Linux container images) with no errors; where no PHP
was running it returned no answers.

Test notes: the Windows test folder was named `phprun`, so every exe there also got
`path`. The Windows `httpd.exe` was a renamed `powershell.exe` with `php7ts.dll`
loaded and a `conf\httpd.conf` containing `LoadModule php_module`. The macOS
`httpd` was a renamed FrankenPHP running `sleep()`, so a real Apache with PHP
on Windows or macOS is still untested. A plain Apache without PHP would also
show as `webserver-modules-unknown` on Windows and macOS.

### Gaps and fallback

| Gap | Platforms | Fallback |
|---|---|---|
| No loaded-module list for a process (mod_php in `httpd`, `php*apache2_4.dll`, DLL hosts) | Windows, macOS | Script: `Get-Process -Module` / `tasklist /m` (Windows), `lsof -d txt` as root (macOS). Config hints (not tested): `LoadModule php_module` in `httpd.conf`, IIS `applicationHost.config` `<fastCgi>`. |
| No command line | Windows, macOS | Script: `Win32_Process.CommandLine`, `ps -o args=`. |
| No unix sockets | macOS | Script: `lsof -U`. |
| Other network namespaces (containers) | Linux | `/proc/<pid>/net/tcp*` as in 6, or the `/proc` script. |
| `image file` of container processes | Linux, from host | `/proc/<pid>/maps` lines (first mapped path is the exe), or `/proc/<pid>/root/...`. |
| Version of what's *running* vs on disk (upgrade without restart) | all | Script: YARA on `/proc/<pid>/exe` (Linux); on Windows/macOS compare process start time with the file's modification time (not tested). |
| One PID per socket | all | Fine for "is PHP serving this port"; scripts list every holder. |

The fallback is the same pattern as the YARA tasks: a script writes a results file
under `__BESData/__Global/Logs/`, and an analysis reads it.

## Matching listeners to the YARA install list

Goal: `port → PHP version`. The YARA list is `path<TAB>version`, one line per
PHP file. For each listener, collect the **exe path** and every **loaded PHP
library path** (`libphp*.so`, `php*ts.dll`, `php8.dll`, `php*apache2_4.dll`), and
look each up in the list.

| Listener evidence | Join key | Notes |
|---|---|---|
| exe is PHP (`php`, `php-fpm`, `php-cgi`, `frankenphp`, renamed) | exe path | Windows: `php.exe` also has its own `ProductVersion`. |
| mod_php / DLL host | loaded library path | Linux from `/proc/<pid>/maps`; Windows from `Get-Process -Module` / `tasklist /m`; macOS `lsof -d txt` (root). |
| extension only (`/php/extensions/*.so`) | — | Version `unknown` in the list; use the exe's line. |

Normalise before joining:

- **Windows:** compare case-insensitively. The Windows scan prints `\\?\C:\...`
  for paths it reached through the long-path prefix; strip `\\?\`.
- **macOS:** `/tmp`, `/var`, `/etc` are symlinks into `/private`; the process
  path is the path it was started with. Resolve both sides (`realpath`) if
  they may differ. (Here both sides showed `/private/tmp/...`.)
- **Linux containers:** the exe path is container-internal and the host YARA
  scan doesn't look inside image layers (README). Scan `/proc/<pid>/exe` and
  `/proc/<pid>/root/<libphp path>` instead of joining.
- **`(deleted)` exe (Linux):** the binary was replaced after the process
  started; the on-disk version is not what's running.

## Recommended approach

1. **Script per OS, results file + analysis** (most complete). For each
   listening socket (TCP, and unix on Linux/macOS), record
   `proto  address:port  pid  exe  php_file  version`:
   - **Linux:** the `/proc` script above (no dependencies, sees containers), then
     YARA (`yr`, already downloaded by the existing task) on `/proc/<pid>/exe` and
     on `/proc/<pid>/root/<libphp>` for each PHP-evidence PID. Covers all five
     cases, containers, and upgraded-but-not-restarted processes.
   - **Windows:** the PowerShell above; the version comes from the exe's or the
     loaded `php*.dll`'s `ProductVersion`, no YARA needed. Add `w3wp.exe` →
     `php-cgi.exe` children for IIS.
   - **macOS:** `netstat -anv` → `ps -o comm=` → `lsof -d txt` (root), joined to
     the YARA list (or YARA on the exe).

   Run as root / SYSTEM (the BigFix agent does). Write to
   `__BESData/__Global/Logs/php_listeners.text` so one analysis property reports
   "version on port".
2. **Relevance only, no new script** (quick win): statement 7 as one analysis
   property on all platforms. It works without YARA results, and they add
   `yara` evidence and versions. Statements 3–5 are smaller single-purpose
   alternatives. It can't confirm DLL hosts on Windows/macOS (only
   `httpd-conf` / `webserver-modules-unknown` hints), misses container listeners
   from a Linux host (container processes still show as `running`; add 6 for
   their ports), and reports the on-disk version for an upgraded-but-running binary.
3. Report "running" (any process) separately from "listening": a PHP worker
   behind RoadRunner or a php-fpm pool on a unix socket serves the network
   without a PHP-owned TCP port.

## Not tested

- macOS: `php -S`, `php-cgi`, php-fpm, mod_php (conda PHP can't start without
  its conda dependencies); non-root `lsof -d txt` on other users' processes.
- Windows: real Apache + `php8apache2_4.dll` (simulated with `LoadLibrary`),
  IIS / FastCGI / `w3wp.exe` (not installed), PHP 8.5 (VC++ runtime too old),
  non-elevated view, 32-bit processes, Windows 11 commands (only relevance ran
  there), Windows containers.
- Linux: Swoole/OpenSwoole, Workerman, RoadRunner (only a plain
  `stream_socket_server` loop), nginx in front of php-fpm, qemu-user emulation,
  real (non-container) hosts with PHP; Linux relevance on real hosts ran without
  PHP.
- Static FrankenPHP on Linux (the Docker image uses `libphp.so`).
