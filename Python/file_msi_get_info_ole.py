#!/usr/bin/env python3
"""
Parse MSI file for info

Related:
- https://github.com/decalage2/oletools/blob/master/oletools/olemeta.py
- https://github.com/ralphje/signify/issues/24#issuecomment-1148320566
"""
import olefile
import os

import signify.authenticode.structures
import signify.pkcs7.signeddata
import sys

# from signify.authenticode.signed_pe import SignedPEFile


def main(pathname):
    # Check file exists:
    if not os.path.exists(pathname):
        raise FileNotFoundError(pathname)

    ole = olefile.OleFileIO(pathname)

    meta = ole.get_metadata()

    for prop in meta.SUMMARY_ATTRIBS:
        value = getattr(meta, prop)
        print((prop, value))

    # get raw info:
    # other_props = ole.getproperties("\x05SummaryInformation")
    # for item in other_props.values():
    #     print(item)

    if not ole.exists("\x05DigitalSignature"):
        print("WARNING: File not signed!")
    else:
        with ole.openstream("\x05DigitalSignature") as fh:
            b_data = fh.read()
            # print(f"DigitalSignature: {len(b_data)} bytes")
            # signed_data = (
            #     signify.authenticode.structures.AuthenticodeSignedData.from_envelope(
            #         b_data
            #     )
            # )
            signed_data_pkcs7 = signify.pkcs7.signeddata.SignedData(b_data)
            print(signed_data_pkcs7)
            # print(signed_data.explain_verify())

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
