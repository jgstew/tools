#!/usr/bin/env python3
"""Generate the cross-platform BigFix client relevance that finds running / listening PHP.

Statement 7 in detect_running_php.md. One expression for Windows, macOS and
Linux: every listening TCP socket ("address:port") and every process ("running")
that looks like PHP, one answer per line:

    <address:port | running> pid=.. name=.. path=.. evidence=.. version=.. libphp=..

It works without a YARA scan (evidence from the process name, exe path, Windows
version resource, Linux /proc/<pid>/maps, Apache config); when the YARA tasks'
yara_results_php.text (path<TAB>version) is present it adds "yara" evidence and
versions. Edit the pieces here, not the generated one-liner.

Usage:
    python3 gen_running_php_relevance.py                  # reads __BESData/__Global/Logs/yara_results_php.text
    python3 gen_running_php_relevance.py /tmp/results.txt # reads this results file instead (testing)

Check and run it:
    uvx bigfix-relevance-analyzer --max-score 2000 "$(python3 gen_running_php_relevance.py)"
    uvx bigfix-remote-client-relevance "$(python3 gen_running_php_relevance.py)"
"""

import sys

# YARA results (path<TAB>version per line). Default: what the YARA-X scan tasks write.
if len(sys.argv) > 1:
    RESULTS = 'files "%s"' % sys.argv[1]
else:
    RESULTS = ('files whose (name of it as lowercase starts with "yara_results_php.text") '
               'of folders "Logs" of folders "__Global" of data folders of client')

# The whole results file as one lowercase string, each line wrapped in "%0a",
# so "%0a<path>%09" finds a path. Evaluated once, as item 0 of every tuple.
F = '("%0a" & concatenation "%0a" of (it as string as lowercase) of lines of ' + RESULTS + ' & "%0a")'

# (where, process): listening sockets with their owner(s), plus every process as "running".
# "processes of <socket>" (plural): some sockets have no owning process.
U = ('((local address of it as string & ":" & local port of it as string, processes of it) '
     'of sockets whose (tcp of it and listening of tcp state of it) of network ; ("running", it) of processes)')

P = 'item 2 of it'
NAME = '(name of item 2 of it | "")'  # some Windows processes have no name
# /proc/<pid>/maps, only where readable: an unreadable maps (non-root, or no CAP_SYS_PTRACE)
# is a fatal file error that "exists" and "|" don't absorb. /proc/<pid>/root resolves
# only with the same ptrace access. On Windows/macOS the file doesn't exist (no answers).
MAPS = ('files ("/proc/" & (pid of item 2 of it as string) & "/maps") '
        'whose (exists folder (pathname of parent folder of it & "/root"))')
WEB = f'({NAME} as lowercase starts with "httpd" or {NAME} as lowercase starts with "apache")'

# Evidence: each check yields its label or "". "version block" is Windows-only, so it
# must sit in an untaken "if" branch; nothing else stops it erroring on macOS/Linux.
EVIDENCE = [
    f'(if ({NAME} as lowercase contains "php") then "name" else "")',
    f'(if (exists pathnames whose (it as lowercase contains "php") of image files of {P}) then "path" else "")',
    f'(if (windows of operating system) then (if (exists image files whose '
    f'(value "ProductName" of version block 1 of it as string = "PHP") of {P}) then "pe" else "") else "")',
    f'(if (exists lines whose (it as lowercase contains "/libphp") of {MAPS}) then "libphp" else "")',
    f'(if (exists lines whose (it as lowercase contains "/php/extensions/") of {MAPS}) then "php-ext" else "")',
    f'(if (exists (item 0 of it, (it as lowercase) of pathnames of image files of {P}) '
    f'whose (item 0 of it contains ("%0a" & item 1 of it & "%09"))) then "yara" else "")',
    # Windows/XAMPP-style layout: <root>\bin\httpd.exe with <root>\conf\httpd.conf (+ conf\extra\*.conf)
    f'(if {WEB} then (if (exists lines whose (it as lowercase contains "loadmodule php") of files whose '
    f'(name of it as lowercase ends with ".conf") of (folders "conf" of it; folders "extra" of folders "conf" of it) '
    f'of parent folders of parent folders of image files of {P}) then "httpd-conf" else "") else "")',
    f'(if ({WEB} and not exists {MAPS}) then "webserver-modules-unknown" else "")',
]
EVID = 'concatenation "," of (' + ' ; '.join(EVIDENCE) + ') whose (it != "")'

# Versions: Windows PE ProductVersion, YARA line for the exe, YARA lines for mapped files (libphp.so).
# Not "following text of first (X) of Y": an "it" inside X is rebound to Y. So split the
# results into lines and match with "starts with", which doesn't rebind.
VERSION = (
    'concatenation "," of unique values of (('
    f'(if (windows of operating system) then concatenation "," of (value "ProductVersion" of version block 1 of it as string) '
    f'of image files whose (value "ProductName" of version block 1 of it as string = "PHP") of {P} else "")'
    f' ; (following text of first "%09" of item 1 of it) of ((it as lowercase) of pathnames of image files of {P}, '
    f'substrings separated by "%0a" of item 0 of it) whose (item 1 of it starts with (item 0 of it & "%09"))'
    f' ; (following text of first "%09" of item 1 of it) of (unique values of (("/" & following text of first "/" of it) as lowercase) '
    f'of lines whose (it contains "/") of {MAPS}, substrings separated by "%0a" of item 0 of it) '
    f'whose (item 1 of it starts with (item 0 of it & "%09"))'
    ') whose (it != "" and it != "unknown"))'  # "unknown" = extensions with no version string
)
LIBS = f'concatenation ";" of unique values of ("/" & following text of first "/" of it) of lines whose (it as lowercase contains "/libphp") of {MAPS}'

FORMAT = (f'item 1 of it & " pid=" & (pid of {P} as string) & " name=" & {NAME} & " path=" & (pathname of image file of {P} | "?")'
          f' & " evidence=" & item 3 of it & " version=" & {VERSION} & " libphp=" & {LIBS}')

# (F, (where, process)) -> flat (F, where, process) -> (F, where, process, evidence) -> keep evidence != ""
print(f'unique values of ({FORMAT}) of ((item 0 of it, item 1 of it, item 2 of it, {EVID}) of '
      f'((item 0 of it, item 0 of item 1 of it, item 1 of item 1 of it) of ({F}, {U}))) whose (item 3 of it != "")')
