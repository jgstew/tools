/****** BigFix Patch ExternalSites BES ******/
SELECT
      '<?xml version="1.0" encoding="UTF-8"?><BES xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="BES.xsd"><ExternalSite><Name>'
	  + [UndecoratedSitename]
      + '</Name><GlobalReadPermission>true</GlobalReadPermission><Masthead><![CDATA['
	  + [Masthead]
	  + ']]></Masthead></ExternalSite></BES>'
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
  WHERE [UndecoratedSitename] LIKE '%Enterprise%'
   OR [UndecoratedSitename] LIKE '%Patch%'
   OR [UndecoratedSitename] LIKE '%Update%'
