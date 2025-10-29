-- This came from John / brolly33:
-- This gets the unique fields from all action definitions.
-- Select the distinct (unique) values found
SELECT DISTINCT
    -- Use the .value() XML method to extract the text content
    -- from the first (or only) child node named <Name>
    -- within the current <Fields> node (represented by x.Item).
    -- Cast this extracted value to VARCHAR(MAX) and alias the
    -- resulting column as 'fieldname'.
    x.Item.value('(Name)[1]', 'VARCHAR(MAX)') AS fieldname
FROM
(
    -- Start of a derived table (subquery) aliased as 'actiondefs'
    SELECT
        -- The [Fields] column (which is likely stored as text)
        -- is first cast to VARBINARY(MAX) and then to the XML data type.
        -- This double-cast is a common technique to handle
        -- potential encoding issues or data type conflicts (e.g., from TEXT/NTEXT).
        -- The resulting XML column is aliased as 'data'.
        CAST(CAST([Fields] AS VARBINARY(MAX)) AS XML) AS data
    FROM
        [BFEnterprise].[dbo].[ACTION_DEFS] -- Specify the source table
) AS actiondefs
-- CROSS APPLY is used to invoke the .nodes() function for EACH row
-- from the 'actiondefs' derived table.
CROSS APPLY
    -- The .nodes() method "shreds" the XML in the 'data' column.
    -- It finds every node matching the XQuery path '/Object/Fields'
    -- (i.e., all <Fields> nodes that are children of the root <Object> node).
    -- It returns a new row for each matching <Fields> node.
    -- This new "virtual" table is aliased as 'x',
    -- and its single column (containing the XML node) is aliased as 'Item'.
    actiondefs.data.nodes('/Object/Fields') AS x(Item);
