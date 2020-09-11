
# ad_New-ADUser
#   The goal of this script is to take only the `SamAccountName` in the format of `firstname.lastname` and infer all other values

#Import-Module ActiveDirectory

#$AD_Creds = Get-Credential

#Get-ADUser -Filter * -SearchBase "OU=Users,OU=demo,DC=DEMO,DC=COM" | FT SamAccountName -A

Start-Transcript ($MyInvocation.MyCommand.Source + ".log") # -Append

$AD_DOMAIN = "demo.com"
$MAIL_DOMAIN = "mail.demo.com"
$USER_MESSAGE = "Your account info for " + $AD_DOMAIN + " is: "

# -----------------------------------------------------------

# the following is to turn `demo.com` into `DC=DEMO,DC=COM`
$AD_DC_PATH = ("DC=" + $AD_DOMAIN).ToUpper().Split(".")
$AD_DC_PATH = $AD_DC_PATH -join ",DC="
Write-Verbose $AD_DC_PATH # DC=DEMO,DC=COM

$AD_USER_OU_PATH_ADDRESS = "OU=Users,OU=demo," + $AD_DC_PATH
Write-Verbose $AD_USER_OU_PATH_ADDRESS


function New-AD-User-From-SAM {
    # https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/09-functions?view=powershell-7 
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$new_SamAccountNames
    )

    PROCESS {
        foreach ($new_SamAccountName in $new_SamAccountNames) {
            $new_SamAccountName = $new_SamAccountName.ToLower()
            # split SamAccountName into FirstName LastName and force first character to uppercase
            $pos = $new_SamAccountName.IndexOf(".")
            # https://stackoverflow.com/questions/22694582/capitalize-the-first-letter-of-each-word-in-a-filename-with-powershell 
            $FirstName = (Get-Culture).TextInfo.ToTitleCase( $new_SamAccountName.Substring(0, $pos) )
            $LastName = (Get-Culture).TextInfo.ToTitleCase( $new_SamAccountName.Substring($pos+1) )
            $FullName = $FirstName + " " + $LastName

            $UserPrincipalName = $new_SamAccountName + "@" + $AD_DOMAIN
            $UserEmailAddress = $new_SamAccountName + "@" + $MAIL_DOMAIN

            Write-Verbose ("new_SamAccountName: " + $new_SamAccountName)
            Write-Verbose ("FullName: " + $FullName)
            Write-Verbose ("UserPrincipalName: " + $UserPrincipalName)
            Write-Verbose ("UserEmailAddress: " + $UserEmailAddress)

            $RandomPassword = Get-RandomPassword 15
            Write-Verbose ("RandomPassword: " + $RandomPassword)

            try {
                $NewUser = New-ADUser -Name $FullName -GivenName $FirstName -Surname $LastName -SamAccountName $new_SamAccountName -EmailAddress $UserEmailAddress -UserPrincipalName $UserPrincipalName -Path $AD_USER_OU_PATH_ADDRESS -AccountPassword(ConvertTo-SecureString $RandomPassword -AsPlainText -Force) -Enabled $True -ChangePasswordAtLogon $False -PassThru
                Write-Host " --- ------------------------------------ ---"
                Write-Host " --- ** User Created: $new_SamAccountName ** --- "
                Write-Host $USER_MESSAGE
                Write-Host ("**Username:** " + $UserPrincipalName)
                Write-Host ("**Password:** " + $RandomPassword)
                Write-Host " --- ------------------------------------ ---"
                # TODO: Generate File with message for user?
            }
            catch [System.ServiceModel.FaultException] {
                # $Error[0] | fl * -Force # https://devblogs.microsoft.com/scripting/weekend-scripter-using-try-catch-finally-blocks-for-powershell-error-handling/
                Write-Warning -Message "User already exists: $new_SamAccountName"
            }
        }
    }
}

# TODO: get this from a file, loop:
New-AD-User-From-SAM "firstName.TESTName" # -Verbose

Stop-Transcript

# References:
# - https://blog.netwrix.com/2018/06/07/how-to-create-new-active-directory-users-with-powershell/ 
# - https://docs.microsoft.com/en-us/powershell/module/addsadministration/new-aduser?view=win10-ps 
# - https://stackoverflow.com/questions/22694582/capitalize-the-first-letter-of-each-word-in-a-filename-with-powershell 
# - https://docs.microsoft.com/en-us/powershell/scripting/learn/ps101/09-functions?view=powershell-7 
# - https://www.computerperformance.co.uk/powershell/functions/ 
# - https://github.com/jgstew/tools/blob/master/powershell/ReadFile_NewUsers.ps1 
# - https://devblogs.microsoft.com/scripting/weekend-scripter-using-try-catch-finally-blocks-for-powershell-error-handling/ 

# Related: 
# - https://stackoverflow.com/questions/55014770/how-can-i-paste-markdown-in-microsoft-teams/55014959 


# from: http://witit.blog/2018/10/16/bulk-create-users-in-ad-via-powershell-with-random-passwords-part-iii/ 
function Get-RandomPassword{
    Param(
        [Parameter(mandatory=$true)]
        [int]$Length
    )
    Begin{
        if($Length -lt 4){
            End
        }
        $Numbers = 1..9
        $LettersLower = 'abcdefghijklmnopqrstuvwxyz'.ToCharArray()
        $LettersUpper = 'ABCEDEFHIJKLMNOPQRSTUVWXYZ'.ToCharArray()
        $Special = '!@#$%^&*()=+[{}]/?<>'.ToCharArray()

        #For the 4 character types (upper, lower, numerical, and special),
        #let's do a little bit of math magic
        $N_Count = [math]::Round($Length*.2)
        $L_Count = [math]::Round($Length*.4)
        $U_Count = [math]::Round($Length*.2)
        $S_Count = [math]::Round($Length*.2)
    }
    Process{
        $Pwd = $LettersLower | Get-Random -Count $L_Count
        $Pwd += $Numbers | Get-Random -Count $N_Count
        $Pwd += $LettersUpper | Get-Random -Count $U_Count
        $Pwd += $Special | Get-Random -Count $S_Count
        
        #If the password length isn't long enough (due to rounding),
        #add X special characters, where X is the difference between
        #the desired length and the current length.
        if($Pwd.length -lt $Length){
            $Pwd += $Special | Get-Random -Count ($Length - $Pwd.length)
        }

        #Lastly, grab the $Pwd string and randomize the order
        $Pwd = ($Pwd | Get-Random -Count $Length) -join ""
    }
    End{
        $Pwd
    }
}
