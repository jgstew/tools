"""
Decrypt a base64 string using the Windows DPAPI

Requires:
pip install pywin32

Related:
- https://github.com/jgstew/tools/blob/master/powershell/WinDPAPI_decrypt.ps1
"""

import base64
import sys

try:
    import win32crypt
except (ImportError, ModuleNotFoundError) as e:
    if not sys.platform.startswith("win"):
        raise RuntimeError("This script only works on Windows systems") from e
    raise ImportError(
        "This script requires the pywin32 package. Install it via 'pip install pywin32'."
    ) from e

# Put the encrypted base64 string here:
base64_string = ""

if not base64_string or base64_string.strip() == "":
    print("Please set the 'base64_string' variable with the encrypted data.")
    sys.exit(1)

try:
    print("Attempting to decrypt the string using the local machine key...")

    # 1. Decode the Base64 string to get the raw encrypted bytes
    encrypted_bytes = base64.b64decode(base64_string)

    # 2. Call CryptUnprotectData.
    # The last parameter (flags) is set to 4
    # to indicate that the data was encrypted in the machine context.
    #
    # The function returns a tuple: (description, decrypted_bytes)
    # We only need the second element.
    _, decrypted_bytes = win32crypt.CryptUnprotectData(
        encrypted_bytes,
        None,  # Optional entropy
        None,  # Reserved
        None,  # Prompt Struct
        4,
    )

    # 3. Decode the decrypted byte array from UTF-8 to a readable string
    decrypted_string = decrypted_bytes.decode("utf-8")

    print("\nDecryption Successful!")
    print(f"Decrypted String: {decrypted_string}")

except Exception as e:
    print("\nDecryption Failed.")
    print(f"Error Message: {e}")
    print("\nThis could mean:")
    print(
        "1. You are not running this script with sufficient permissions (try 'Run as administrator')."
    )
    print("2. The data was not encrypted on this machine.")
    print(
        "3. The data was originally encrypted with the 'CurrentUser' scope, not 'LocalMachine'."
    )
