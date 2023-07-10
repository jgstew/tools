import codecs

file_path = "Python/file_check_bom.py"

encoding = "Unknown"

required_bom = getattr(codecs, "BOM_UTF8")

with open(file_path, "rb") as file:
    header = file.read(len(required_bom))
    if header.startswith(required_bom):
        encoding = "utf-8-bom"

print(encoding)
