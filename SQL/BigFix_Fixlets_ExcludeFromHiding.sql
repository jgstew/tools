/****** SiteID, FixletID of the combined results of fixlets to exclude from hiding ******/
WITH CombinedFixletsExclude AS (

-- Fixlets that have at least 1 relevant computer
SELECT DISTINCT [SiteID]
	  ,[ID] As FixletID
FROM [BFEnterprise].[dbo].[FIXLETRESULTS]
WHERE [IsRelevant] = 1

UNION

-- Fixlets that have at least 1 open action
SELECT [SourceSiteID] As SiteID
	  ,[SourceContentID] As FixletID
FROM [BFEnterprise].[dbo].[ACTIONS]
WHERE [SourceSiteID] is not NULL
  AND [IsStopped] = 0
  AND [IsDeleted] = 0

UNION

-- Fixlets that already have an entry in the visibility table
SELECT [SiteID]
      ,[FixletID]
  FROM [BFEnterprise].[dbo].[FIXLET_VISIBILITY]

)

SELECT * FROM CombinedFixletsExclude
ORDER BY SiteID, FixletID;
