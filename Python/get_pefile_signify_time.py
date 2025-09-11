"""
Get the time a windows binary was signed.

Related:
- https://stackoverflow.com/a/72520692/861745
"""

from signify.authenticode.signed_pe import SignedPEFile

pathname = r"C:\Windows\explorer.exe"
# pathname = r"VirtualBox-Win.exe"

with open(pathname, "rb") as f:
    pefile = SignedPEFile(f)

    print("first signature timestamp:")
    print(list(pefile.signed_datas)[0].signer_infos[0].countersigner.signing_time)

    sig_times = []

    print("all signature times: (most files only have 1)")
    for data in list(pefile.signed_datas):
        for infos in data.signer_infos:
            sig_time = infos.countersigner.signing_time
            sig_times.append(sig_time)
            print(sig_time)

    print("maximum signature timestamp:")
    print(max(sig_times))
