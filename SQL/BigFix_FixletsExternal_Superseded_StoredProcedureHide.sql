/****** Call Stored Procedure to hide all Superseded Content ******/
DECLARE @CurrentSiteID INT;
DECLARE @CurrentFixletID INT;

-- 1. Declare the cursor using your "missing items" query
DECLARE FixletCursor CURSOR FOR
SELECT 
      SiteNameMapTable.[SiteID]
    , ExternalFixletsTable.[ID]
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
  );

-- 2. Open the cursor and begin the loop
OPEN FixletCursor;

FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 3. Call the Stored Procedure for the current row
    EXEC dbo.update_fixlet_visibility 
        @siteID = @CurrentSiteID, 
        @fixletID = @CurrentFixletID, 
        @isVisible = 0;

    -- Fetch the next row
    FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;
END

-- 4. Clean up
CLOSE FixletCursor;
DEALLOCATE FixletCursor;
