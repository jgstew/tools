from __future__ import with_statement
from hashlib import sha1, sha256


try:
  from urllib.request import urlopen # Python 3
except ImportError:
  from urllib2 import urlopen # Python 2

# https://stackoverflow.com/a/26767972
import sys
#reload(sys)
#sys.setdefaultencoding('Cp1252')

def url_to_prefetch(url):
  hashes = sha1(), sha256()
  chunksize = max(4096, max(h.block_size for h in hashes))
  size = 0
  filename = "testfile"
  
  response = urlopen(url)
  while True:
    chunk = response.read(chunksize)
    if not chunk:
      break
    for h in hashes:
      h.update(chunk)
      # https://stackoverflow.com/questions/4013230/how-many-bytes-does-a-string-have
      size = size + sys.getsizeof(chunk)
  
  # https://www.learnpython.org/en/String_Formatting
  return ( "prefetch %s sha1:%s size:%d %s sha256:%s" % (filename, "SHA1ph", size, url, size) )



if __name__ == '__main__':
  print( url_to_prefetch("http://google.com") )

# References: 
#  - https://stackoverflow.com/questions/537542/how-can-i-create-multiple-hashes-of-a-file-using-only-one-pass
#  - https://stackoverflow.com/questions/1517616/stream-large-binary-files-with-urllib2-to-file
#  - https://stackoverflow.com/questions/16694907/how-to-download-large-file-in-python-with-requests-py
#  - https://gist.github.com/Zireael-N/ed36997fd1a967d78cb2
