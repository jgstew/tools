#!/usr/bin/env python
# moved to https://github.com/jgstew/bigfix_prefetch/blob/master/src/bigfix_prefetch/prefetch_from_url.py

try:
  import bigfix_prefetch
except ModuleNotFoundError:
  print("")
  print("ERROR: requires `bigfix_prefetch` - install with:")
  print("    pip install bigfix-prefetch")
  print(" -------------------------------- ")
  raise


# if called directly, then run this example:
if __name__ == '__main__':
  print(bigfix_prefetch.prefetch_from_url("google.com"))
