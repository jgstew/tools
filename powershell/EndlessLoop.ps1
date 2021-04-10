# https://www.vexasoft.com/blogs/powershell/7255214-powershell-tutorial-creating-an-endless-loop-avoiding-a-call-depth-overflow
while($true){$i++ ; Write-Host "counted to $i - press Ctrl+C to stop"}
