/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/


IF OBJECT_ID('tempdb..#tmp_Customers') IS NOT NULL BEGIN DROP TABLE #tmp_Customers; END
 
SELECT *
INTO #tmp_Customers
FROM
(
	SELECT *
	FROM [Sales].[Customers]
	WHERE CustomerID IN
	(
		SELECT CustomerID
		FROM [Sales].[Invoices]
	)
) AS t1
				
DECLARE @Query NVARCHAR(MAX), @Fields NVARCHAR(MAX), @Fields2 NVARCHAR(MAX);

SET @Fields = (SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);
SET @Fields2 = (SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);

SET @Query = '  WITH cte
				AS
				(
						SELECT 
								CustomerID
								, CustomerName
								, InvoiceDate
								, COUNT(CustomerID) AS CntOrders
								FROM
								(
									SELECT 
											  #tmp_Customers.CustomerID
											, #tmp_Customers.CustomerName
											, DATEADD(month, DATEDIFF(month, 0, [Sales].[Invoices].InvoiceDate), 0) AS InvoiceDate

									FROM [Sales].[Invoices]

									JOIN #tmp_Customers
									ON [Sales].[Invoices].CustomerID = #tmp_Customers.CustomerID
							) AS t1
							GROUP BY 
					
									CustomerID
									, CustomerName
									, InvoiceDate
				)

				SELECT    
					MonthFirstDay
				  , ' + @Fields2 + '
				FROM  
				(
					SELECT 
							CustomerName
						  , FORMAT (InvoiceDate, ''dd.MM.yyyy'') AS MonthFirstDay
						  , CntOrders
					FROM cte
				) AS SourceTable  
				PIVOT  
				( 
				  SUM(CntOrders)
				  FOR CustomerName IN (' + @Fields + ')  
				) AS PivotTable;';

EXEC sp_executesql  @Query

















/*

IF OBJECT_ID('tempdb..#tmp_Customers') IS NOT NULL BEGIN DROP TABLE #tmp_Customers; END

SELECT *
INTO #tmp_Customers
FROM
(

	SELECT 
			*
			, ROW_NUMBER() OVER(ORDER BY CustomerID) AS Rn
	FROM [Sales].[Customers]
) AS t1


DECLARE @Query NVARCHAR(MAX), @QueryCte NVARCHAR(MAX), @QueryJoin NVARCHAR(MAX), @Fields NVARCHAR(MAX), @Fields2 NVARCHAR(MAX), @Pos INT = 1, @Limit INT = 100, @MaxRowNum INT;


SET @MaxRowNum = (SELECT MAX(Rn) AS Rn FROM #tmp_Customers);

SET @QueryCte = '  WITH cte_Dates
					AS
					(
						SELECT DISTINCT DATEADD(month, DATEDIFF(month, 0, [Sales].[Orders].OrderDate), 0) AS OrderDate
						FROM [Sales].[Orders]
					), cte_Customets
					AS
					(
							SELECT 
									CustomerID
									, CustomerName
									, OrderDate
									, COUNT(CustomerID) AS CntOrders
									FROM
									(
										SELECT 
												  [Sales].[Customers].CustomerID
												, [Sales].[Customers].CustomerName
												, DATEADD(month, DATEDIFF(month, 0, [Sales].[Orders].OrderDate), 0) AS OrderDate

										FROM [Sales].[Orders]

										JOIN [Sales].[Customers]
										ON [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID
								) AS t1
								GROUP BY 
						
										CustomerID
										, CustomerName
										, OrderDate
					)';
					

WHILE ( @Pos <= @MaxRowNum)
BEGIN
	SET @Fields = (
						SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName 
						FROM #tmp_Customers 
						WHERE Rn BETWEEN @Pos AND (@Pos + @Limit - 1)
					);
	SET @Fields2 = (
						SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName 
						FROM #tmp_Customers 
						WHERE Rn BETWEEN @Pos AND (@Pos + @Limit - 1)
					);

	SET @QueryCte =  @QueryCte + ',
	cte_' + CAST(@Pos AS NVARCHAR(MAX)) + '
	AS 
	(
		SELECT    
			MonthFirstDay
			, ' + @Fields2 + '
		FROM  
		(
			SELECT 
					CustomerName
					, FORMAT (OrderDate, ''dd.MM.yyyy'') AS MonthFirstDay
					, CntOrders
			FROM cte
		) AS SourceTable  
		PIVOT  
		( 
			SUM(CntOrders)
			FOR CustomerName IN (' + @Fields + ')  
		) AS PivotTable;
	)';

	PRINT @Pos

    SET @Pos  = @Pos  + @Limit;
END	



IF OBJECT_ID('tempdb..#tmp_Customers') IS NOT NULL BEGIN DROP TABLE #tmp_Customers; END


SELECT *
INTO #tmp_Customers
FROM
(

	SELECT 
			*
			, ROW_NUMBER() OVER(ORDER BY ) AS Rn
	FROM [Sales].[Customers]
) AS 

DECLARE @Query NVARCHAR(MAX), @QueryCte NVARCHAR(MAX), @QueryJoin NVARCHAR(MAX), @Fields NVARCHAR(MAX), @Fields2 NVARCHAR(MAX), @Pos INT = 1, @Limit INT = 1000, @MaxRowNum INT;

SET @MaxRowNum = (SELECT MAX(Rn) AS Rn FROM #tmp_Customers);

SET @QueryCte = '  WITH cte_Dates
					AS
					(
						SELECT DISTINCT DATEADD(month, DATEDIFF(month, 0, [Sales].[Orders].OrderDate), 0) AS OrderDate
						FROM [Sales].[Orders]
					), cte_Customets
					AS
					(
							SELECT 
									CustomerID
									, CustomerName
									, OrderDate
									, COUNT(CustomerID) AS CntOrders
									FROM
									(
										SELECT 
												  [Sales].[Customers].CustomerID
												, [Sales].[Customers].CustomerName
												, DATEADD(month, DATEDIFF(month, 0, [Sales].[Orders].OrderDate), 0) AS OrderDate

										FROM [Sales].[Orders]

										JOIN [Sales].[Customers]
										ON [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID
								) AS t1
								GROUP BY 
						
										CustomerID
										, CustomerName
										, OrderDate
					);';
					

WHILE ( @Pos <= @MaxRowNum)
BEGIN
	SET @Fields = (
						SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName 
						FROM #tmp_Customers 
						WHERE Rn BETWEEN @Pos AND (@Pos + @Limit - 1)
					);
	SET @Fields2 = (
						SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName 
						FROM #tmp_Customers 
						WHERE Rn BETWEEN @Pos AND (@Pos + @Limit - 1)
					);


    SET @Pos  = @Pos  + @Limit;
END					
					
					
SET @Fields = (SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName FROM [Sales].[Customers] WHERE [Sales].[Customers].CustomerID < 1000);
SET @Fields2 = (SELECT DISTINCT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName FROM [Sales].[Customers] WHERE [Sales].[Customers].CustomerID < 1000);

SET @Query =  @Query + '
				SELECT    
					MonthFirstDay
				  , ' + @Fields2 + '
				FROM  
				(
					SELECT 
							CustomerName
						  , FORMAT (OrderDate, ''dd.MM.yyyy'') AS MonthFirstDay
						  , CntOrders
					FROM cte
				) AS SourceTable  
				PIVOT  
				( 
				  SUM(CntOrders)
				  FOR CustomerName IN (' + @Fields + ')  
				) AS PivotTable;';

EXEC sp_executesql  @Query*/