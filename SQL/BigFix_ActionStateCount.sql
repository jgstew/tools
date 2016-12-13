/****** Count of each ActionState  ******/
SELECT
	  DISTINCT [BFEnterprise].[dbo].[ACTIONSTATESTRINGS].[ActionStateString],
	  count([BFEnterprise].[dbo].[ACTIONSTATESTRINGS].[ActionStateString]) AS numberEach
  FROM [BFEnterprise].[dbo].[ACTIONRESULTS]
  INNER JOIN [BFEnterprise].[dbo].[ACTIONSTATESTRINGS]
  ON [BFEnterprise].[dbo].[ACTIONRESULTS].[State]=[BFEnterprise].[dbo].[ACTIONSTATESTRINGS].[ActionState]
  GROUP BY [BFEnterprise].[dbo].[ACTIONSTATESTRINGS].[ActionStateString]
