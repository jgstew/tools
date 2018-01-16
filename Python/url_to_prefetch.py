from __future__ import with_statement
from hashlib import sha1, sha256

def url_to_prefetch(url)
  hashes = sha1(), sha256()
  chunksize = max(4096, max(h.block_size for h in hashes))
  size = 0
  


# References: 
#  - https://stackoverflow.com/questions/537542/how-can-i-create-multiple-hashes-of-a-file-using-only-one-pass
#  - https://stackoverflow.com/questions/16694907/how-to-download-large-file-in-python-with-requests-py
#  - https://gist.github.com/Zireael-N/ed36997fd1a967d78cb2
