# pip install chardet
# import chardet

# pip install charset_normalizer
import charset_normalizer

file_path = "Python/file_get_encoding.py"

with open(file_path, "rb") as f:
    f_data = f.read()
    print(charset_normalizer.detect(f_data))
    # print(chardet.detect(f_data))

# returns 'ascii' even if the file is saved in UTF8 format if it does not contain any unicode characters.
