
# This is Windows Only and Python2 only: https://github.com/hakril/PythonForWindows/projects/1
# https://twitter.com/jgstew/status/1012509162540974080
# https://programtalk.com/vs2/python/5137/PythonForWindows/windows/wintrust.py/
# https://github.com/hakril/PythonForWindows/blob/master/samples/crypto/wintrust.py
# https://github.com/jgstew/tools/blob/master/Python/verifyAuthenticodePS.py

import windows.wintrust
# git clone https://github.com/hakril/PythonForWindows.git
# cd PythonForWindows && python .\setup.py install

sFileName = r"C:\Windows\explorer.exe"

print "signed: " + str( windows.wintrust.is_signed(sFileName) )
print "0 is valid: " + str( windows.wintrust.check_signature(sFileName) )
