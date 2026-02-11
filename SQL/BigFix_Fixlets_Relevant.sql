/****** SiteID, FixletID for fixlets with at least 1 relevant computer ******/
SELECT DISTINCT [SiteID]
      ,[ID] As FixletID
  FROM [BFEnterprise].[dbo].[FIXLETRESULTS]
  WHERE [IsRelevant] = 1
