#!/usr/bin/env bash
# examples of verifying windows PE signatures using cross platform tools

# https://github.com/mtrojnar/osslsigncode
./osslsigncode verify /tmp/SoftwareUpdate.exe
# does not seem to validate time stamping without additional file


# https://github.com/sassoftware/relic
./relic-client verify /tmp/SoftwareUpdate.exe
# example output:
# ./SoftwareUpdate.exe: OK - `CN=Apple Inc., OU=Digital ID Class 3 - Microsoft Software Validation v2, O=Apple Inc., L=Cupertino, ST=California, C=US`
# ./SoftwareUpdate.exe(timestamp): OK - `CN=VeriSign Time Stamping Services Signer - G2, O="VeriSign, Inc.", C=US` [2008-07-25 22:21:53 +0000 UTC]
