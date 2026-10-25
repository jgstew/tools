/*
  Executable header check - the source of truth for every IsExecutable rule.

  sync_rules.py copies the condition below into PHP_Detect_IsExecutable
  (php/php_detect.yar), Node_Detect_IsExecutable (node/node_detect.yar), from
  there into the scan scripts, and into PHP_Branch_IsExecutable
  (php/php_version_branches.yar). Edit it here, then run:

      python3 sync_rules.py

  On its own this rule reports the files that pass the check:

      yr scan --recursive is_executable.yar <folder>

  Only fixed-offset reads, no patterns and no modules: YARA-X skips the pattern
  search of a file when this is false, so a large non-executable costs about
  the same as reading its header. Real executables, shared libraries and
  loadable modules (PHP extensions, Node addons) pass; object files, core
  dumps, debug symbols (dSYM) and files that only start with an executable
  magic do not.
*/

rule Is_Executable
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
