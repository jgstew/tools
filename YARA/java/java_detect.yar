/*
  Java runtime (JRE / JDK) detection + version and vendor, all OSes.

  Based on java_detect.yar from bigfix/Site_Rapid_Response PR #15. Run with
  `yara -s` (or `yr scan -s`) to print the matched version text.

  Rules:
    Java_Runtime_Version - the JDK/JRE "release" file (JAVA_VERSION=...), or,
                           for IBM Semeru / OpenJ9 Java 8 runtimes that ship no
                           release file, the j9vmNN library; $ver holds the
                           version

  Unlike the PHP, Node.js and Apache rules, the anchor is a small text file
  (release), not an executable, so the rule is gated on "small file OR
  executable" rather than on the executable header alone:
    - an is_executable gate on its own misses every JDK/JRE that has a
      release file (measured: a Microsoft OpenJDK 21 on Windows Server 2022
      went undetected)
    - with no gate the patterns are searched in every file the scan opens,
      which cost +29% (Windows) to +36-52% (macOS) scan time over the PHP,
      Node.js and Apache rules alone, and also reported the same install
      several times (lib/modules, bin/server/classes*.jsa)
    - "filesize < 16KB or executable" found the same installs, one row each,
      at +4-20% on macOS (release files are about 1-2 KB)

  Semeru / OpenJ9 Java 8 hits give the Java level only (1.8.0), never the
  update: the VM fills that in at run time. Expect two rows per install
  (bin/default and bin/compressedrefs). Inspect those by hand for the patch
  level.

  No modules are imported so the rules also work in embedded YARA engines
  (osquery, EDRs) that are built without the pe/elf/macho modules.
*/

// Condition copied from is_executable.yar. sync_rules.py does not copy it here
// yet, so keep it in step with is_executable.yar by hand
private rule Java_Detect_IsExecutable
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

rule Java_Runtime_Version
{
  meta:
    description = "Java runtime (JDK/JRE release file, or OpenJ9 j9vm library); $ver = Java version"
    confidence = "high"
  strings:
    // Modern 9+ and legacy 1.6-1.8 versions in one pattern, named $ver so
    // versions.awk reads the version from it. JAVA_VERSION is the release
    // file spelling (a modern release file has no lowercase form);
    // java.runtime.version is the runtime system property.
    // JAVA_RUNTIME_VERSION is deliberately not listed: it matches next to
    // JAVA_VERSION (every install would report twice) and its value is cut at
    // the first dot of a distro suffix (Ubuntu's
    // 11.0.33+9-post-1ubuntu1-22.04.1-Ubuntu came out as ...-1ubuntu1-22).
    // The trailing "JRE 1.x.0" branch is the banner template in OpenJ9's
    // j9vmNN library (Semeru Java 8, no release file); it has no keyword of
    // its own, so it relies on the vendor half of the condition.
    $ver = /(openjdk|java\.runtime\.version|JAVA_VERSION|Java\(TM\) SE Runtime Environment)[=:\s"]+((9|[12][0-9])\.[0-9]+\.[0-9]+([+._-][0-9A-Za-z-]+)?|1\.[6-8]\.0_[0-9]+(-[0-9A-Za-z-]+)?)|JRE 1\.[6-8]\.0/ ascii wide
    // Vendor properties. BUILD_TYPE is here because Oracle 6/7/8 release files
    // have no vendor key at all (no IMPLEMENTOR, no java.vendor, no "Oracle
    // Corporation"); BUILD_TYPE="commercial" is an Oracle build marker that
    // OpenJDK release files don't have
    $vendor_prop = /(java\.vendor|java\.vm\.vendor|IMPLEMENTOR|BUILD_TYPE)[=:\s"]+[A-Za-z0-9 ._(),-]{3,50}/ ascii wide
    // Distribution names
    $vendor_oracle    = "Oracle Corporation" ascii wide
    $vendor_sun       = "Sun Microsystems Inc." ascii wide
    $vendor_temurin   = /Eclipse Adoptium|Temurin-[0-9.+_-]+/ ascii wide
    $vendor_adopt     = /AdoptOpenJDK(-[0-9.+_-]+)?/ ascii wide
    $vendor_corretto  = /Amazon\.com Inc\.|Corretto-[0-9.]+/ ascii wide
    $vendor_zulu      = /Azul Systems|Zulu[0-9]{1,2}\.[0-9.+_-]+/ ascii wide
    $vendor_ibm       = /IBM Corporation|IBM J9 VM|Semeru/ ascii wide
    $vendor_microsoft = /Microsoft-[0-9.+_-]+/ ascii wide
    $vendor_redhat    = "Red Hat, Inc." ascii wide
    $vendor_sap       = /SAP SE|SapMachine/ ascii wide
    $vendor_bellsoft  = /BellSoft|Liberica/ ascii wide
  condition:
    // A release file is about 1-2 KB; the j9vm library passes the header check
    (filesize < 16KB or Java_Detect_IsExecutable) and
    $ver and any of ($vendor_*)
}
