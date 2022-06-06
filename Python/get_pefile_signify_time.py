from signify.authenticode.signed_pe import SignedPEFile

pathname = r"C:\Windows\explorer.exe"

with open(pathname, "rb") as f:
    pefile = SignedPEFile(f)
    print(list(pefile.signed_datas)[0].signer_infos[0].countersigner.signing_time)
