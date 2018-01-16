#  function url_to_prefetch(url) takes
#    Input a URL of a file
#      downloads the file at the URL, and 
#    Outputs a BigFix Prefetch statement.

# NOTE: not sure if `size` is always accurate. Need to investigate further with more examples. TODO

from __future__ import with_statement
from hashlib import sha1, sha256

try:
  from urllib.request import urlopen # Python 3
except ImportError:
  from urllib2 import urlopen # Python 2

#import sys


def url_to_prefetch(url):
  hashes = sha1(), sha256()
  chunksize = max(4096, max(h.block_size for h in hashes))
  size = 0
  #iterations = 0
  filename = "testfile"
  
  response = urlopen(url)
  while True:
    chunk = response.read(chunksize)
    if not chunk:
      break
    for h in hashes:
      h.update(chunk)
      #iterations = iterations + 1
      # https://stackoverflow.com/questions/4013230/how-many-bytes-does-a-string-have
      try:
        size = size + ( len(str(chunk)) )
      except UnicodeDecodeError:
        print(size)
        # https://docs.python.org/2/tutorial/errors.html
        raise
      
  #Debugging:
  #print(iterations)

  # if using `len(str(chunk))` then size is double for some reason.
  size = size / 2

  # https://www.learnpython.org/en/String_Formatting
  return ( "prefetch %s sha1:%s size:%d %s sha256:%s" % (filename, hashes[0].hexdigest(), size, url, hashes[1].hexdigest()) )



if __name__ == '__main__':
  print( url_to_prefetch("http://download.windowsupdate.com/d/msdownload/update/software/secu/2016/07/windows10.0-kb3172729-x64_18df742fad6bebc01e617c2d4f92e0d325e5138f.msu") )

# References: 
#  - https://stackoverflow.com/questions/537542/how-can-i-create-multiple-hashes-of-a-file-using-only-one-pass
#  - https://stackoverflow.com/questions/1517616/stream-large-binary-files-with-urllib2-to-file
#  - https://stackoverflow.com/questions/16694907/how-to-download-large-file-in-python-with-requests-py
#  - https://gist.github.com/Zireael-N/ed36997fd1a967d78cb2
