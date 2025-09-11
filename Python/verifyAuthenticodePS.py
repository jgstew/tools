# NOTE: This is Windows Only - tested in Python2.7.1 (should work in Python3)
# https://twitter.com/jgstew/status/1011657455275610112
# https://github.com/jgstew/tools/blob/master/CMD/PS_VerifyFileSig.bat
# https://github.com/jgstew/tools/blob/master/Python/verifyAuthenticode.py
# https://docs.python.org/2/library/subprocess.html

# powershell -ExecutionPolicy Bypass -command "(Get-AuthenticodeSignature \"C:\Windows\explorer.exe\").Status -eq 'Valid'"
import subprocess

# import sys

sFileName = r"C:\Windows\explorer.exe"
# https://stackoverflow.com/questions/21944895/running-powershell-script-within-python-script-how-to-make-python-print-the-pow
sResult = subprocess.check_output(
    [
        "powershell",
        "-ExecutionPolicy",
        "Bypass",
        "-command",
        r'(Get-AuthenticodeSignature "' + sFileName + r'").Status -eq "Valid"',
    ]
)

if "True" in sResult:
    print("Athenticode Signature is Valid")
else:
    print("!!Authenticode Signature is Invalid!!")
