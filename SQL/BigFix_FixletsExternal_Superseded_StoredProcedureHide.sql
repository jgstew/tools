/****** Call Stored Procedure to hide all Superseded Content with no open actions or relevant devices ******/
DECLARE @CurrentSiteID INT;
DECLARE @CurrentFixletID INT;

-- 1. Declare the cursor using the CTE to safely exclude active items
DECLARE FixletCursor CURSOR FOR
    WITH CombinedFixletsExclude AS (
        -- 1. Exclude if it has at least 1 relevant computer
        SELECT DISTINCT [SiteID]
              ,[ID] As FixletID
        FROM [BFEnterprise].[dbo].[FIXLETRESULTS]
        WHERE [IsRelevant] = 1

        UNION

        -- 2. Exclude if it has at least 1 open action
        SELECT [SourceSiteID] As SiteID
              ,[SourceContentID] As FixletID
        FROM [BFEnterprise].[dbo].[ACTIONS]
        WHERE [SourceSiteID] is not NULL
          AND [IsStopped] = 0
          AND [IsDeleted] = 0

        UNION

        -- 3. Exclude if it already has an entry in the visibility table
        SELECT [SiteID]
              ,[FixletID]
          FROM [BFEnterprise].[dbo].[FIXLET_VISIBILITY]
    )
    SELECT 
          SiteNameMapTable.[SiteID]
        , ExternalFixletsTable.[ID]
    FROM [BFEnterprise].[dbo].[EXTERNAL_OBJECT_DEFS] AS ExternalFixletsTable
    INNER JOIN [BFEnterprise].[dbo].[SITENAMEMAP] AS SiteNameMapTable
        ON ExternalFixletsTable.[Sitename] = SiteNameMapTable.[Sitename]
    WHERE ExternalFixletsTable.[IsFixlet] = 1
      AND ExternalFixletsTable.[Name] LIKE '% (Superseded)%'
      -- The Logic: Only select items that DO NOT exist in your Combined Exclude list
      AND NOT EXISTS (
          SELECT 1 
          FROM CombinedFixletsExclude AS ExcludeList
          WHERE ExcludeList.[SiteID] = SiteNameMapTable.[SiteID]
            AND ExcludeList.[FixletID] = ExternalFixletsTable.[ID]
      );

-- 2. Open the cursor and begin the loop
OPEN FixletCursor;

FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- 3. Call the Stored Procedure for the current row
    -- We assume isVisible = 0 because we want to hide these
    EXEC dbo.update_fixlet_visibility 
        @siteID = @CurrentSiteID, 
        @fixletID = @CurrentFixletID, 
        @isVisible = 0;

    FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;
END

-- 4. Clean up
CLOSE FixletCursor;
DEALLOCATE FixletCursor;
