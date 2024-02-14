"""
Example of WinCrypto API
"""

import sys

try:
    import win32crypt
except ModuleNotFoundError as e:
    print("")
    print(e)
    print("Must install win32crypt:")
    print("pip install pywin32")
    print("")
    raise e


def main():
    """Execution starts here"""
    print("main()")

    input_text = "example-test-data"

    crypt_result = win32crypt.CryptProtectData(input_text.encode("utf-8"), Flags=4)

    # print(crypt_result)

    print(win32crypt.CryptUnprotectData(crypt_result)[1])

    return 0


if __name__ == "__main__":
    sys.exit(main())
