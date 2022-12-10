EXEC sp_configure 'clr enabled' , '1'; 
EXEC sp_configure 'clr strict security' , '0'; 
EXEC sp_add_trusted_assembly 0x652C9036D60C57D5AE9C6CF9AF92668E0F64897D59EBB4A67C80896D059A2E182B8B7451CADE813E2E5EA1FFF446348C4BC74396664E2ACF5C73EECCD3060826;
GO
RECONFIGURE
GO


CREATE ASSEMBLY HomeWork22
FROM 'F:\DB\OTUS\mssql-otus\homeworks\homework-22\HomeWork22\HomeWork22\bin\Debug\HomeWork22.dll'
WITH PERMISSION_SET = SAFE;


CREATE FUNCTION dbo.fn_IsINN(@Limit BIGINT)
RETURNS BIT
AS EXTERNAL NAME [HomeWork22].[HomeWork22.ApiHandler].IsINN;
GO

PRINT dbo.fn_IsInn(7731347089)


/*
CREATE FUNCTION dbo.fn_GetLatestPosts(@Limit INT)
RETURNS VARBINARY(MAX)
AS EXTERNAL NAME [HomeWork22].[HomeWork22.ApiHandler].GetLatestPosts;
GO*/


/*

CREATE FUNCTION dbo.fn_GetRandomString()
RETURNS VARBINARY
AS EXTERNAL NAME [HomeWork22].[HomeWork22.ApiHandler].GetString;
GO

DECLARE @str NVARCHAR(100)
SET @str = dbo.fn_GetRandomString()
PRINT @str


CREATE FUNCTION dbo.fn_GetLatestPosts(@Limit INT)
RETURNS VARBINARY(MAX)
AS EXTERNAL NAME [HomeWork22].[HomeWork22.ApiHandler].GetLatestPosts;
GO

DECLARE @str NVARCHAR(100)
SET @str = dbo.fn_GetLatestPosts(10)
PRINT @str




Сообщение 6522, уровень 16, состояние 2, строка 2
A .NET Framework error occurred during execution of user-defined routine or aggregate "fn_GetLatestPosts": 
System.Security.SecurityException: Сбой при запросе разрешения типа "System.Net.WebPermission, System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089".
System.Security.SecurityException: 
   в System.Security.CodeAccessSecurityEngine.Check(Object demand, StackCrawlMark& stackMark, Boolean isPermSet)
   в System.Security.CodeAccessPermission.Demand()
   в System.Net.HttpWebRequest.CheckConnectPermission(Uri uri, Boolean needExecutionContext)
   в System.Net.HttpWebRequest..ctor(Uri uri, ServicePoint servicePoint)
   в System.Net.HttpRequestCreator.Create(Uri Uri)
   в System.Net.WebRequest.Create(Uri requestUri, Boolean useUriBase)
   в HomeWork22.ApiHandler.GetLatestPosts(Int32 limit)
.

select
      HASHBYTES('SHA2_512', af.content)
    , a.clr_name
FROM sys.assemblies a
JOIN sys.assembly_files af
    ON a.assembly_id = af.assembly_id*/