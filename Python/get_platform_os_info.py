"""
Get system info

Want to get the right asset from here:
https://github.com/sassoftware/relic/releases/tag/v7.4.0

relic-client-darwin
relic-client-linux-amd64
relic-client-linux-arm64
relic-client-linux-ppc64le
relic-client-windows-amd64.exe

Example RegEx:
(?i)relic-client-%platform_system%(-%platform_machine%|(?!-))
"""

import platform
import sys


# https://github.com/autopkg/autopkg/blob/8f2de997860ee591c0f0628190d0b67826fb2fec/Code/autopkglib/__init__.py#L45-L47
print(sys.platform.lower())

# https://stackoverflow.com/a/7491509/861745
print(platform.uname())
print(platform.machine().lower())

prefix = "relic-client-"
file_ext = ""
sys_platform = sys.platform.lower()
platform_machine = platform.machine().lower()
platform_system = platform.system().lower()

if "win32" in sys_platform:
    # sys_platform = "windows"
    file_ext = ".exe"

if "darwin" in platform_system:
    print(f"{prefix}darwin")
else:
    print(f"{prefix}{platform_system}-{platform_machine}{file_ext}")
