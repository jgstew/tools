"""
Check if file is authenticode signed and valid

Related:
- https://stackoverflow.com/questions/34951975/digital-signature-signing-time
"""

import sys

# pip install signify
from signify.authenticode.signed_pe import SignedPEFile


def main(pathname):
    # print("main()")
    with open(pathname, "rb") as f:
        pefile = SignedPEFile(f)
        print(list(pefile.signed_datas)[0].signer_infos[0].countersigner.signing_time)
        print(pefile.explain_verify())
        # print(pefile.signed_datas)
        signed_datas = list(pefile.signed_datas)
        print(signed_datas[0].signer_infos[0].more_info)
        # this returns None:
        print(signed_datas[0].signer_infos[0].signing_time)
        # this returns what I'm looking for:
        print("Signing Time: ")
        print(signed_datas[0].signer_infos[0].countersigner.signing_time)


# if called directly, then run this example:
if __name__ == "__main__":
    try:
        sys.exit(main(sys.argv[1]))
    except IndexError:
        EXAMPLE_PATH = r"C:\Windows\explorer.exe"
        sys.exit(main(EXAMPLE_PATH))
