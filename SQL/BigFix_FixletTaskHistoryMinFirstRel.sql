/****** Not validated, just a first attempt  ******/
SELECT
      [Sitename]
      ,[ID]
      ,MIN([FirstBecameRelevant])
  FROM [BFEnterprise].[dbo].[BES_RELEVANT_FIXLET_HISTORY]
  GROUP BY [Sitename],[ID]
UNION
SELECT
      [Sitename]
      ,[ID]
      ,MIN([FirstBecameRelevant])
  FROM [BFEnterprise].[dbo].[BES_RELEVANT_TASK_HISTORY]
  GROUP BY [Sitename],[ID];
