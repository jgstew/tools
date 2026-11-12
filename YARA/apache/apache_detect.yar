/*
  Apache HTTP Server (httpd) + mod_http2 detection + version, all OSes (Linux
  ELF, Windows PE, macOS Mach-O).

  Signatures based on jeffschafer's Apache mod_http2 scanner. Run with
  `yara -s` (or `yr scan -s`) to print the matched version text.

  Rules:
    Apache_HTTPD_Version - the file holding the httpd core: httpd on Linux and
                           macOS, libhttpd.dll on Windows (httpd.exe is a small
                           launcher); $ver holds the exact version (Apache/2.4.67)
    Apache_HTTP2_Module  - mod_http2 (mod_http2.so, or httpd with it built in);
                           $_module_ver is a candidate module version only

  No modules are imported so the rules also work in embedded YARA engines
  (osquery, EDRs) that are built without the pe/elf/macho modules.
*/

// Condition copied from is_executable.yar by sync_rules.py - edit it there
private rule Apache_Detect_IsExecutable
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

rule Apache_HTTPD_Version
{
  meta:
    description = "Apache httpd core (httpd, libhttpd.dll); $ver = server version"
    confidence = "high"
  strings:
    // AP_SERVER_BASEVERSION ("Apache" "/" AP_SERVER_BASEREVISION), one literal
    // in the core. Also in other software (user agent lists, proxies), so it
    // only counts together with a $core marker. Modules built against httpd
    // (mod_ssl, mod_proxy) have it too.
    $ver = /Apache\/2\.[0-9]{1,2}\.[0-9]{1,3}/
    // Only in the core: the directive name from its command table, and its
    // error message when the host name can't be resolved (AH00558 in 2.4).
    // The directive name as a whole C string: mod_security2 has "ServerTokens"
    // in a message, and "ModSecurity for Apache/2.9.7" matches $ver
    $core1 = "\x00ServerTokens\x00"
    $core2 = "Could not reliably determine the server's fully qualified domain name"
  condition:
    Apache_Detect_IsExecutable and $ver and any of ($core*)
}

rule Apache_HTTP2_Module
{
  meta:
    description = "Apache mod_http2; $_module_ver = candidate module version"
    confidence = "high"
  strings:
    // Not "http2_module": it is also inside mod_proxy_http2's proxy_http2_module
    $module_identity = "mod_http2_init_counter"
    $module_log = "mod_http2 (v%s, feats="
    // MOD_HTTP2_VERSION as a bare C string, reported as the mod_http2 version.
    // Candidate evidence only: any bare "2.x.y" string matches, and the same
    // mod_http2 version ships with several httpd releases. Optional - the
    // leading "_" lets it go unused in the condition while `-s` still prints it.
    // A suffix only after "-": RHEL's separate mod_http2 package has "2.0.26-git"
    $_module_ver = /\x002\.[0-9]\.[0-9]{1,3}(-[0-9A-Za-z.]{1,20})?\x00/
  condition:
    Apache_Detect_IsExecutable and
    ($module_identity or $module_log)
}
