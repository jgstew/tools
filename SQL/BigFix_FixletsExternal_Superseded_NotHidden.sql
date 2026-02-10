/****** SiteID, FixletID for External Fixlets that are Superseded but NOT hidden ******/
SELECT 
      SiteNameMapTable.[SiteID]
    , ExternalFixletsTable.[ID] AS [FixletID]
FROM [BFEnterprise].[dbo].[EXTERNAL_OBJECT_DEFS] AS ExternalFixletsTable
INNER JOIN [BFEnterprise].[dbo].[SITENAMEMAP] AS SiteNameMapTable
    ON ExternalFixletsTable.[Sitename] = SiteNameMapTable.[Sitename]
WHERE ExternalFixletsTable.[IsFixlet] = 1
  AND ExternalFixletsTable.[Name] LIKE '% (Superseded)%'
  AND NOT EXISTS (
      SELECT 1 
      FROM [BFEnterprise].[dbo].[FIXLET_VISIBILITY] AS VisibilityTable
      WHERE VisibilityTable.[SiteID] = SiteNameMapTable.[SiteID]
        AND VisibilityTable.[FixletID] = ExternalFixletsTable.[ID]
  )
