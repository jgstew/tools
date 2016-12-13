/******  Actions * Computers WHERE Successful  ******/
SELECT COUNT(*)
  FROM [BFEnterprise].[dbo].[BES_ACTIONS]
  WHERE [ActionStatus]='Fixed';
