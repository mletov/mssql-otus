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

-- Вариант 1
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
SET @Fields = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);
SET @Fields2 = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);

SET @Query = '  SELECT    
					InvoiceMonth
				  , ' + @Fields2 + '
				FROM  
				(
					SELECT 
							  c.CustomerID
							, c.CustomerName
							, CONVERT(nvarchar,CAST(DATEADD(month,DATEDIFF(month,0,i.InvoiceDate),0) as date),104) AS InvoiceMonth

					FROM [Sales].[Invoices] AS i

					JOIN #tmp_Customers AS c
					ON i.CustomerID = c.CustomerID
									
				) AS SourceTable  
				PIVOT  
				( 
					COUNT(CustomerID)
					FOR CustomerName IN (' + @Fields + ')  
				) AS PivotTable;';

EXEC sp_executesql  @Query




-- Вариант 2
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

SET @Fields = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('[', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);
SET @Fields2 = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX), CONCAT('ISNULL([', CustomerName, '], 0) AS [', CustomerName, ']')), ', ' ) AS CustomerName FROM #tmp_Customers);

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
				),
				cte2 AS
				(
					SELECT 
						  FORMAT (MonthFirstDay, ''dd.MM.yyyy'') AS MonthFirstDay
						, ' + @Fields + '
					FROM
					(
						SELECT    
							MonthFirstDay
						  , ' + @Fields2 + '
						FROM  
						(
							SELECT 
									CustomerName
								  , InvoiceDate AS MonthFirstDay
								  , CntOrders
							FROM cte
						) AS SourceTable  
						PIVOT  
						( 
						  SUM(CntOrders)
						  FOR CustomerName IN (' + @Fields + ')  
						) AS PivotTable
				   ) AS t1
			   )
			   
			   SELECT *
			   FROM cte2
			   ';
				
EXEC sp_executesql  @Query
































