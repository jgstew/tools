/****** Mapping of External SiteID to Sitename

This table is populated by the BESAdmin tool.
If you have not run BESAdmin recently then it may be out of date.

Related:
- https://github.com/jgstew/tools/blob/master/bash/bfsite_get_id.sh
- https://sync.bigfix.com/bfsites/bessupport_1513/SiteMap.js
 ******/
SELECT [SiteID]
      , [UndecoratedSitename]
      , [SiteURL]
      , [ModificationTime]
FROM [BFEnterprise].[dbo].[SITENAMEMAP]
