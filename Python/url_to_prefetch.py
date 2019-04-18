#  function url_to_prefetch(url) takes
#    Input a URL of a file
#      downloads the file at the URL, and 
#    Outputs a BigFix Prefetch statement.

# NOTE: not sure if `size` is always accurate. Need to investigate further with more examples and different `chunksize`. TODO

##  Example Results:
# Docker: docker run python:2 bash -c "wget https://raw.githubusercontent.com/jgstew/tools/master/Python/url_to_prefetch.py ;python url_to_prefetch.py"
#  Input: http://download.windowsupdate.com/d/msdownload/update/software/secu/2016/07/windows10.0-kb3172729-x64_18df742fad6bebc01e617c2d4f92e0d325e5138f.msu
# Output: prefetch testfile sha1:18df742fad6bebc01e617c2d4f92e0d325e5138f size:199259 http://download.windowsupdate.com/d/msdownload/update/software/secu/2016/07/windows10.0-kb3172729-x64_18df742fad6bebc01e617c2d4f92e0d325e5138f.msu sha256:f5b55d436056a905e755984d457bac67295ad3e11531a6c33f3812cfb63ce010

# TODO: !!! size calc failes in Python3 !!!
# TODO: Consider adding options to cache the file downloads & log/cache the prefetches generated


from hashlib import sha1, sha256

try:
  from urllib.request import urlopen # Python 3
except ImportError:
  from urllib2 import urlopen # Python 2


def main():
  print( url_to_prefetch("http://download.windowsupdate.com/d/msdownload/update/software/secu/2016/07/windows10.0-kb3172729-x64_18df742fad6bebc01e617c2d4f92e0d325e5138f.msu") )

def url_to_prefetch(url):
  hashes = sha1(), sha256()
  # chunksize seems like it could be anything
  #   it is probably best if it is a multiple of a typical hash block_size
  #   a larger chunksize is probably best for faster downloads
  #   a larger chunksize is probably also better due to extra overhead due to meltdown mitigations
  chunksize = max(384000, max(h.block_size for h in hashes))
  size = 0
  filename = "testfile" # TODO: get filename from URL/download
  
  response = urlopen(url)
  while True:
    chunk = response.read(chunksize)
    if not chunk:
      break
    for h in hashes:
      h.update(chunk)
      # https://stackoverflow.com/questions/4013230/how-many-bytes-does-a-string-have
      size = size + ( len(str(chunk)) )

  # if using `len(str(chunk))` then size is double for some reason in Python2 (this is just wrong in Python3)
  size = size / 2

  # https://www.learnpython.org/en/String_Formatting
  # TODO: not sure how to get the results from `hashes` by name (sha1) rather than by index (0)
  return ( "prefetch %s sha1:%s size:%d %s sha256:%s" % (filename, hashes[0].hexdigest(), size, url, hashes[1].hexdigest()) )


# if called directly, then run this example:
if __name__ == '__main__':
  main()


# References: 
#  - https://stackoverflow.com/questions/537542/how-can-i-create-multiple-hashes-of-a-file-using-only-one-pass
#  - https://stackoverflow.com/questions/1517616/stream-large-binary-files-with-urllib2-to-file
#  - https://stackoverflow.com/questions/16694907/how-to-download-large-file-in-python-with-requests-py
#  - https://gist.github.com/Zireael-N/ed36997fd1a967d78cb2
#  - https://blog.sourcerer.io/full-guide-to-developing-rest-apis-with-aws-api-gateway-and-aws-lambda-d254729d6992
#  - https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-lambda.html

#  AWS Lambda
#from url_to_prefetch import url_to_prefetch
#def lambda_handler(event, context):
#    print( event['url_to_prefetch'] )
#    return url_to_prefetch( event['url_to_prefetch'] )

