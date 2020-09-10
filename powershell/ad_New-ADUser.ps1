
# ad_New-ADUser
#   The goal of this script is to take only the `SamAccountName` in the format of `firstname.lastname` and infer all other values

#Import-Module ActiveDirectory

#$AD_Creds = Get-Credential

#Get-ADUser -Filter * -SearchBase "OU=Users,OU=demo,DC=DEMO,DC=BIGFIX,DC=COM" | FT SamAccountName -A

$AD_DOMAIN = "demo.com"
$AD_DC_PATH = $AD_DOMAIN.ToUpper().Split(".")
$AD_DC_PATH = $AD_DC_PATH -join ",DC="
$AD_DC_PATH = "DC=" + $AD_DC_PATH
Write-Host $AD_DC_PATH
$AD_PATH_ADDRESS = "OU=Users,OU=demo," + $AD_DC_PATH
Write-Host $AD_PATH_ADDRESS

# TODO: get this from a file, loop:
$new_SamAccountName = "first.LAST"
$new_SamAccountName = $new_SamAccountName.ToLower()


$pos = $new_SamAccountName.IndexOf(".")

# https://stackoverflow.com/questions/22694582/capitalize-the-first-letter-of-each-word-in-a-filename-with-powershell 
$FirstName = (Get-Culture).TextInfo.ToTitleCase( $new_SamAccountName.Substring(0, $pos) )
$LastName = (Get-Culture).TextInfo.ToTitleCase( $new_SamAccountName.Substring($pos+1) )
$FullName = $FirstName + " " + $LastName
$UserPrincipalName = $new_SamAccountName + "@" + $AD_DOMAIN

Write-Host $new_SamAccountName
Write-Host $FullName
Write-Host $UserPrincipalName
