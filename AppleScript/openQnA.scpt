-- http://www-01.ibm.com/support/docview.wss?uid=swg21506026
-- https://github.com/jgstew/tools/blob/master/bash/openQnA.sh
-- http://alvinalexander.com/blog/post/mac-os-x/applescript-use-comments
tell application "Terminal"
	if not (exists window 1) then reopen
	activate
	do script "/Library/BESAgent/BESAgent.app/Contents/MacOS/QnA -showtypes" in window 1
end tell

-- http://stackoverflow.com/questions/5288161/converting-to-one-line-applescript
-- osascript -e 'tell application "Terminal"' -e 'if not (exists window 1) then reopen' -e 'activate' -e 'do script "/Library/BESAgent/BESAgent.app/Contents/MacOS/QnA -showtypes" in window 1' -e 'end tell'
