Generally, direct queries to the BigFix DB should only be performed on a read only copy of the database and not directly to the root server's active database.

The same info is often available using Session Relevance which is much safer to use with an API that is much less likely to break with new versions of BigFix.

[Download SQL Server Management Studio (SSMS)](https://msdn.microsoft.com/en-us/library/mt238290.aspx)
