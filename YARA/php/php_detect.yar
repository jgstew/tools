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
