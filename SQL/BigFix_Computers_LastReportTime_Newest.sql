/****** Get newest computer last report time in DB ******/
SELECT MAX(LastReportTime) AS LastReportTimeMax
  FROM [BFEnterprise].[dbo].[COMPUTERS]
/******
SELECT TOP (1)
       [LastReportTime]
  FROM [BFEnterprise].[dbo].[COMPUTERS]
  ORDER BY [LastReportTime] DESC
******/
/******
SELECT TOP 1 [Value]
  FROM [BFEnterprise].[dbo].[BES_COLUMN_HEADINGS]
 WHERE [Name] = 'Last Report Time'
-- Convert the text to a date, then sort Descending (Newest first)
ORDER BY CAST(SUBSTRING([Value], 6, 20) AS DATETIME) DESC
******/
