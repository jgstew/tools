# pip install python-magic
# pip install python-magic-bin

import magic

file_path = r"C:\Windows\explorer.exe"

print(magic.from_file(file_path))
# Example Output: `PE32+ executable (GUI) x86-64, for MS Windows`

print(magic.from_file(file_path, mime=True))
# Example Output: `application/x-dosexec`
