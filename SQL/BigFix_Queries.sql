/****** Get info on Client Query / Fast Query in DB ******/
SELECT [QueryID]
      ,[Operator]
      ,[CreationTime]
	    ,dbo.fn_ExtractField('Query', 1, Fields) as 'QueryRelevance'
	    ,dbo.fn_ExtractField('Targeting', 0, Fields) as 'Targeting'
      --,CAST(CAST([Fields] AS VARBINARY(MAX)) AS XML).value(
      --  '(/Object/Fields/Contents/text())[5]', -- XPath to the node
      --  'NVARCHAR(MAX)' -- SQL data type to return
      --) AS 'QueryRelevance2'
  FROM [BFEnterprise].[dbo].[QUERIES]
