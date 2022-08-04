# pip install python-magic
# pip install python-magic-bin

import magic

print(magic.from_file(r"C:\Windows\explorer.exe"))
# Example Output: `PE32+ executable (GUI) x86-64, for MS Windows`
