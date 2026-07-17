 # Requires the SqlServer module: Install-Module SqlServer
$server   = 'localhost'
$database = 'BFEnterprise'
$outDir   = 'C:\tmp'

# https://github.com/jgstew/tools/blob/master/SQL/BigFix_ExternalSites_Mastheads_Patch_BES.sql
$query = @"
SELECT
      [UndecoratedSitename],
      '<?xml version="1.0" encoding="UTF-8"?><BES xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BES.xsd"><ExternalSite><Name>'
      + [UndecoratedSitename]
      + '</Name><GlobalReadPermission>true</GlobalReadPermission><Masthead><![CDATA['
      + [Masthead]
      + ']]></Masthead></ExternalSite></BES>' AS [BESContent]
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
  WHERE [UndecoratedSitename] LIKE '%Enterprise%'
     OR [UndecoratedSitename] LIKE '%Patch%'
     OR [UndecoratedSitename] LIKE '%Update%'
"@

New-Item -ItemType Directory -Path $outDir -Force | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

Invoke-Sqlcmd -ServerInstance $server -Database $database -Query $query `
    -MaxCharLength 2147483647 |
  ForEach-Object {
    $safeName = $_.UndecoratedSitename -replace '[\\/:*?"<>|]', '_'
    $safeName = $safeName -creplace '\bfor\b', 'For'   # case-sensitive, whole word "for" -> "For"
    $safeName = $safeName -replace '\s', ''            # remove all spaces
    $path = Join-Path $outDir "Site_$safeName.bes"
    $path = Join-Path $outDir "Site_$safeName.bes"
    [System.IO.File]::WriteAllText($path, $_.BESContent, $utf8NoBom)
    Write-Host "Wrote $path"
  }
