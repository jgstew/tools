/****** SiteID, FixletID for sources of open actions ******/
SELECT DISTINCT [SourceSiteID]
      ,[SourceContentID]
  FROM [BFEnterprise].[dbo].[ACTIONS]
  WHERE [SourceSiteID] is not NULL
  AND [IsStopped] = 0
  AND [IsDeleted] = 0
