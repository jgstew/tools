/****** Info on deleted computers in BigFix  ******/
SELECT [ComputerID]
      ,[LastReportTime]
	  ,[ComputerName]
	  ,[AgentType]
      ,[IsRelay]
      ,[ReportNumber]
  FROM [BFEnterprise].[dbo].[COMPUTERS]
  WHERE [IsDeleted] = 1
