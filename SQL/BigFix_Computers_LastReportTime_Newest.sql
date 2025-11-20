SELECT TOP 1 [Value]
  FROM [BFEnterprise].[dbo].[BES_COLUMN_HEADINGS]
 WHERE [Name] = 'Last Report Time'
-- Convert the text to a date, then sort Descending (Newest first)
ORDER BY CAST(SUBSTRING([Value], 6, 20) AS DATETIME) DESC
