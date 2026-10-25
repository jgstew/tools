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

  No modules are imported so the rules also work in embedded YARA engines
  (osquery, EDRs) that are built without the pe/elf/macho modules.

  See README.md for tested samples and the API number -> branch table.
*/

// Condition copied from is_executable.yar by sync_rules.py - edit it there
private rule PHP_Detect_IsExecutable
{
  condition:
    // ELF executable (2) or shared object (3, also PIE executables); e_type is
    // in the byte order given by EI_DATA (1 = little, 2 = big endian)
    (uint32(0) == 0x464C457F and
      ((uint8(5) == 1 and (uint16(16) == 2 or uint16(16) == 3)) or
       (uint8(5) == 2 and (uint16be(16) == 2 or uint16be(16) == 3))))
    // PE: MZ header whose e_lfanew (0x3C) points at "PE\0\0"
    or (uint16(0) == 0x5A4D and uint32(uint32(0x3C)) == 0x00004550)
    // Mach-O 32/64 execute (2), dylib (6) or bundle (8, e.g. PHP extensions)
    or ((uint32(0) == 0xFEEDFACE or uint32(0) == 0xFEEDFACF) and
        (uint32(12) == 2 or uint32(12) == 6 or uint32(12) == 8))
    // same, byte-swapped (big-endian) Mach-O
    or ((uint32(0) == 0xCEFAEDFE or uint32(0) == 0xCFFAEDFE) and
        (uint32be(12) == 2 or uint32be(12) == 6 or uint32be(12) == 8))
    // Mach-O universal (CAFEBABE) with 1-19 architectures whose first slice
    // passes the thin Mach-O check above, so universal static libraries (.a),
    // object files and dSYMs are rejected. Java .class files also start with
    // CAFEBABE, but bytes 4-7 hold their class version (major >= 45), not an
    // architecture count. The header is big-endian; the first slice's offset
    // is at 16 (fat_arch.offset).
    or (uint32(0) == 0xBEBAFECA and uint32be(4) > 0 and uint32be(4) < 20 and
        (((uint32(uint32be(16)) == 0xFEEDFACE or uint32(uint32be(16)) == 0xFEEDFACF) and
          (uint32(uint32be(16) + 12) == 2 or uint32(uint32be(16) + 12) == 6 or
           uint32(uint32be(16) + 12) == 8)) or
         ((uint32(uint32be(16)) == 0xCEFAEDFE or uint32(uint32be(16)) == 0xCFFAEDFE) and
          (uint32be(uint32be(16) + 12) == 2 or uint32be(uint32be(16) + 12) == 6 or
           uint32be(uint32be(16) + 12) == 8))))
    // same for the rare 64-bit universal header (CAFEBABF): fat_arch_64.offset
    // is 8 bytes at 16; slices sit well below 4 GB, so its low half (20) is used
    or (uint32(0) == 0xBFBAFECA and uint32be(4) > 0 and uint32be(4) < 20 and
        (((uint32(uint32be(20)) == 0xFEEDFACE or uint32(uint32be(20)) == 0xFEEDFACF) and
          (uint32(uint32be(20) + 12) == 2 or uint32(uint32be(20) + 12) == 6 or
           uint32(uint32be(20) + 12) == 8)) or
         ((uint32(uint32be(20)) == 0xCEFAEDFE or uint32(uint32be(20)) == 0xCFFAEDFE) and
          (uint32be(uint32be(20) + 12) == 2 or uint32be(uint32be(20) + 12) == 6 or
           uint32be(uint32be(20) + 12) == 8))))
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
    // A real PE (MZ + PE signature). #pv >= 0 is always true: $pv is only
    // there so -s prints the version
    uint16(0) == 0x5A4D and PHP_Detect_IsExecutable and $pname and #pv >= 0
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
