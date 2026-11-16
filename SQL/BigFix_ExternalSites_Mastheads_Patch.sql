/****** BigFix Patch ExternalSites ******/
SELECT
      [UndecoratedSitename]
      ,[Masthead]
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
  WHERE [UndecoratedSitename] LIKE '%Enterprise Security%'
   OR [UndecoratedSitename] LIKE '%Patch%'
   OR [UndecoratedSitename] LIKE '%Update%'
