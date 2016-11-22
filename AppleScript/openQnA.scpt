tell application "Terminal"
	if not (exists window 1) then reopen
	activate
	do script "/Library/BESAgent/BESAgent.app/Contents/MacOS/QnA -showtypes" in window 1
end tell
