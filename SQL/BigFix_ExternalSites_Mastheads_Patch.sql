/****** BigFix Patch ExternalSites ******/
SELECT
      [UndecoratedSitename]
      ,[Masthead]
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
  WHERE [UndecoratedSitename] LIKE '%Enterprise%'
   OR [UndecoratedSitename] LIKE '%Patch%'
   OR [UndecoratedSitename] LIKE '%Update%'
