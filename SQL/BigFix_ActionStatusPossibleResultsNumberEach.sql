/******  Number of Each Distinct Action Status  ******/
SELECT DISTINCT [ActionStatus], count([ActionStatus]) AS numberEach
  FROM [BFEnterprise].[dbo].[BES_ACTIONS]
  GROUP BY [ActionStatus];
