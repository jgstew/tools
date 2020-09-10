
Start-Transcript ($MyInvocation.MyCommand.Source + ".log") # -Append

# match `first.last` within ` first.last@demo.com `
#  - regexr.com/5bqku
$REGEX = " *(\w+\.\w+)[@ \n]"

# read users from file "ReadFile_NewUsers.ps1.txt"
foreach( $line in Get-Content ($MyInvocation.MyCommand.Source + ".txt") ) {
    if($line -match $regex){
        # Get the first RegEx Match, Get first capture Group value
        # - https://stackoverflow.com/questions/33913878/how-to-get-the-captured-groups-from-select-string
        $parsed = [regex]::Match($line, $REGEX)[0].Groups[1].Value
        Write-Host $parsed
    }
}

Stop-Transcript

# References:
#  - https://stackoverflow.com/questions/33511772/read-file-line-by-line-in-powershell
