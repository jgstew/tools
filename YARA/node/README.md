# YARA: Node.js install detection + version

Find every Node.js runtime on a machine and report its exact version, on Linux,
Windows and macOS - **without running Node**. Covers standalone `node` /
`node.exe`, distro `libnode`, and Node embedded in other software: Electron
apps (with the Electron version too), single-executable applications (SEA),
vercel/pkg builds and apps that bundle `libnode`.

Embedded runtimes are the point: end-of-life Node (8.x, 15.x, 16.x, 18.x) turns
up inside third-party apps, where a check for a `node` on `PATH` finds nothing.

The header check, `sync_rules.py`, the summary filter (`versions.awk`), the scan
scripts and the BigFix content are shared with the PHP rules: see
[../README.md](../README.md). The scan scripts look for PHP and Node.js in one
pass.

## Files

| File | What it's for |
|---|---|
| `node_detect.yar` | The rules. Detects Node.js and carries the **exact version** in the matched string (`yara -s`). Its `Node_Detect_IsExecutable` is copied from `../is_executable.yar` by `../sync_rules.py`. |

## Rules in `node_detect.yar`

| Rule | Confidence | Matches | Version from |
|---|---|---|---|
| `Node_Runtime_Version` | high | `node`, `node.exe`, `libnode.so*` / `libnode*.dylib`, and runtimes embedding Node: Electron, SEA, vercel/pkg | `$ver` = `node.js/v<version>`; vercel/pkg builds have no `$ver`, so `$rel` (the release URL), which only counts together with the ABI symbol `$abi` |
| `Node_Electron_Version` | high | Electron framework (embeds Node) | `$electron` = `Electron/<version>`, `$ver` = the embedded Node version |
| `Node_Binary_Broad` | medium | Catch-all: any ELF/PE/Mach-O with any Node marker. Includes native addons (`.node`), the distro `node` launchers that load `libnode`, and Bun-compiled executables. | - (`node unknown` in the summary; the ABI table below gives an addon's Node major) |

Every rule is gated on the shared executable header check, see
[../README.md](../README.md#executable-header-check). The `.node` extension is
not skipped by the scan scripts, so addons and runtimes named `*.node` are
scanned.

## Signatures

Taken from real binaries: official nodejs.org builds checked against each
release's `SHASUMS256.txt`, distro packages and installed apps (see
[Tested](#tested)).

| Marker | Where | Present in |
|---|---|---|
| `node.js/v<version>` | Inspector `/json/version` "Browser" value (`"node.js/" NODE_VERSION`) | **every** official build 8.17.0-25.9.0 (all platforms), every distro `libnode`, Alpine/musl, Electron, Node SEA. Usually one copy per binary, two in some (e.g. linux-x64 24.22.1, universal binaries). |
| `https://nodejs.org/download/release/v<version>/...` | `process.release.sourceUrl` / `headersUrl` | every sample above, **and** vercel/pkg builds (which have no inspector string), **but also Bun** (Node-compatibility shim) |
| `node_register_module_v<ABI>` | `NODE_MODULE` registration symbol (ABI = `NODE_MODULE_VERSION`) | every Node build from 10.x on, and pkg; **not** in 8.17.0 or Bun. Also in native addons. |
| `napi_register_module_v1` / `napi_module_register` | N-API addon export / import | Node itself and native `.node` addons. Also in Bun. |
| `_ZN4node5StartEiPPc` | import of `node::Start` | the small distro/Homebrew `node` launchers that load `libnode` (the version lives in `libnode`) |
| `Electron/<version>` | Electron user agent | Electron Framework (together with `node.js/v<embedded node>`) |
| PE `CompanyName`/`ProductName` = `Node.js`, `ProductVersion` | Windows version resource | official `node.exe`. Not used: `node.js/v` is always there too. |

Two findings shaped the rules:

1. **Bun has the nodejs.org release URL but is not Node.** Bun is a separate
   runtime (JavaScriptCore, not V8) with a Node-compatibility layer. A
   Bun-compiled CLI (`bun-v1.4.0`) contains
   `https://nodejs.org/download/release/v26.3.0` and N-API symbols, but neither
   `node.js/v` nor `node_register_module_v`. So the release URL only counts
   together with the ABI symbol, which keeps Bun out of `Node_Runtime_Version`
   without a Bun-specific exclusion.
2. **vercel/pkg builds have no `node.js/v`** (they're built without the
   inspector), but they do have the release URL and the ABI symbol. Requiring
   `node.js/v` alone would miss them.

The `$ver` and `$electron` patterns allow a suffix only after `-` (`-rc.1`,
`-nightly...`): in the official linux-x64 24.22.1 build the compiler merged the
string with the next one (`node.js/v24.22.1Protocol-Version`). Both rules'
`$ver` use the same pattern, so a file gives one `node` version. Electron
pre-releases and vendor builds keep their suffix: GoTo's framework reports
`electron 39.8.8-29`, its `CFBundleVersion`.

## Usage

```bash
yr scan --recursive --print-strings node_detect.yar /opt | awk -f ../versions.awk | sort -u
```

```text
/opt/node/bin/node	node	22.23.4      (illustrative)
/opt/app/addon.node	node	unknown
```

Raw output (VS Code's Electron framework, shortened; it also matches
`Node_Binary_Broad`):

```text
Node_Runtime_Version /Applications/Visual Studio Code.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Electron Framework
0xa9c2d40:16:$ver: node.js/v24.21.0
0x9663af7:44:$rel: https://nodejs.org/download/release/v24.21.0
Node_Electron_Version /Applications/Visual Studio Code.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Electron Framework
0x9f0cdf6:15:$electron: Electron/43.7.7
0xa9c2d40:16:$ver: node.js/v24.21.0
```

To scan for PHP and Node.js in one pass, give `yr` both rule files (or use the
[scan scripts](../README.md#scan-scripts), which do this):

```bash
yr scan --recursive --print-strings ../php/php_detect.yar node_detect.yar /opt | awk -f ../versions.awk | sort -u
```

## `NODE_MODULE_VERSION` (ABI) → Node major

From https://nodejs.org/dist/index.json, plus Homebrew 26.8.1 (`libnode.147`).
Use it for addons, which carry only the ABI number (`node_register_module_v<ABI>`):

| ABI | Node | | ABI | Node |
|---|---|---|---|---|
| 57 | 8 | | 108 | 18 |
| 64 | 10 | | 115 | 20 |
| 72 | 12 | | 127 | 22 |
| 83 | 14 | | 137 | 24 |
| 88 | 15 | | 141 | 25 |
| 93 | 16 | | 147 | 26 |

Electron uses its own ABI numbers (observed 106-149 for Electron 19-44), which
overlap Node's range. So an ABI number alone can't tell Node from Electron,
which is one reason `Node_Electron_Version` checks `Electron/x.y.z`.

## Tested

YARA-X 1.22.0. Every runtime below was detected with the exact version: the
release version for official builds, `node -v` in the distro containers.

| Source | Platforms | Versions |
|---|---|---|
| nodejs.org official builds, SHA256 checked | linux-x64, darwin-arm64, win-x64 | 18.20.8, 20.20.2, 22.23.4, 24.22.1, 25.9.0 |
| nodejs.org official builds, SHA256 checked | linux-x64, win-x64 | 8.17.0, 10.24.1, 12.22.12, 14.21.3, 16.20.2 |
| Debian 12 `nodejs` | Linux aarch64 | 18.20.4 (`libnode.so.108`) |
| Ubuntu 24.04 `nodejs` | Linux aarch64 | 18.19.1 (`libnode.so.109`) |
| Rocky Linux 9 `nodejs` | Linux aarch64 | 16.20.2 (`libnode.so.93`) |
| Alpine 3.20 `nodejs` (musl) | Linux aarch64 | 20.15.1 |
| `node:22-alpine` official image | Linux aarch64 | 22.23.4 |
| Homebrew `node` | macOS arm64 | 26.8.1 (`libnode.147.dylib`) |

- The Debian, Ubuntu and Rocky `node` launchers match only `Node_Binary_Broad`
  (`node::Start` import), reported as `node unknown`; their version comes from
  the `libnode` next to them.
- A Node SEA (GitHub Copilot CLI, 24.16.0) and a vercel/pkg build (16.16.0, from
  `$rel`) were detected with their Node versions.
- The Bun-compiled CLI does not match `Node_Runtime_Version` or
  `Node_Electron_Version`; it matches `Node_Binary_Broad` (`node unknown`).
- No cross-matches: the Node rules gave 0 hits on the PHP samples (Windows
  8.3.35, Linux 8.4.27, macOS 8.5.12), and `php_detect.yar` gave 0 hits on the
  Node samples.
- False-positive sweep on a developer Mac (about 316k pre-filtered files from
  Homebrew, Xcode, Command Line Tools and a projects folder, plus all of
  `/Applications`, about 600k files): every `Node_Runtime_Version` /
  `Node_Electron_Version` hit was a real embedded Node. The `Node_Binary_Broad`
  only hits were native addons (`pty.node`, `fsevents.node`, ...), `libnode`
  launchers and the one Bun-built CLI.
- Combined scan cost (one run, 316k files, 1 thread): PHP rules alone 56.6 s,
  Node rules alone 55.7 s, both in one rule file 56.3 s - no measurable wall
  time over either alone, about 0.2 s more CPU.

Found in the wild on that Mac (Node / Electron / ABI): VMware Fusion
`libnode.dylib` **8.9.3**; Adobe Photoshop / Illustrator / Audition / Media
Encoder 2022-2024 `libnode.dylib` **15.9.0** (ABI 88); Adobe Photoshop 2024
`node` 18.13.0; Adobe Creative Cloud `Creative Cloud Content Manager.node` - a
whole runtime despite the `.node` name - 18.20.2; Microsoft Teams classic
**16.14.2** / Electron 19.1.8; GitHub Desktop 18.18.2 / 28.2.3; Azure Data
Studio 18.15.0 / 25.9.8; VS Code, Docker Desktop and others 24.x / 42-44.

## Limitations

- **Bun / Deno:** not detected, and not excluded. Bun-compiled executables
  appear as `node unknown` through the broad rule (one Bun version, 1.4.0, was
  examined); Bun's claimed Node version (the release URL) is never reported. A
  "not Bun" exclusion was dropped because a real Node SEA or pkg build whose
  JavaScript mentions `Bun v1.2.3` would have been hidden. Deno (Rust + V8 with
  Node compatibility) was not tested.
- **Node built without the inspector *and* without `NODE_MODULE`:** only 8.x and
  older lack the ABI symbol, and every 8.x sample still had `node.js/v`. Such a
  build would only be caught by `Node_Binary_Broad`, without a version.
- **Native addons are noisy.** Every `.node` addon in every `node_modules`
  matches `Node_Binary_Broad` (159 on one Mac). They are kept, like PHP
  extensions; the version rules list the runtimes.
- **Packed/compressed builds** (e.g. UPX) won't match until unpacked, the same
  as PHP.
- **Containers:** Node inside image layers isn't a host install and is skipped
  by default on Linux, the same as PHP.
- **Not tested yet:** Windows apps embedding Node (Electron on Windows, MSIX
  packages), nexe builds, NW.js, Node in `snap` packages, and the official Linux
  arm64 / macOS x64 builds (similar builds were tested: distro arm64 and official
  linux-x64 / darwin-arm64).
