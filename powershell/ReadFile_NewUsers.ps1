
Start-Transcript ($MyInvocation.MyCommand.Source + ".log") # -Append

# match `first.last` within ` first.last@demo.com ` or within ` first.last `
#  - regexr.com/5bqku
$REGEX = " *(\w+\.\w+)[@ \n]*"

# read users from file "ReadFile_NewUsers.ps1.txt"
#   file should have 1 user.name per line
foreach( $line in Get-Content ($MyInvocation.MyCommand.Source + ".txt") ) {
    #Write-Host $line
    if([regex]::Match($line, $REGEX)[0].Groups[1].Value){
        # Get the first RegEx Match, Get first capture Group value
        # - https://stackoverflow.com/questions/33913878/how-to-get-the-captured-groups-from-select-string
        $parsed = [regex]::Match($line, $REGEX)[0].Groups[1].Value
        Write-Host $parsed # first.last
    }
}

Stop-Transcript

# References:
# - https://stackoverflow.com/questions/33511772/read-file-line-by-line-in-powershell
# - https://stackoverflow.com/questions/33913878/how-to-get-the-captured-groups-from-select-string 

# Related:
# - https://github.com/jgstew/tools/blob/master/powershell/ad_New-ADUser.ps1
# - https://github.com/jgstew/tools/tree/master/powershell
