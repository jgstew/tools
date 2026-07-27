/****** Mapping of External SiteID to Sitename
Related: https://github.com/jgstew/tools/blob/master/bash/bfsite_get_id.sh
 ******/
SELECT [SiteID]
      ,[UndecoratedSitename]
      ,[SiteURL]
      ,[ModificationTime]
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
