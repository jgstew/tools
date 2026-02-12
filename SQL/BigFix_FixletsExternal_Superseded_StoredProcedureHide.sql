/****** Call Stored Procedure to hide all Superseded Content with no open actions or relevant devices ******/
SET NOCOUNT ON; -- Stops the "1 row affected" spam for every single update

DECLARE @CurrentSiteID INT;
DECLARE @CurrentFixletID INT;
DECLARE @ProcessedCount INT = 0;

PRINT 'Starting analysis of Superseded Fixlets...';

-- 1. Declare the cursor
DECLARE FixletCursor CURSOR FOR
    WITH CombinedFixletsExclude AS (
        -- Exclude if relevant on at least 1 computer
        SELECT DISTINCT [SiteID], [ID] As FixletID
        FROM [BFEnterprise].[dbo].[FIXLETRESULTS]
        WHERE [IsRelevant] = 1

        UNION

        -- Exclude if part of an open action
        SELECT [SourceSiteID], [SourceContentID]
        FROM [BFEnterprise].[dbo].[ACTIONS]
        WHERE [SourceSiteID] IS NOT NULL
          AND [IsStopped] = 0
          AND [IsDeleted] = 0

        UNION

        -- Exclude if already hidden (already in visibility table)
        SELECT [SiteID], [FixletID]
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
      AND NOT EXISTS (
          SELECT 1 
          FROM CombinedFixletsExclude AS ExcludeList
          WHERE ExcludeList.[SiteID] = SiteNameMapTable.[SiteID]
            AND ExcludeList.[FixletID] = ExternalFixletsTable.[ID]
      );

-- 2. Open the cursor
OPEN FixletCursor;

FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;

-- 3. Loop through results
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Run the update
    EXEC dbo.update_fixlet_visibility 
        @siteID = @CurrentSiteID, 
        @fixletID = @CurrentFixletID, 
        @isVisible = 0;

    -- Increment counter
    SET @ProcessedCount = @ProcessedCount + 1;
    
    FETCH NEXT FROM FixletCursor INTO @CurrentSiteID, @CurrentFixletID;
END

-- 4. Cleanup and Final Output
CLOSE FixletCursor;
DEALLOCATE FixletCursor;

PRINT '---------------------------------------------------';
IF @ProcessedCount = 0
    PRINT 'Result: No superseded items required hiding at this time.';
ELSE
    PRINT 'Result: Successfully hid ' + CAST(@ProcessedCount AS VARCHAR(10)) + ' superseded fixlets.';
PRINT '---------------------------------------------------';
