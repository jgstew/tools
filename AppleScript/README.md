
scripts with a `.sh` extension use bash to execute AppleScript using `osascript`

Otherwise, it seems like AppleScript files should have a `.scpt` extension by default:

- http://fileinfo.com/extension/scpt


### Examples:

- To execute a `.scpt` file on the command line:
 - `osascript openQnA.scpt`
- To execute an AppleScript command without a file:
 - `osascript -e 'tell application "Terminal" to set shell to do script "clear" in window 1'`
