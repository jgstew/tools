"""
attempt to read and output smime signature info

This is meant to approximate the output of:
- `openssl cms -in smime.msg -noout -cmsout -print`

but the functionality is not quite the same
"""

import base64

# import binascii

import asn1crypto.cms

# Load the signature from a file
with open("Python\smime.p7s.txt", "rb") as f:
    signed_data = f.read()

# convert base64 smime.p7s to binary
# Decode the base64-encoded data
# skip this step if already binary
signed_data = base64.b64decode(signed_data)

# Load the PKCS#7 message
p7 = asn1crypto.cms.ContentInfo.load(signed_data)

# Get the signature object
signed_data = p7["content"]
signer_infos = signed_data["signer_infos"]

# # Print the signer's certificate
# signer_cert = signer_infos[0]["sid"].chosen
# print("Signer's certificate:")
# print(binascii.hexlify(signer_cert.dump()).decode())

# # Print the signature value
# signature_value = signer_infos[0]["signature"].native
# print("Signature value:")
# print(binascii.hexlify(signature_value).decode())

# # print everything:
# print(signer_infos.native)

print("Number of signatures :", len(signer_infos))

for signer_info in signer_infos:
    # Print the signature algorithm
    digest_algorithm = signer_info["digest_algorithm"]
    print("Signature algorithm :", digest_algorithm["algorithm"].native)

    print("signature time :", signer_info["signed_attrs"][1]["values"][0].native)

    cert = signer_info["sid"].chosen

    print("cert info:")
    print("serial_number:", cert["serial_number"].native)
    for k, v in cert["issuer"].native.items():
        print(k, ":", v)
