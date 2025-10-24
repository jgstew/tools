/****** Get info on Client Query / Fast Query in DB ******/
SELECT [QueryID]
      ,[Operator]
      ,[CreationTime]
      ,CAST(CAST([Fields] AS VARBINARY(MAX)) AS XML).value(
        '(/Object/Fields/Contents/text())[5]', -- XPath to the node
        'NVARCHAR(MAX)' -- SQL data type to return
      ) AS QueryRelevance
  FROM [BFEnterprise].[dbo].[QUERIES]
