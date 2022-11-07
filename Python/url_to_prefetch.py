#!/usr/bin/env python
# moved to https://github.com/jgstew/bigfix_prefetch/blob/master/src/bigfix_prefetch/prefetch_from_url.py

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
    # get first argument as url:
    try:
        url = sys.argv[1]
    except IndexError:
        url = None

    # if no url, use a default for demo purposes:
    if not url:
        url = "http://software.bigfix.com/download/redist/unzip-6.0.exe"

    if "http" not in url or "://" not in url:
        print("ERROR: invalid URL: ", url)
        sys.exit(1)

    # get prefetch and print to console:
    print(bigfix_prefetch.prefetch_from_url.url_to_prefetch(url))
