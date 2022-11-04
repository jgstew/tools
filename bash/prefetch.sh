
# Example Usage:
# prefetch statement:
# bash prefetch.sh "prefetch unzip.exe sha1:84debf12767785cd9b43811022407de7413beb6f size:204800 http://software.bigfix.com/download/redist/unzip-6.0.exe sha256:2122557d350fd1c59fb0ef32125330bde673e9331eb9371b454c2ad2d82091ac"
# prefetch block:
# bash prefetch.sh "add prefetch item name=string.txt sha1=? size=? url=? sha256=?"

prefetch="$1"
# echo $prefetch

command_exists () {
  type "$1" &> /dev/null ;
}


prefetch_name="`echo $prefetch | sed -E 's/.*(name=|prefetch )([a-zA-Z0-9\.]+)( .+|$)/\2/'`"
prefetch_sha256="`echo $prefetch | sed -E 's/.+ (sha256:|sha256=)([a-zA-Z0-9]+)( .+|$)/\2/'`"
prefetch_url="`echo $prefetch | sed -E 's/.+ (|url=)(http[-:/.a-zA-Z0-9]+)( .+|$)/\2/'`"

# echo $prefetch_name
# echo $prefetch_sha256
# echo $prefetch_url

#### Downloads #############################################
echo
echo Downloading file $prefetch_name from: $prefetch_url
DLEXITCODE=0
if command_exists curl ; then
  # Download the file
  curl -o $prefetch_name $prefetch_url
  # http://stackoverflow.com/questions/6348902/how-can-i-add-numbers-in-a-bash-script
  DLEXITCODE=$(( DLEXITCODE + $? ))
else
  if command_exists wget ; then
    # this is run if curl doesn't exist, but wget does
    # download using wget
    # http://stackoverflow.com/questions/16678487/wget-command-to-download-a-file-and-save-as-a-different-filename
    # https://www.gnu.org/software/wget/manual/html_node/HTTPS-_0028SSL_002fTLS_0029-Options.html
    wget $prefetch_url -O $prefetch_name
    DLEXITCODE=$(( DLEXITCODE + $? ))
  else
    echo neither wget nor curl is installed.
    echo not able to download required files.
    echo exiting...
    exit 2
  fi
fi

# Exit if download failed
if [ $DLEXITCODE -ne 0 ]; then
  # http://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
  (>&2 echo Download Failed. ExitCode=$DLEXITCODE)
  exit $DLEXITCODE
fi

echo
echo "Validating file sha256 hash:"
echo "$prefetch_sha256 $prefetch_name" | sha256sum --check

if [ $? -ne 0 ]; then
  echo ERROR: sha256 does not match! Deleting file!
  rm $prefetch_name
fi
