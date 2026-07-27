/****** Mapping of External SiteID to Sitename
Related:
- https://github.com/jgstew/tools/blob/master/bash/bfsite_get_id.sh
- https://sync.bigfix.com/bfsites/bessupport_1513/SiteMap.js
 ******/
SELECT [SiteID]
      ,[UndecoratedSitename]
      ,[SiteURL]
      ,[ModificationTime]
  FROM [BFEnterprise].[dbo].[SITENAMEMAP]
