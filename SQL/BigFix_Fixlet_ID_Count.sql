SELECT TOP (1000) [ID], count(*) as Count
  FROM [BFEnterprise].[dbo].[BES_FIXLETS]
  GROUP BY [ID]
