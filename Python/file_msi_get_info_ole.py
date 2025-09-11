#!/usr/bin/env python3
"""
Parse MSI file for info

Related:
- https://github.com/decalage2/oletools/blob/master/oletools/olemeta.py
- https://github.com/ralphje/signify/issues/24#issuecomment-1148320566
"""

import os
import sys

import olefile


def main(pathname):
    # Check file exists:
    if not os.path.exists(pathname):
        raise FileNotFoundError(pathname)

    ole = olefile.OleFileIO(pathname)

    meta = ole.get_metadata()

    for prop in meta.SUMMARY_ATTRIBS:
        value = getattr(meta, prop)
        print((prop, value))
    # print(meta.dump())

    create_time = getattr(meta, "create_time")
    last_saved_time = getattr(meta, "last_saved_time")
    dates_to_compare = []
    dates_to_compare.append(create_time)
    dates_to_compare.append(last_saved_time)
    max_time = max(dates_to_compare)
    # print(max_time)
    max_time_yyyymmdd = max_time.strftime("%Y-%m-%d")
    print(f"Max Mod Time: {max_time_yyyymmdd}")

    # get raw info:
    # other_props = ole.getproperties("\x05SummaryInformation")
    # for item in other_props.values():
    #     print(item)

    if not ole.exists("\x05DigitalSignature"):
        print("WARNING: File not signed!")
    else:
        with ole.openstream("\x05DigitalSignature") as fh:
            sig_data = fh.read()
            print(f"Digital Signature: {len(sig_data)} bytes")

    # end:
    ole.close()


# if called directly, then run this example:
if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1]))
    except IndexError:
        # using https://github.com/PowerShell/PowerShell/releases/download/v7.2.5/PowerShell-7.2.5-win-x64.msi
        EXAMPLE_PATH = r"Python\test.msi"
        sys.exit(main(EXAMPLE_PATH))
