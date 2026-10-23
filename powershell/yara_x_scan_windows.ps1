<#
.SYNOPSIS
    Self-contained YARA-X scan for Windows that finds PHP installs and their versions.

.DESCRIPTION
    Windows counterpart of bash/yara_x_scan_macos.sh:
      1. downloads the YARA-X CLI (yr.exe) release
      2. verifies the SHA256 of the download against a pinned value
      3. unpacks it into a temporary folder (removed on exit)
      4. scans the target (recursively) with the YARA rule embedded below
         (a copy of YARA/php/php_detect.yar)
      5. writes results + a log to OutputDir; for text format:
           yara_results_<host>_<time>.raw.text  full yr output (rules, meta, strings)
           yara_results_<host>_<time>.text      "path<TAB>version", one per line
         Files matched with no version string are listed with version "unknown".
         json / ndjson write a single yara_results_<host>_<time>.json / .ndjson.

    With no -Path, every local fixed drive (DriveType 3) is scanned. Network,
    removable and optical drives are skipped. Note that some USB disks and
    mounted VHDs report themselves as fixed and are scanned too.

    Junctions and directory symlinks are not followed (avoids loops and scanning
    the same files twice). File symlinks list with no size and are skipped like
    empty files (their target is scanned where it lives); other file-level
    reparse points are scanned: they can be real local files (deduplicated
    volumes, hydrated OneDrive files).

    Run as Administrator for a full scan; otherwise protected folders are logged
    as unreadable and skipped.

    yr.exe is x64 only (YARA-X ships no Windows ARM64 build); on Windows on ARM
    it runs under x64 emulation.

    Skipped by default (each skip is reported while running; files over the size
    cap are listed in the log). A skipped folder that contains the target is not
    skipped, and none of the skips apply when the target is a single file.
      - Files of MaxMB (512) MB or more: PHP builds are ~20-40 MB, the largest
        known (FrankenPHP, static PHP in Go) ~180 MB; this cuts pagefile.sys,
        VM disks, WSL/Docker .vhdx, media. Use -MaxMB 0 to include.
      - Images, media, archives, installers, documents, fonts, web/source/text
        files, C headers other than php_version.h, debug symbols (.pdb), event
        logs and databases: the rules only match executables (by header) and
        php-config/php_version.h. Files with no extension, .exe, .dll, .so, .o
        are kept. Use -IncludeNonBinary to include.
      - Empty files.
      - Cloud placeholders (OneDrive Files On-Demand, Dropbox, iCloud, etc.):
        files and folders with the Offline, RecallOnOpen or RecallOnDataAccess
        attribute are only online, and reading them would download them. Use
        -IncludeCloudFiles to include.
      - System folders that can't hold a PHP install, on every scanned drive:
          \Windows\WinSxS               component store: Microsoft side-by-side
                                        components only, mostly hard links to
                                        System32 (double scan), 100k+ files
          \Windows\SoftwareDistribution Windows Update download cache
          \$Recycle.Bin                 deleted files, not installs
          \System Volume Information    restore points/shadow copy data, not
                                        readable even as Administrator
          \pagefile.sys, \hiberfil.sys, \swapfile.sys  locked by the OS
        The rest of C:\Windows is scanned on purpose: old PHP setup guides told
        people to copy php5ts.dll / php.ini into C:\Windows\System32. Use
        -IncludeSystemPaths to include these too.
      - This script's own output and temp folders (old results contain matched
        strings).
    Nothing where PHP is plausible is skipped: C:\xampp, C:\wamp*, C:\laragon,
    C:\php*, C:\tools (Chocolatey), Program Files, Program Files (x86) (IIS PHP
    Manager / Web PI), ProgramData, user profiles.

    The scan runs at BelowNormal priority (this PowerShell process and yr.exe)
    and yr uses 2 threads (-Threads), so a full scan doesn't take over the
    machine. It's meant to run unattended; in an interactive session the
    priority stays lowered until that PowerShell window is closed.

    Exit codes: 0 = scan ran, no matches; 1 = scan ran, matches found;
                2 = usage error; 3 = download/verify/unpack error; 4 = scan error

    Release: https://github.com/VirusTotal/yara-x/releases/tag/v1.22.0
    Related: https://github.com/jgstew/tools/tree/master/YARA/php
             https://github.com/jgstew/tools/blob/master/bash/yara_x_scan_macos.sh

.PARAMETER Path
    One or more files or folders to scan. Default: all local fixed drives.
    With powershell.exe -File, list several targets separated by spaces
    (-Path C:\xampp D:\web), not commas: -File passes "A,B" as one path.

.PARAMETER OutputDir
    Folder to write results into. Default: .\yara_results

.PARAMETER Format
    yr output format: text, json or ndjson. Default: text

.PARAMETER KeepBinary
    Keep the downloaded yr.exe in OutputDir\bin for reuse.

.PARAMETER YaraXArchive
    Use a local yr release zip instead of downloading: the file, or a folder
    holding it under its release name (e.g. a BigFix prefetch folder). Its
    SHA256 is still checked.

.PARAMETER MaxMB
    Skip files of MaxMB MB or larger; 0 = no limit. Default: 512

.PARAMETER Threads
    Number of yr scan threads. Default: 2

.PARAMETER ExcludePath
    Folders to skip, comma-separated (-ExcludePath D:\backup,E:\media). A
    folder that contains the target is not skipped.

.PARAMETER IncludeSystemPaths
    Also scan the system folders listed above (WinSxS, Recycle Bin, ...).

.PARAMETER IncludeNonBinary
    Also scan file types that can't be executables.

.PARAMETER IncludeCloudFiles
    Also read online-only cloud files. This downloads them.

.PARAMETER Help
    Show this help.

.PARAMETER ExtraArgs
    Catch-all for arguments after -Path: those that are not options are more
    targets; an unknown option is a usage error (exit code 2).

.EXAMPLE
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\yara_x_scan_windows.ps1

    Scan all local fixed drives, writing results to .\yara_results.

.EXAMPLE
    .\yara_x_scan_windows.ps1 -Path C:\xampp, D:\web -OutputDir C:\Temp\yara -KeepBinary

.EXAMPLE
    .\yara_x_scan_windows.ps1 -Format ndjson -MaxMB 0

.NOTES
    Works with Windows PowerShell 5.1 and PowerShell 7+.
    To download:
      Invoke-WebRequest -UseBasicParsing -OutFile yara_x_scan_windows.ps1 https://raw.githubusercontent.com/jgstew/tools/master/powershell/yara_x_scan_windows.ps1
#>
# Status lines go to the console via Write-Host (the information stream since
# PS 5.0, so 6> can redirect them) and keep stdout free for callers.
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Console status output')]
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$Path,

    [string]$OutputDir = (Join-Path -Path (Get-Location).ProviderPath -ChildPath 'yara_results'),

    # Validated in the script body (not ValidateSet/[int]) so bad values exit with code 2
    [string]$Format = 'text',

    [switch]$KeepBinary,

    [string]$YaraXArchive,

    [string]$MaxMB = '512',

    [string]$Threads = '2',

    [string[]]$ExcludePath,

    [switch]$IncludeSystemPaths,

    [switch]$IncludeNonBinary,

    [switch]$IncludeCloudFiles,

    [switch]$Help,

    # More targets, or unknown options (exit code 2 instead of a binding error)
    [Parameter(ValueFromRemainingArguments = $true, DontShow = $true)]
    [string[]]$ExtraArgs
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

$YaraXVersion = '1.22.0'
$YaraXAsset   = "yara-x-v$YaraXVersion-x86_64-pc-windows-msvc.zip"
$YaraXUrl     = "https://github.com/VirusTotal/yara-x/releases/download/v$YaraXVersion/$YaraXAsset"
# GitHub-computed asset digest for v1.22.0 (releases API, assets[].digest)
$YaraXSha256  = 'eac36a58699b94d3732a7fe1d8453fe89e0077bb18ac2c99b4c2ee102a431f2e'

# Same base list as NONBINARY_EXTS in bash/yara_x_scan_macos.sh: extensions of files
# that can't start with an executable header and aren't php-config / php_version.h
# (php_version.h is kept despite 'h'). The last line is Windows-only: debug
# symbols, installers/cabinets, import libraries, event logs, ESE databases.
$NonBinaryExtensions = @(
    'jpg', 'jpeg', 'png', 'gif', 'heic', 'tif', 'tiff', 'bmp', 'webp', 'ico', 'icns', 'svg', 'svgz',
    'mov', 'mp4', 'm4v', 'avi', 'mkv', 'mp3', 'm4a', 'aac', 'wav', 'aiff', 'caf', 'flac',  # codespell:ignore caf
    'pdf', 'zip', 'gz', 'tgz', 'xz', 'bz2', 'zst', '7z', 'rar', 'dmg', 'pkg', 'xip', 'iso', 'jar', 'whl',
    'docx', 'xlsx', 'pptx', 'doc', 'xls', 'ppt', 'pages', 'numbers', 'key',
    'txt', 'md', 'rst', 'json', 'js', 'mjs', 'cjs', 'ts', 'tsx', 'jsx', 'map', 'css', 'scss', 'html', 'htm',
    'xml', 'plist', 'strings', 'nib', 'car', 'py', 'pyc', 'rb', 'php', 'java', 'class', 'go', 'rs',
    'c', 'cc', 'cpp', 'h', 'hpp', 'm', 'swift', 'yml', 'yaml', 'toml', 'ini', 'csv', 'tsv', 'log',
    'sqlite', 'db', 'sqlite-wal', 'sqlite-shm', 'ttf', 'otf', 'woff', 'woff2', 'mo', 'po', 'lock', 'sum',
    'pdb', 'cab', 'msi', 'msp', 'nupkg', 'lib', 'cat', 'etl', 'evtx', 'edb', 'chm'
)

# System folders / files skipped on every scanned drive (see help for why)
$SystemSkipDirs  = @('Windows\WinSxS', 'Windows\SoftwareDistribution', '$Recycle.Bin', 'System Volume Information')
$SystemSkipFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys')

# FILE_ATTRIBUTE_OFFLINE | FILE_ATTRIBUTE_RECALL_ON_OPEN | FILE_ATTRIBUTE_RECALL_ON_DATA_ACCESS.
# Numeric because .NET Framework's FileAttributes enum has no names for the last two.
$CloudAttributeMask = 0x1000 -bor 0x40000 -bor 0x400000

# ---- embedded YARA rule -----------------------------------------------------
# PHP install detection + version. Copy of YARA/php/php_detect.yar - keep in
# sync. The version is in the printed strings ($ver, $pv, $cfg_ver, $hdr_ver).
$EmbeddedRule = @'
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
'@

$Utf8NoBom = New-Object -TypeName System.Text.UTF8Encoding -ArgumentList $false

function Write-ScanLog
{
    param([Parameter(Mandatory = $true)][string]$Message)
    Write-Host ('[{0}] {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message)
}

function Write-UsageError
{
    # Plain message on stderr, without the error-record noise of Write-Error
    param([Parameter(Mandatory = $true)][string]$Message)
    [Console]::Error.WriteLine("ERROR: $Message")
}

function Test-IsWindowsHost
{
    return [System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT
}

function Test-IsAdministrator
{
    $principal = New-Object -TypeName System.Security.Principal.WindowsPrincipal -ArgumentList ([System.Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-FixedDriveRoot
{
    # DriveType Fixed = Win32_LogicalDisk DriveType 3; skips network, removable, optical
    foreach ($drive in [System.IO.DriveInfo]::GetDrives())
    {
        if ($drive.DriveType -eq [System.IO.DriveType]::Fixed -and $drive.IsReady)
        {
            $drive.RootDirectory.FullName
        }
    }
}

function Test-PathWithin
{
    # True when $Child is $Parent or somewhere below it (case-insensitive, like NTFS)
    param([string]$Child, [string]$Parent)
    $c = $Child.TrimEnd('\', '/')
    $p = $Parent.TrimEnd('\', '/')
    if ($c.Equals($p, [System.StringComparison]::OrdinalIgnoreCase)) { return $true }
    return $c.StartsWith($p + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-YaraX
{
    # Downloads (or copies -ArchivePath), verifies and unpacks yr.exe into
    # $WorkDir; returns its path. Throws on any failure (the caller maps that
    # to exit code 3).
    param(
        [Parameter(Mandatory = $true)][string]$WorkDir,
        [string]$ArchivePath
    )

    $zipPath = Join-Path -Path $WorkDir -ChildPath $YaraXAsset

    if ($ArchivePath)
    {
        # A folder holding the zip under its release name (BigFix prefetch), or the zip itself
        if (Test-Path -LiteralPath $ArchivePath -PathType Container)
        {
            $ArchivePath = Join-Path -Path $ArchivePath -ChildPath $YaraXAsset
        }
        if (-not (Test-Path -LiteralPath $ArchivePath -PathType Leaf))
        {
            throw "yr archive not found: $ArchivePath"
        }
        Write-ScanLog "Using local archive $ArchivePath"
        Copy-Item -LiteralPath $ArchivePath -Destination $zipPath -Force
    }
    else
    {
        # Windows PowerShell 5.1 may default to TLS 1.0/1.1, which GitHub refuses
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

        Write-ScanLog "Downloading $YaraXUrl"
        $oldProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'  # the progress bar makes 5.1 downloads very slow
        try
        {
            for ($attempt = 1; $attempt -le 3; $attempt++)
            {
                try
                {
                    Invoke-WebRequest -Uri $YaraXUrl -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
                    break
                }
                catch
                {
                    if ($attempt -eq 3) { throw "download failed: $($_.Exception.Message)" }
                    Write-ScanLog "Download attempt $attempt failed ($($_.Exception.Message)), retrying"
                    Start-Sleep -Seconds (2 * $attempt)
                }
            }
        }
        finally
        {
            $ProgressPreference = $oldProgress
        }
    }

    $actual = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $YaraXSha256)
    {
        throw "SHA256 mismatch for $YaraXAsset`n  expected: $YaraXSha256`n  actual:   $actual"
    }
    Write-ScanLog "SHA256 verified: $actual"

    $binDir = Join-Path -Path $WorkDir -ChildPath 'bin'
    try
    {
        Expand-Archive -LiteralPath $zipPath -DestinationPath $binDir -Force
    }
    catch
    {
        throw "failed to unpack ${YaraXAsset}: $($_.Exception.Message)"
    }
    $yr = Join-Path -Path $binDir -ChildPath 'yr.exe'
    if (-not (Test-Path -LiteralPath $yr -PathType Leaf))
    {
        throw 'yr.exe not found in archive'
    }
    return $yr
}

function Invoke-NativeToFile
{
    # Runs $FilePath with $Arguments; stdout bytes go to $StdoutPath unchanged
    # (no PowerShell re-encoding, so non-ASCII paths survive), stderr is returned.
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$StdoutPath
    )

    # ProcessStartInfo.ArgumentList is .NET Core only, so build a quoted string.
    # Our arguments are file paths and flags: no embedded quotes or trailing '\'.
    $psi = New-Object -TypeName System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FilePath
    $psi.Arguments = ($Arguments | ForEach-Object { if ($_ -match '[\s"]') { '"' + $_ + '"' } else { $_ } }) -join ' '
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardErrorEncoding = $Utf8NoBom

    $process = [System.Diagnostics.Process]::Start($psi)
    # Background scan: keep the machine responsive. Best effort; yr runs either way.
    try { $process.PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch { $null = $_ }
    # Read stderr asynchronously so neither pipe can fill up and block yr
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $out = [System.IO.File]::Create($StdoutPath)
    try
    {
        $process.StandardOutput.BaseStream.CopyTo($out)
    }
    finally
    {
        $out.Dispose()
    }
    $process.WaitForExit()
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        Stderr   = $stderrTask.Result
    }
}

function ConvertTo-ExtendedPath
{
    # C:\x -> \\?\C:\x, \\server\share -> \\?\UNC\server\share. The prefix turns off
    # Win32 path parsing: no MAX_PATH (260) limit, even with LongPathsEnabled=0
    # and on .NET Framework, and trailing dots/spaces in names are kept.
    param([Parameter(Mandatory = $true)][string]$Path)
    if ($Path.StartsWith('\\?\')) { return $Path }
    if ($Path.StartsWith('\\')) { return '\\?\UNC\' + $Path.Substring(2) }
    return '\\?\' + $Path
}

function Get-ScanFile
{
    <#
    Walks $Root with an explicit stack (fast, and one unreadable folder doesn't
    stop the walk) and writes the files to scan to $ListWriter, one per line.
    Returns counters for the skips.

    A folder that fails with "not found" / "path too long" before any entry was
    read (path over 260 chars, or a name ending in '.' or ' ') is listed again
    with the \\?\ prefix; everything below it keeps the prefix, which yr
    accepts, so those paths appear as \\?\C:\... in the results.
    #>
    param(
        [Parameter(Mandatory = $true)][string]$Root,
        [Parameter(Mandatory = $true)][System.IO.TextWriter]$ListWriter,
        [Parameter(Mandatory = $true)][System.IO.TextWriter]$LogWriter,
        [System.Collections.Generic.HashSet[string]]$SkipDirs,
        [System.Collections.Generic.HashSet[string]]$SkipRootFiles,
        [System.Collections.Generic.HashSet[string]]$SkipExtensions,
        [long]$MaxBytes = 0,
        [bool]$SkipCloud = $true
    )

    $stats = [pscustomobject]@{ Listed = 0L; SizeSkipped = 0L; ExtSkipped = 0L; EmptySkipped = 0L; CloudSkipped = 0L; LinksSkipped = 0L; Errors = 0L }
    $dirAttr = [int][System.IO.FileAttributes]::Directory
    $reparseAttr = [int][System.IO.FileAttributes]::ReparsePoint

    # Windows only: retry a folder that "doesn't exist" or is "too long" with the
    # \\?\ prefix (see Get-ScanFile help); never on other OSes or twice
    $canExtend = [System.IO.Path]::DirectorySeparatorChar -eq '\'

    $stack = New-Object -TypeName 'System.Collections.Generic.Stack[string]'
    $stack.Push($Root)
    while ($stack.Count -gt 0)
    {
        $dir = $stack.Pop()
        $isDriveRoot = $dir -eq [System.IO.Path]::GetPathRoot($dir)
        $attempt = $dir
        $seen = 0
        while ($null -ne $attempt)
        {
            $retry = $null
            try
            {
                $dirInfo = New-Object -TypeName System.IO.DirectoryInfo -ArgumentList $attempt
                # Lazy enumeration: Attributes and Length come from the directory
                # listing itself, no extra per-file system call
                foreach ($entry in $dirInfo.EnumerateFileSystemInfos())
                {
                    $seen++
                    $attr = [int]$entry.Attributes
                    if ($attr -band $dirAttr)
                    {
                        if ($null -ne $SkipDirs -and $SkipDirs.Contains($entry.FullName)) { continue }
                        # Junctions, directory symlinks and volume mount points have a
                        # LinkType; other reparse folders (OneDrive) are real folders.
                        # LinkType is a PowerShell extended property (5.0+); if it is
                        # missing, treat every reparse folder as a link to be safe.
                        if ($attr -band $reparseAttr)
                        {
                            $linkType = $entry.PSObject.Properties['LinkType']
                            if ($null -eq $linkType -or $linkType.Value)
                            {
                                $stats.LinksSkipped++
                                continue
                            }
                        }
                        if ($SkipCloud -and ($attr -band $CloudAttributeMask))
                        {
                            $stats.CloudSkipped++
                            continue
                        }
                        $stack.Push($entry.FullName)
                        continue
                    }

                    if ($SkipCloud -and ($attr -band $CloudAttributeMask))
                    {
                        $stats.CloudSkipped++
                        continue
                    }
                    if ($isDriveRoot -and $null -ne $SkipRootFiles -and $SkipRootFiles.Contains($entry.Name)) { continue }
                    if ($null -ne $SkipExtensions)
                    {
                        $ext = $entry.Extension
                        if ($ext.Length -gt 1 -and $SkipExtensions.Contains($ext.Substring(1)) -and $entry.Name -ne 'php_version.h')
                        {
                            $stats.ExtSkipped++
                            continue
                        }
                    }
                    if ($entry.Length -eq 0)
                    {
                        $stats.EmptySkipped++
                        continue
                    }
                    if ($MaxBytes -gt 0 -and $entry.Length -ge $MaxBytes)
                    {
                        $LogWriter.WriteLine("skipped (>= $($MaxBytes / 1MB) MB): $($entry.FullName)")
                        $stats.SizeSkipped++
                        continue
                    }
                    $ListWriter.WriteLine($entry.FullName)
                    $stats.Listed++
                }
            }
            catch
            {
                $cause = $_.Exception.GetBaseException()
                if ($canExtend -and $seen -eq 0 -and -not $attempt.StartsWith('\\?\') -and
                    ($cause -is [System.IO.DirectoryNotFoundException] -or $cause -is [System.IO.PathTooLongException]))
                {
                    $retry = ConvertTo-ExtendedPath -Path $attempt
                }
                else
                {
                    # Access denied, folder removed during the walk, ...
                    # Files listed before the error are kept.
                    $LogWriter.WriteLine("error listing ${attempt}: $($_.Exception.Message)")
                    $stats.Errors++
                }
            }
            $attempt = $retry
        }
    }
    return $stats
}

function ConvertTo-PhpVersionSummary
{
    <#
    PowerShell port of YARA/php/php_versions.awk - keep in sync.
    Reads `yr scan --print-meta --print-strings` text output and returns sorted,
    unique "path<TAB>version" lines; matched files with no version string get
    "unknown".
    #>
    param([Parameter(Mandatory = $true)][string]$RawPath)

    # rule line: "<RULE> <path>", or with --print-meta "<RULE> [k="v",...] <path>".
    # The meta pattern skips quoted values, so a ']' inside a description is fine.
    $ruleLine = [regex]'^PHP_\S* (?:\[(?:"(?:[^"\\]|\\.)*"|[^\]"])*\] )?(?<path>.*)$'
    # string line: "0xOFFSET:LENGTH:$id: <matched text>"
    $stringLine = [regex]':\$(?:ver|pv|cfg_ver|hdr_ver): '
    $version = [regex]'[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+~_-]*'

    $results = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
    $seen = New-Object -TypeName 'System.Collections.Generic.List[string]'
    $versioned = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::Ordinal)
    $file = $null

    $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $RawPath, $Utf8NoBom
    try
    {
        while ($null -ne ($line = $reader.ReadLine()))
        {
            $m = $ruleLine.Match($line)
            if ($m.Success)
            {
                $file = $m.Groups['path'].Value
                $seen.Add($file)
                continue
            }
            if ($null -ne $file -and $stringLine.IsMatch($line))
            {
                # UTF-16 matches ($pv) are printed with escaped NULs: 8\x00.\x002\x00...
                $text = $line.Replace('\x00', '')
                $space = $text.IndexOf(' ')
                $text = $text.Substring($space + 1)
                $v = $version.Match($text)
                if ($v.Success)
                {
                    [void]$results.Add("$file`t$($v.Value)")
                    [void]$versioned.Add($file)
                }
            }
        }
    }
    finally
    {
        $reader.Dispose()
    }
    foreach ($f in $seen)
    {
        if (-not $versioned.Contains($f)) { [void]$results.Add("$f`tunknown") }
    }
    $sorted = [string[]]@($results)
    [System.Array]::Sort($sorted, [System.StringComparer]::Ordinal)
    return , $sorted
}

function Invoke-Main
{
    # Takes the script's parameters explicitly (dot-sourced tests call it the
    # same way) and returns the exit code
    param(
        [string[]]$Path,
        [string]$OutputDir,
        [string]$Format,
        [switch]$KeepBinary,
        [string]$YaraXArchive,
        [string]$MaxMB,
        [string]$Threads = '2',
        [string[]]$ExcludePath,
        [switch]$IncludeSystemPaths,
        [switch]$IncludeNonBinary,
        [switch]$IncludeCloudFiles,
        [switch]$Help,
        [string[]]$ExtraArgs
    )

    if ($Help)
    {
        Get-Help -Name $PSCommandPath -Full | Out-String | Write-Host
        return 0
    }

    # ---- options --------------------------------------------------------------
    # powershell.exe -File can't pass arrays ("-Path A,B" arrives as one string),
    # so extra arguments that aren't options are more targets: -Path A B
    $allPaths = @($Path | Where-Object { $_ })
    $extra = @($ExtraArgs | Where-Object { $_ })
    foreach ($extraArg in $extra)
    {
        if ($extraArg.StartsWith('-'))
        {
            Write-UsageError "Unknown argument: $extraArg (see -Help)"
            return 2
        }
        $allPaths += $extraArg
    }
    $Format = $Format.ToLowerInvariant()
    if ($Format -notin @('text', 'json', 'ndjson'))
    {
        Write-UsageError "Invalid -Format '$Format' (use text, json or ndjson)."
        return 2
    }
    if ($MaxMB -notmatch '^[0-9]{1,7}$')
    {
        Write-UsageError "Invalid -MaxMB '$MaxMB' (whole number of MB, 0 = no limit)."
        return 2
    }
    $maxBytes = [long]$MaxMB * 1MB
    if ($Threads -notmatch '^[0-9]{1,3}$' -or [int]$Threads -lt 1)
    {
        Write-UsageError "Invalid -Threads '$Threads' (number of threads, 1 or more)."
        return 2
    }

    if (-not (Test-IsWindowsHost))
    {
        Write-UsageError 'This script is for Windows only (see bash/ for macOS and Linux).'
        return 2
    }

    $targets = @()
    if ($allPaths.Count -gt 0)
    {
        foreach ($p in $allPaths)
        {
            if (-not (Test-Path -LiteralPath $p))
            {
                Write-UsageError "Target path does not exist: $p"
                return 2
            }
            # Full provider path; trailing separator kept only on a drive root
            $full = (Resolve-Path -LiteralPath $p).ProviderPath
            if ($full -ne [System.IO.Path]::GetPathRoot($full)) { $full = $full.TrimEnd('\', '/') }
            $targets += $full
        }
    }
    else
    {
        $targets = @(Get-FixedDriveRoot)
        if ($targets.Count -eq 0)
        {
            Write-UsageError 'No local fixed drives found.'
            return 2
        }
    }

    # ---- output files ---------------------------------------------------------
    if (-not (Test-Path -LiteralPath $OutputDir -PathType Container))
    {
        $null = New-Item -Path $OutputDir -ItemType Directory -Force
    }
    $OutputDir = (Resolve-Path -LiteralPath $OutputDir).ProviderPath
    $hostName = [System.Environment]::MachineName
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $resultBase = Join-Path -Path $OutputDir -ChildPath "yara_results_${hostName}_$timestamp"
    $summaryFile = $null
    if ($Format -eq 'text')
    {
        $resultFile = "$resultBase.raw.text"
        $summaryFile = "$resultBase.text"
    }
    else
    {
        $resultFile = "$resultBase.$Format"
    }
    $logFile = Join-Path -Path $OutputDir -ChildPath "yara_scan_${hostName}_$timestamp.log"

    $workDir = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ('yara_x_scan_' + [guid]::NewGuid().ToString('N'))
    $null = New-Item -Path $workDir -ItemType Directory -Force
    $logWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $logFile, $false, $Utf8NoBom
    try
    {
        # ---- download, verify, unpack -------------------------------------------
        try
        {
            $yr = Get-YaraX -WorkDir $workDir -ArchivePath $YaraXArchive
            $yrVersion = (& $yr --version 2>&1 | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) { throw "yr --version failed: $yrVersion" }
            Write-ScanLog "Unpacked $yrVersion"
        }
        catch
        {
            Write-ScanLog "ERROR: $($_.Exception.Message)"
            return 3
        }

        $ruleFile = Join-Path -Path $workDir -ChildPath 'embedded_rule.yar'
        [System.IO.File]::WriteAllText($ruleFile, $EmbeddedRule, $Utf8NoBom)

        # ---- build list of files to scan ------------------------------------------
        # Unattended background scan: the file walk (this process) runs at
        # BelowNormal like yr.exe (see Invoke-NativeToFile). Best effort.
        try { [System.Diagnostics.Process]::GetCurrentProcess().PriorityClass = [System.Diagnostics.ProcessPriorityClass]::BelowNormal } catch { $null = $_ }
        if (-not (Test-IsAdministrator))
        {
            Write-Warning 'Not running as Administrator - protected folders will be skipped (see log)'
        }

        $skipExt = $null
        if (-not $IncludeNonBinary)
        {
            $skipExt = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([string[]]$NonBinaryExtensions), ([System.StringComparer]::OrdinalIgnoreCase)
            Write-ScanLog 'Skipping non-executable file types (use -IncludeNonBinary to include)'
        }
        if (-not $IncludeCloudFiles)
        {
            Write-ScanLog 'Skipping online-only cloud files (use -IncludeCloudFiles to include)'
        }
        if ($maxBytes -gt 0)
        {
            Write-ScanLog "Skipping files of $MaxMB MB or more (use -MaxMB 0 to include)"
        }
        if (-not $IncludeSystemPaths)
        {
            Write-ScanLog "Skipping system folders: $($SystemSkipDirs -join ', ') (use -IncludeSystemPaths to include)"
        }
        # powershell.exe -File passes "A,B" as one string, so split on commas here
        $excludeDirs = @()
        foreach ($x in @($ExcludePath | Where-Object { $_ } | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ }))
        {
            if (-not (Test-Path -LiteralPath $x -PathType Container))
            {
                Write-ScanLog "WARNING: -ExcludePath folder not found, ignored: $x"
                continue
            }
            $excludeDirs += (Resolve-Path -LiteralPath $x).ProviderPath.TrimEnd('\', '/')
        }

        $scanList = Join-Path -Path $workDir -ChildPath 'scan_list.txt'
        $listWriter = New-Object -TypeName System.IO.StreamWriter -ArgumentList $scanList, $false, $Utf8NoBom
        $listWriter.NewLine = "`n"
        $totals = @{ Listed = 0L; SizeSkipped = 0L; ExtSkipped = 0L; EmptySkipped = 0L; CloudSkipped = 0L; LinksSkipped = 0L; Errors = 0L }
        try
        {
            foreach ($target in $targets)
            {
                # An explicitly named file is always scanned
                if (Test-Path -LiteralPath $target -PathType Leaf)
                {
                    $listWriter.WriteLine($target)
                    $totals.Listed++
                    continue
                }

                # Never scan our own output (old results contain matched strings) or temp folder
                $skipDirs = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($d in @($OutputDir, $workDir.TrimEnd('\', '/')))
                {
                    if (-not (Test-PathWithin -Child $target -Parent $d)) { [void]$skipDirs.Add($d) }
                }
                foreach ($d in $excludeDirs)
                {
                    if (Test-PathWithin -Child $target -Parent $d) { Write-ScanLog "Not skipping $d (-ExcludePath): it contains $target" }
                    else { [void]$skipDirs.Add($d); Write-ScanLog "Skipping $d (-ExcludePath)" }
                }
                $skipRootFiles = $null
                if (-not $IncludeSystemPaths)
                {
                    $root = [System.IO.Path]::GetPathRoot($target)
                    foreach ($rel in $SystemSkipDirs)
                    {
                        $d = Join-Path -Path $root -ChildPath $rel
                        # A skip whose folder contains the target is turned off
                        if (-not (Test-PathWithin -Child $target -Parent $d)) { [void]$skipDirs.Add($d) }
                    }
                    $skipRootFiles = New-Object -TypeName 'System.Collections.Generic.HashSet[string]' -ArgumentList ([string[]]$SystemSkipFiles), ([System.StringComparer]::OrdinalIgnoreCase)
                }

                Write-ScanLog "Listing files under $target"
                $stats = Get-ScanFile -Root $target -ListWriter $listWriter -LogWriter $logWriter `
                    -SkipDirs $skipDirs -SkipRootFiles $skipRootFiles -SkipExtensions $skipExt `
                    -MaxBytes $maxBytes -SkipCloud (-not $IncludeCloudFiles)
                foreach ($k in @($totals.Keys)) { $totals[$k] += $stats.$k }
            }
        }
        finally
        {
            $listWriter.Dispose()
        }

        if ($totals.Errors -gt 0) { Write-ScanLog "$($totals.Errors) folder(s) could not be listed (see $logFile)" }
        if ($totals.LinksSkipped -gt 0) { Write-ScanLog "Did not follow $($totals.LinksSkipped) junction(s)/symlink(s)" }
        if ($totals.CloudSkipped -gt 0) { Write-ScanLog "Skipped $($totals.CloudSkipped) online-only cloud file(s)/folder(s)" }
        if ($totals.SizeSkipped -gt 0) { Write-ScanLog "Skipped $($totals.SizeSkipped) file(s) of $MaxMB MB or more (listed in $logFile)" }
        if ($null -ne $skipExt) { Write-ScanLog "Skipped $($totals.ExtSkipped) non-executable file type(s)" }
        if ($totals.EmptySkipped -gt 0) { Write-ScanLog "Skipped $($totals.EmptySkipped) empty file(s)" }
        Write-ScanLog "Found $($totals.Listed) file(s) to scan"

        # ---- scan -----------------------------------------------------------------
        Write-ScanLog "Scanning with $Threads thread(s) at low priority..."
        Write-ScanLog "Results: $resultFile"
        try
        {
            $scan = Invoke-NativeToFile -FilePath $yr -StdoutPath $resultFile -Arguments @(
                'scan', '--scan-list', '--print-meta', '--print-strings', '--threads', $Threads,
                '--output-format', $Format, $ruleFile, $scanList)
        }
        catch
        {
            Write-ScanLog "ERROR: could not run yr: $($_.Exception.Message)"
            return 4
        }
        # yr reports per-file errors (e.g. access denied, locked files) on stderr,
        # still scans the rest and exits 0; non-zero means the scan itself failed
        if ($scan.Stderr) { $logWriter.Write($scan.Stderr) }
        if ($scan.ExitCode -ne 0)
        {
            Write-ScanLog "ERROR: yr exited with code $($scan.ExitCode) (see $logFile)"
            return 4
        }

        if ($null -ne $summaryFile)
        {
            $lines = ConvertTo-PhpVersionSummary -RawPath $resultFile
            [System.IO.File]::WriteAllLines($summaryFile, $lines, $Utf8NoBom)
            Write-ScanLog "Versions: $summaryFile ($($lines.Count) path(s))"
        }

        if ($KeepBinary)
        {
            $keepDir = Join-Path -Path $OutputDir -ChildPath 'bin'
            $null = New-Item -Path $keepDir -ItemType Directory -Force
            Copy-Item -LiteralPath $yr -Destination (Join-Path -Path $keepDir -ChildPath 'yr.exe') -Force
            Write-ScanLog "Kept yr binary at $(Join-Path -Path $keepDir -ChildPath 'yr.exe')"
        }

        # Any output in text/ndjson mode means at least one match; json always prints an object
        if ($Format -eq 'json')
        {
            $matched = [bool](Select-String -LiteralPath $resultFile -Pattern '"rule"' -SimpleMatch -Quiet)
        }
        else
        {
            $matched = (Get-Item -LiteralPath $resultFile).Length -gt 0
        }
        if ($matched)
        {
            Write-ScanLog "MATCHES FOUND - see $resultFile"
            return 1
        }
        Write-ScanLog 'No matches.'
        return 0
    }
    finally
    {
        $logWriter.Dispose()
        $logItem = Get-Item -LiteralPath $logFile -ErrorAction SilentlyContinue
        if ($null -ne $logItem)
        {
            if ($logItem.Length -eq 0)
            {
                Remove-Item -LiteralPath $logFile -Force
            }
            else
            {
                $lineCount = @(Get-Content -LiteralPath $logFile).Count
                Write-ScanLog "$lineCount skip/warning/error line(s) in $logFile"
            }
        }
        Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Dot-sourcing (". .\yara_x_scan_windows.ps1") only loads the functions, for testing
if ($MyInvocation.InvocationName -ne '.')
{
    $mainArgs = @{
        Path               = $Path
        OutputDir          = $OutputDir
        Format             = $Format
        KeepBinary         = $KeepBinary
        YaraXArchive       = $YaraXArchive
        MaxMB              = $MaxMB
        Threads            = $Threads
        ExcludePath        = $ExcludePath
        IncludeSystemPaths = $IncludeSystemPaths
        IncludeNonBinary   = $IncludeNonBinary
        IncludeCloudFiles  = $IncludeCloudFiles
        Help               = $Help
        ExtraArgs          = $ExtraArgs
    }
    exit (Invoke-Main @mainArgs)
}
