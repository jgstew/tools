/****** SideID, FixletID of Superseded Fixlets ******/
SELECT 
      SiteNameMapTable.[SiteID]
    , ExternalFixletsTable.[ID] AS [FixletID]
FROM [BFEnterprise].[dbo].[EXTERNAL_OBJECT_DEFS] AS ExternalFixletsTable
INNER JOIN [BFEnterprise].[dbo].[SITENAMEMAP] AS SiteNameMapTable
    ON ExternalFixletsTable.[Sitename] = SiteNameMapTable.[Sitename]
WHERE ExternalFixletsTable.[IsFixlet] = 1
  AND ExternalFixletsTable.[Name] LIKE '% (Superseded)%'
