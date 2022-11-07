#!/usr/bin/env python

import sys

try:
    import bigfix_prefetch
except ModuleNotFoundError:
    print("")
    print("ERROR: requires `bigfix_prefetch` - install with:")
    print("    pip install bigfix-prefetch")
    print(" -------------------------------- ")
    raise


# if called directly, then run this example:
if __name__ == "__main__":
    # get first argument as prefetch_string:
    try:
        prefetch_string = sys.argv[1]
    except IndexError:
        prefetch_string = None

    # if no url, use a default for demo purposes:
    if not prefetch_string:
        prefetch_string = "prefetch unzip.exe sha1:84debf12767785cd9b43811022407de7413beb6f size:204800 https://software.bigfix.com/download/redist/unzip-6.0.exe sha256:2122557d350fd1c59fb0ef32125330bde673e9331eb9371b454c2ad2d82091ac"

    if "http://" not in prefetch_string and "https://" not in prefetch_string:
        print("ERROR: invalid prefetch: ", prefetch_string)
        sys.exit(1)

    # download file and validate it matches hashes:
    file_valid = bigfix_prefetch.prefetch.prefetch(prefetch_string)

    if not file_valid:
        print("\nERROR: file does not match hashes in prefetch!!!")
    else:
        print("\nFile downloaded successfully.")
