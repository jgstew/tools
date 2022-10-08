#!/usr/bin/env python3

# https://stackoverflow.com/questions/17195924/python-equivalent-of-unix-strings-utility

import string


def strings(filename, min=4):
    with open(filename, errors="ignore") as f:  # Python 3.x
        result = ""
        for c in f.read():
            if c in string.printable:
                result += c
                continue
            if len(result) >= min:
                yield result
            result = ""
        if len(result) >= min:  # catch result at EOF
            yield result


def main(filename, min=4):
    for s in strings(filename, min):
        # get https:// or http:// or similar:
        if "://" in s:
            # strip off whitespace, print:
            print(s.strip())


if __name__ == "__main__":
    main(r"\tmp\file.exe", 18)
