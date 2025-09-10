/******
Get info about configured WebReports servers the BigFix server will
 try to connect to for RESTAPI query session relevance

You can get similar info from this REST API endpoint:
- https://developer.bigfix.com/rest-api/api/webreports.html

Consult these if you get this 503 Error:
- "Cannot perform relevance query evaluation at this time because there is no reachable BigFix Explorer and/or BigFix Web Reports instance collecting data from this Server."

This error means either the BigFix Web Reports or BigFix Explorer server is down, or is unreachable by the root server.

The result from these queries can change back and forth rapidly between different results if you
 have 2 different Web Reports servers sharing the same BFReporitingDB which is not supported.
******/
SELECT [WebReportsURL]
      ,[LastAggregatedTime]
      ,[SessionToken]
      ,[SSLCert]
      ,[WebReportsServerID]
      ,[Priority]
      ,[IsDeleted]
  FROM [BFEnterprise].[dbo].[AGGREGATEDBY]
