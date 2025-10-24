/****** Get info on Client Query / Fast Query in DB ******/
SELECT [QueryID]
      ,[Operator]
      ,[CreationTime]
      , CAST(CAST([Fields] AS VARBINARY(MAX)) AS XML) as 'Fields'
  FROM [BFEnterprise].[dbo].[QUERIES]
