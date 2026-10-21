#!/usr/bin/env python3
"""Generate the BigFix tasks and analysis for the YARA-X PHP install scan.

Embeds the three scan scripts (bash/yara_x_scan_macos.sh,
bash/yara_x_scan_linux.sh, powershell/yara_x_scan_windows.ps1) into one task
per OS, and writes one analysis that reads the results back:

    <bigfix-content>/fixlet/Scan for PHP Installs with YARA-X - macOS.bes
    <bigfix-content>/fixlet/Scan for PHP Installs with YARA-X - Linux.bes
    <bigfix-content>/fixlet/Scan for PHP Installs with YARA-X - Windows.bes
    <bigfix-content>/analyses/PHP Installs from YARA-X Scan - Universal.bes

The yr (YARA-X CLI) release archive is a BigFix prefetch instead of a download
inside the script; the scripts get it with -a / -YaraXArchive and still check
its SHA256. Edit the scripts, then rerun this to refresh the tasks.

Usage:
    python3 make_bigfix_content.py [BIGFIX_CONTENT_DIR]

BIGFIX_CONTENT_DIR defaults to a bigfix-content checkout next to this repo.

The PREFETCH lines below were generated with the bigfix-prefetch package:
    from bigfix_prefetch.prefetch_from_url import url_to_prefetch
    from bigfix_prefetch.prefetch_from_dictionary import prefetch_from_dictionary
    print(prefetch_from_dictionary(url_to_prefetch(URL, True), "block"))
Their sha256 values match the ones pinned in the scripts.
"""

import email.utils
import pathlib
import sys

TOOLS_DIR = pathlib.Path(__file__).resolve().parents[2]
RELEASE_DATE = "2026-10-21"
RESULTS_FILE = "yara_results_php.text"
END_MARKER = "_END_OF_SCRIPT_"

_URL = "https://github.com/VirusTotal/yara-x/releases/download/v1.22.0/"
PREFETCH = {
    "macos-aarch64": "add prefetch item name=yara-x-v1.22.0-aarch64-apple-darwin.tar.gz sha1=16b30fd7d7613bd0172bc197d785f1143c34f2b9 size=8421133 url="
    + _URL
    + "yara-x-v1.22.0-aarch64-apple-darwin.tar.gz sha256=79d596da5bf02205de63a1d7844a964daebc7293fa36fcb7da46c3e3c7567229",
    "macos-x86_64": "add prefetch item name=yara-x-v1.22.0-x86_64-apple-darwin.tar.gz sha1=560ace0fca8543195a71d52545bef248e92854e4 size=9476144 url="
    + _URL
    + "yara-x-v1.22.0-x86_64-apple-darwin.tar.gz sha256=d059da4b91c7d7b43f6f50174a7739e3362b51f349f2ba8b33d46e3334bb3300",
    "linux-aarch64": "add prefetch item name=yara-x-v1.22.0-aarch64-unknown-linux-gnu.tar.gz sha1=fde88001e579387275f731387963dd220f7a6fbd size=9252173 url="
    + _URL
    + "yara-x-v1.22.0-aarch64-unknown-linux-gnu.tar.gz sha256=b1b90f0686ae3e9f607c07b743fd96d6283d9ea5e2fd764919b8505de8b63d4e",
    "linux-x86_64": "add prefetch item name=yara-x-v1.22.0-x86_64-unknown-linux-gnu.tar.gz sha1=f6e1f286242753e0e621c43da7f0c753c8ffc1f4 size=10347394 url="
    + _URL
    + "yara-x-v1.22.0-x86_64-unknown-linux-gnu.tar.gz sha256=7f470770b2c1a0d97f02298fc194978d999074d147d003d33dd62775761439db",
    "windows-x86_64": "add prefetch item name=yara-x-v1.22.0-x86_64-pc-windows-msvc.zip sha1=344da50ce1693edd32b92c7d32eaf26d99c97f17 size=9081400 url="
    + _URL
    + "yara-x-v1.22.0-x86_64-pc-windows-msvc.zip sha256=eac36a58699b94d3732a7fe1d8453fe89e0077bb18ac2c99b4c2ee102a431f2e",
}

# Every task: skip proxy agents, and only run when there's no result from the last day
COMMON_RELEVANCE = [
    "not in proxy agent context",
    'not exists files whose(name of it as lowercase starts with "yara_results_php.text" AND (now - modification time of it) < 1*day ) of folders "Logs" of folders "__Global" of data folders of client',
    # not while a scan from an earlier action is still running in the background
    # (a marker older than 12 hours is from a scan that died)
    'not exists files whose(name of it = "scan.running" AND (now - modification time of it) < 12*hour) of folders "yara_php_scan" of folders "__Global" of data folders of client',
]

LOGS_FOLDER = (
    'pathname of folders "Logs" of folders "__Global" of data folders of client'
)
GLOBAL_FOLDER = 'pathname of folders "__Global" of data folders of client'
# the prefetched yr archive (the only yara-x-v* file in __Download)
ARCHIVE_NAME = 'name of file whose(name of it starts with "yara-x-v") of folder "__Download" of client folder of current site'

# Started with "run" so the scan runs in the background and the client stays
# free for other actions. @NAME@ placeholders become BigFix parameters; every
# other left curly brace is escaped like in the scan scripts.
WRAPPER_BASH = r"""#!/bin/bash
# Started by the BigFix task with "run": runs the scan in the background, then
# copies the summary to the Logs folder. scan.running marks a scan in progress
# (the task is not relevant while it exists).
T="@TEMP@"
D="@DEST@"
touch "$T/scan.running"
/bin/bash "$T/@SCRIPT@" -a "$T" -o "$T/results" >"$T/scan_console.log" 2>&1
rc=$?
echo "scan exit code: $rc (0 = no PHP found, 1 = PHP found, 2-4 = error)" >>"$T/scan_console.log"
mkdir -p "$D"
# Only a finished scan replaces the results; written under a temp name first so
# the analysis never reads a partial file
if [ "$rc" -le 1 ]; then
  for f in "$T"/results/yara_results_*.text; do
    case "$f" in *.raw.text) continue ;; esac
    cp "$f" "$D/.@RESULTS@.tmp" && mv -f "$D/.@RESULTS@.tmp" "$D/@RESULTS@"
  done
fi
cp "$T/scan_console.log" "$D/yara_scan_php.log"
rm -f "$T"/yara-x-v* "$T/scan.running"
"""

WRAPPER_PS1 = r"""# Started by the BigFix task with "run": runs the scan in the background, then
# copies the summary to the Logs folder. scan.running marks a scan in progress
# (the task is not relevant while it exists).
$T = '@TEMP@'
$D = '@DEST@'
$running = Join-Path -Path $T -ChildPath 'scan.running'
$console = Join-Path -Path $T -ChildPath 'scan_console.log'
New-Item -ItemType File -Force -Path $running | Out-Null
# A separate 64-bit powershell.exe: the scan script ends with "exit"
& "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path -Path $T -ChildPath '@SCRIPT@') -YaraXArchive $T -OutputDir (Join-Path -Path $T -ChildPath 'results') *>&1 | Out-File -FilePath $console -Encoding utf8
$rc = $LASTEXITCODE
"scan exit code: $rc (0 = no PHP found, 1 = PHP found, 2-4 = error)" | Out-File -FilePath $console -Encoding utf8 -Append
if (-not (Test-Path -LiteralPath $D)) { New-Item -ItemType Directory -Force -Path $D | Out-Null }
# Only a finished scan replaces the results; written under a temp name first so
# the analysis never reads a partial file
if ($rc -eq 0 -or $rc -eq 1)
{
    $summary = Get-ChildItem -LiteralPath (Join-Path -Path $T -ChildPath 'results') -Filter 'yara_results_*.text' |
        Where-Object { -not $_.Name.EndsWith('.raw.text') } | Select-Object -First 1
    if ($summary)
    {
        $tmp = Join-Path -Path $D -ChildPath '.@RESULTS@.tmp'
        Copy-Item -LiteralPath $summary.FullName -Destination $tmp -Force
        Move-Item -LiteralPath $tmp -Destination (Join-Path -Path $D -ChildPath '@RESULTS@') -Force
    }
}
Copy-Item -LiteralPath $console -Destination (Join-Path -Path $D -ChildPath 'yara_scan_php.log') -Force
Remove-Item -Path (Join-Path -Path $T -ChildPath 'yara-x-v*') -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $running -Force -ErrorAction SilentlyContinue
"""

PLATFORMS = {
    "macOS": {
        "script": "bash/yara_x_scan_macos.sh",
        "relevance": [
            "mac of operating system",
            # yr: x86_64 build needs 10.12+, arm64 build 11.0+ (every Apple Silicon Mac)
            'version of operating system >= "10.12"',
        ],
        "prefetch": [
            ('architecture of operating system = "arm64"', "macos-aarch64"),
            ('architecture of operating system != "arm64"', "macos-x86_64"),
        ],
        "download_size": 9476144,
        "sep": "/",
        "notes": "Runs as root. The BigFix agent needs Full Disk Access (MDM PPPC profile) to read protected folders; without it they are skipped. The read-only system volume, cloud-drive folders, files of 512 MB or more and non-executable file types are skipped.",
    },
    "Linux": {
        "script": "bash/yara_x_scan_linux.sh",
        "relevance": [
            'name of operating system as lowercase starts with "linux"',
            # yr is only released for these two (statically linked: any distro)
            'exists (architecture of operating system) whose(it = "x86_64" OR it = "aarch64")',
            'exists file "/bin/bash"',
        ],
        "prefetch": [
            ('architecture of operating system = "aarch64"', "linux-aarch64"),
            ('architecture of operating system = "x86_64"', "linux-x86_64"),
        ],
        "download_size": 10347394,
        "sep": "/",
        "notes": "Runs as root and scans every local disk filesystem (separate /home, /var, /opt, tmpfs /tmp, snaps); network shares, FUSE mounts, container storage, snapshots, files of 512 MB or more and non-executable file types are skipped.",
    },
    "Windows": {
        "script": "powershell/yara_x_scan_windows.ps1",
        "relevance": [
            "windows of operating system",
            # yr is x64 only and needs Windows 10 / Server 2016 or later
            "x64 of operating system",
            'version of operating system >= "10.0"',
            'exists (it as string as version) whose(it >= "5.1") of values "PowerShellVersion" of keys "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\PowerShell\\3\\PowerShellEngine" of native registry',
        ],
        "prefetch": [(None, "windows-x86_64")],
        "download_size": 9081400,
        "sep": "\\",
        "notes": "Runs as SYSTEM with 64-bit PowerShell and scans every local fixed drive; network, removable and optical drives, online-only cloud files, WinSxS and similar system folders, files of 512 MB or more and non-executable file types are skipped.",
    },
}


def bigfix_escape(text):
    """Escape a file for createfile: "{" starts relevance substitution, "{{" is a literal "{"."""
    return text.replace("{", "{{")


def check_embeddable(name, text):
    for bad in ("]]>", "\n" + END_MARKER + "\n"):
        if bad in text:
            sys.exit(f"ERROR: {name} contains {bad!r} and can't be embedded")
    if not text.isascii():
        sys.exit(
            f"ERROR: {name} must be ASCII (createfile writes it in the local code page)"
        )


def prefetch_block(items):
    lines = ["begin prefetch block"]
    for condition, key in items:
        if condition:
            lines += [f"\tif {{{condition}}}", f"\t\t{PREFETCH[key]}", "\tendif"]
        else:
            lines.append(f"\t{PREFETCH[key]}")
    lines.append("end prefetch block")
    return "\n".join(lines)


def wrapper_text(os_name, script_name):
    text = bigfix_escape(WRAPPER_PS1 if os_name == "Windows" else WRAPPER_BASH)
    for key, value in {
        "@TEMP@": '{parameter "temp_folder"}',
        "@DEST@": '{parameter "destination_folder"}',
        "@RESULTS@": '{parameter "results_file"}',
        "@SCRIPT@": script_name,
    }.items():
        text = text.replace(key, value)
    return text.rstrip("\n")


def actionscript(os_name, cfg, script_text):
    sep = cfg["sep"]
    script_name = pathlib.PurePosixPath(cfg["script"]).name
    if os_name == "Windows":
        wrapper_name = "run_scan.ps1"
        # 64-bit PowerShell, so System32 isn't redirected to SysWOW64 during the scan
        run = f"""action uses wow64 redirection {{not x64 of operating system}}

override run
hidden=true
run "{{pathname of system folder}}\\WindowsPowerShell\\v1.0\\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "{{parameter "temp_folder"}}\\{wrapper_name}\""""
    else:
        wrapper_name = "run_scan.sh"
        run = f"""run /bin/bash "{{parameter "temp_folder"}}/{wrapper_name}\""""

    return f"""// Scan for PHP installs and their versions with YARA-X - {os_name}
// Generated by YARA/php/make_bigfix_content.py from {cfg["script"]} in
// https://github.com/jgstew/tools - change the script there and regenerate.

// yr (YARA-X CLI) release archive for this OS/CPU; the script still checks its SHA256
{prefetch_block(cfg["prefetch"])}

// Where the "path<TAB>version" results are copied to (read by the analysis):
parameter "destination_folder" = "{{{LOGS_FOLDER}}}"
parameter "results_file" = "{RESULTS_FILE}"
// The scan runs in the background from here, not __Download: the client clears
// __Download when the action ends, and the scan outlives the action
parameter "temp_folder" = "{{{GLOBAL_FOLDER}}}{sep}yara_php_scan"

folder delete "{{parameter "temp_folder"}}"
folder create "{{parameter "temp_folder"}}"
copy "__Download{sep}{{{ARCHIVE_NAME}}}" "{{parameter "temp_folder"}}{sep}{{{ARCHIVE_NAME}}}"

// The scan script; every left curly brace in it is doubled, BigFix's escape for relevance substitution
delete __createfile
createfile until {END_MARKER}
{bigfix_escape(script_text).rstrip(chr(10))}
{END_MARKER}
copy __createfile "{{parameter "temp_folder"}}{sep}{script_name}"

// The wrapper that runs it and copies the results to the destination folder
delete __createfile
createfile until {END_MARKER}
{wrapper_text(os_name, script_name)}
{END_MARKER}
copy __createfile "{{parameter "temp_folder"}}{sep}{wrapper_name}"

// Mark the scan as running before it starts, so the task isn't relevant again
// in the meantime (the wrapper removes the marker when the scan ends)
delete __createfile
createfile until {END_MARKER}
started by action {{id of action}}
{END_MARKER}
copy __createfile "{{parameter "temp_folder"}}{sep}scan.running"

// Start the scan without waiting (it can take 10-30+ minutes): the action ends
// here and the client runs other actions. The results show up when it finishes.
{run}
"""


def task_xml(os_name, cfg, script_text, mtime):
    title = f"Scan for PHP Installs with YARA-X - {os_name}"
    relevance = "\n".join(
        f"\t\t<Relevance><![CDATA[{r}]]></Relevance>"
        for r in cfg["relevance"] + COMMON_RELEVANCE
    )
    description = (
        "<P>Scans this computer for PHP installs, both package-managed and one-off (XAMPP, MAMP, Laragon, "
        "zips unpacked to a folder, static builds such as FrankenPHP), and records the exact version of each. "
        'It uses <A href="https://github.com/VirusTotal/yara-x">YARA-X</A> with the rules from '
        '<A href="https://github.com/jgstew/tools/tree/master/YARA/php">jgstew/tools YARA/php</A>; '
        "the version is read from strings compiled into the binaries, so PHP is never run.</P>"
        f"<P>Results: one line per file, &quot;path&lt;TAB&gt;version&quot; (&quot;unknown&quot; for files "
        f"such as extensions that carry no version), in __BESData/__Global/Logs/{RESULTS_FILE}. "
        "Activate the analysis &quot;PHP Installs from YARA-X Scan - Universal&quot; to report them. "
        "The task becomes relevant again when the results are more than a day old.</P>"
        f"<P>{cfg['notes']}</P>"
        "<P>The scan runs in the background (started with run, so the agent stays free for other actions) "
        "from __BESData/__Global/yara_php_scan and reads the whole disk, which can take 10-30 minutes or more. "
        "The action completes when the scan starts; the results file appears when it finishes, and its console "
        "output goes to __BESData/__Global/Logs/yara_scan_php.log. While a scan is running the task is not "
        "relevant, so a second one is not started.</P>"
    )
    return (
        f"""<?xml version="1.0" encoding="UTF-8"?>
<BES xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BES.xsd">
	<Task>
		<Title>{title}</Title>
		<Description><![CDATA[{description}]]></Description>
{relevance}
		<Category></Category>
		<DownloadSize>{cfg["download_size"]}</DownloadSize>
		<Source>Internal</Source>
		<SourceID>jgstew</SourceID>
		<SourceReleaseDate>{RELEASE_DATE}</SourceReleaseDate>
		<SourceSeverity></SourceSeverity>
		<CVENames></CVENames>
		<SANSID></SANSID>
		<MIMEField>
			<Name>x-fixlet-modification-time</Name>
			<Value>{mtime}</Value>
		</MIMEField>
		<Domain>BESC</Domain>
		<DefaultAction ID="Action1">
			<Description>
				<PreLink>Click </PreLink>
				<Link>here</Link>
				<PostLink> to scan for PHP installs.</PostLink>
			</Description>
			<ActionScript MIMEType="application/x-Fixlet-Windows-Shell"><![CDATA[
{actionscript(os_name, cfg, script_text)}]]></ActionScript>
			<SuccessCriteria Option="RunToCompletion"></SuccessCriteria>
		</DefaultAction>
	</Task>
</BES>
""",
        title,
    )


def analysis_xml(mtime):
    files = f'files whose(name of it as lowercase starts with "{RESULTS_FILE}") of folders "Logs" of folders "__Global" of data folders of client'
    # Summary properties only: every line of the file (former ID 1) could be too
    # much data. IDs stay fixed so existing results keep their history.
    properties = [
        (
            2,
            "PHP Versions Found",
            f'unique values of following texts of lasts "%09" of lines of {files}',
        ),
        (3, "PHP Files Found", f"(number of lines of it) of {files}"),
        (4, "PHP Scan Time", f"modification times of {files}"),
    ]
    props = "\n".join(
        f'\t\t<Property Name="{name}" ID="{i}" EvaluationPeriod="P1D"><![CDATA[{rel}]]></Property>'
        for i, name, rel in properties
    )
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<BES xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BES.xsd">
	<Analysis>
		<Title>PHP Installs from YARA-X Scan - Universal</Title>
		<Description><![CDATA[<P>Reports the results of the &quot;Scan for PHP Installs with YARA-X&quot; tasks (macOS, Linux, Windows), once a day: the distinct PHP versions found, how many PHP files were found, and when the scan ran. Each computer's full list (&quot;path&lt;TAB&gt;version&quot; per file) is in __BESData/__Global/Logs/yara_results_php.text. A computer that was scanned and has no PHP reports 0 files.</P>]]></Description>
		<Relevance><![CDATA[exists {files}]]></Relevance>
		<Source>Internal</Source>
		<SourceID>jgstew</SourceID>
		<SourceReleaseDate>{RELEASE_DATE}</SourceReleaseDate>
		<MIMEField>
			<Name>x-fixlet-modification-time</Name>
			<Value>{mtime}</Value>
		</MIMEField>
		<Domain>BESC</Domain>
{props}
	</Analysis>
</BES>
"""


def write_file(path, text):
    bad = sorted({hex(ord(c)) for c in text if ord(c) < 32 and c not in "\n\t"})
    if bad:
        sys.exit(
            f"ERROR: control characters {bad} in {path.name} (a backslash escape?)"
        )
    # CRLF on every OS: the bigfix-content convention (E208). XML parsing turns
    # it back into LF inside the ActionScript, so createfile still writes LF.
    with open(path, "w", encoding="utf-8", newline="\r\n") as f:
        f.write(text)


def main():
    out_dir = (
        pathlib.Path(sys.argv[1])
        if len(sys.argv) > 1
        else TOOLS_DIR.parent / "bigfix-content"
    )
    if not (out_dir / "fixlet").is_dir() or not (out_dir / "analyses").is_dir():
        sys.exit(f"ERROR: {out_dir} has no fixlet/ and analyses/ folders")
    mtime = email.utils.formatdate(usegmt=True).replace("GMT", "+0000")

    for os_name, cfg in PLATFORMS.items():
        script_text = (TOOLS_DIR / cfg["script"]).read_text(encoding="utf-8")
        check_embeddable(cfg["script"], script_text)
        xml, title = task_xml(os_name, cfg, script_text, mtime)
        path = out_dir / "fixlet" / f"{title}.bes"
        write_file(path, xml)
        print(f"wrote {path}")

    path = out_dir / "analyses" / "PHP Installs from YARA-X Scan - Universal.bes"
    write_file(path, analysis_xml(mtime))
    print(f"wrote {path}")


if __name__ == "__main__":
    main()
