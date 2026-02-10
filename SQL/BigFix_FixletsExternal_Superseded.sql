/****** SideID, FixletID of Superseded Fixlets ******/
SELECT 
      S.[SiteID]
    , E.[ID] AS [FixletID]
FROM [BFEnterprise].[dbo].[EXTERNAL_OBJECT_DEFS] AS E
INNER JOIN [BFEnterprise].[dbo].[SITENAMEMAP] AS S
    ON E.[Sitename] = S.[Sitename]
WHERE E.[IsFixlet] = 1
  AND E.[Name] LIKE '% (Superseded)%'
