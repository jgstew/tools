/*
  Node.js install detection + version, all OSes (Linux ELF, Windows PE, macOS Mach-O).

  Finds standalone node / node.exe, distro libnode, and Node embedded in other
  software (Electron, single-executable applications, vercel/pkg, apps that
  bundle libnode). Deliberately broad: Node_Binary_Broad flags anything that
  looks Node-related so nothing is missed; the other rules carry the exact
  version string. Run with `yara -s` (or `yr scan -s`) to print the matched
  version text.

  Rules:
    Node_Runtime_Version  - Node runtime or a runtime embedding Node; $ver holds
                            the exact version (node.js/v22.23.4), or for pkg
                            builds with no inspector $rel (the release URL)
    Node_Electron_Version - Electron framework; $electron holds Electron's
                            version, $ver the embedded Node version (none
                            in very old Electron, around 2.x)
    Node_Binary_Broad     - catch-all: any executable with any Node marker,
                            incl. native addons (.node) and the distro node
                            launchers that load libnode

  Bun is not detected and not excluded: Bun-compiled executables match only
  Node_Binary_Broad (an accepted false positive, reported with no version).

  No modules are imported so the rules also work in embedded YARA engines
  (osquery, EDRs) that are built without the pe/elf/macho modules.

  See README.md for tested samples and the ABI number -> Node major table.
*/

// Condition copied from is_executable.yar by sync_rules.py - edit it there
private rule Node_Detect_IsExecutable
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

rule Node_Runtime_Version
{
  meta:
    description = "Node.js runtime (node, node.exe, libnode, or a runtime embedding Node: Electron, SEA, pkg); $ver = exact Node version"
    confidence = "high"
  strings:
    // Inspector /json/version "Browser" value: "node.js/" NODE_VERSION. In
    // every official build 8.17.0-25.9.0, distro libnode, Electron and SEA.
    // A suffix only after "-" (-rc.1, -nightly...): the compiler can merge the
    // literal with the next string (linux-x64 24.22.1: "v24.22.1Protocol-...")
    $ver = /node\.js\/v[0-9]{1,2}\.[0-9]{1,3}\.[0-9]{1,3}(-[0-9A-Za-z.]{1,20})?/
    // process.release.sourceUrl / headersUrl. Also in Bun (Node compatibility),
    // so it only counts together with the NODE_MODULE ABI symbol, which Bun
    // lacks; needed for vercel/pkg builds, which have no inspector string.
    // No "not Bun" exclusion: it could hide a real Node binary whose embedded
    // JavaScript mentions Bun.
    $rel = /https:\/\/nodejs\.org\/download\/release\/v[0-9]{1,2}\.[0-9]{1,3}\.[0-9]{1,3}/
    // NODE_MODULE registration symbol, ABI = NODE_MODULE_VERSION (10.x and later)
    $abi = /node_register_module_v[0-9]{2,3}/
  condition:
    Node_Detect_IsExecutable and ($ver or ($rel and $abi))
}

rule Node_Electron_Version
{
  meta:
    description = "Electron framework (embeds Node.js); $electron = Electron version, $ver = embedded Node version"
    confidence = "high"
  strings:
    // Electron user agent. Both keep a "-" suffix (31.0.0-nightly.20240101), the
    // same as Node_Runtime_Version's $ver, so one file gives one node version
    $electron = /Electron\/[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(-[0-9A-Za-z.]{1,20})?/
    $ver = /node\.js\/v[0-9]{1,2}\.[0-9]{1,3}\.[0-9]{1,3}(-[0-9A-Za-z.]{1,20})?/
    // Old Electron (2.x) has no node.js/v, only the NODE_MODULE registration
    // function; it is then reported by its Electron version alone
    $reg = "node_module_register"
  condition:
    Node_Detect_IsExecutable and $electron and ($ver or $reg)
}

rule Node_Binary_Broad
{
  meta:
    description = "Broad catch-all: Node runtime, libnode launcher, or native addon (.node)"
    confidence = "medium"
  strings:
    $ver    = "node.js/v"
    $rel    = "https://nodejs.org/download/release/v"
    $abi    = /node_register_module_v[0-9]{2,3}/   // NODE_MODULE ABI, also in addons
    $napi   = "napi_register_module_v1"              // N-API addon export
    $napiim = "napi_module_register"                 // N-API addon import
    $start  = "_ZN4node5StartEiPPc"                  // distro launcher importing node::Start from libnode
    $reg    = "node_module_register"                 // NODE_MODULE: legacy (non-N-API) addons, old runtimes
  condition:
    // Also matches Bun-compiled executables (release URL, N-API): an accepted
    // false positive, reported as "node unknown"
    Node_Detect_IsExecutable and any of them
}
