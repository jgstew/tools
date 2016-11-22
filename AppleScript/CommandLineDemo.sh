killall Terminal
open /Applications/Utilities/Terminal.app
osascript -e 'tell application "Terminal" to set shell to do script "cd" in window 1'
osascript -e 'tell application "Terminal" to set shell to do script "clear" in window 1'
osascript -e 'tell application "Terminal" to set shell to do script "cd Desktop" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "touch demo.txt" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "cp demo.txt demo2.txt" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "rm demo.txt" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "mv demo2.txt demo.txt" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "mkdir New_Dir" in window 1'
sleep 2
osascript -e 'tell application "Terminal" to set shell to do script "mv demo.txt New_Dir" in window 1'
