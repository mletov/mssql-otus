/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

WITH cte_CountOrders
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
					  , REPLACE(REPLACE([Sales].[Customers].CustomerName, 'Tailspin Toys (', ''), ')','') AS CustomerName
					  , DATEADD(month, DATEDIFF(month, 0, [Sales].[Orders].OrderDate), 0) AS OrderDate

				FROM [Sales].[Orders]

				JOIN [Sales].[Customers]
				ON [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID

				WHERE [Sales].[Customers].CustomerID IN (2, 3, 4, 5, 6)
		) AS t1
		GROUP BY 
	
				CustomerID
			  , CustomerName
			  , OrderDate
)

SELECT    
	MonthFirstDay
  , ISNULL([Peeples Valley, AZ], 0) AS [Peeples Valley, AZ]
  , ISNULL([Gasport, NY], 0) AS [Gasport, NY]
  , ISNULL([Medicine Lodge, KS], 0) AS [Medicine Lodge, KS]
  , ISNULL([Sylvanite, MT], 0) AS [Sylvanite, MT]
  , ISNULL([Jessie, ND], 0) AS [Jessie, ND]
FROM  
(
	SELECT 
			CustomerName
		  , FORMAT (OrderDate, 'dd.MM.yyyy') AS MonthFirstDay
		  , CntOrders
	FROM cte_CountOrders
) AS SourceTable  
PIVOT  
( 
  SUM(CntOrders)
  FOR CustomerName IN ([Peeples Valley, AZ], [Gasport, NY], [Medicine Lodge, KS], [Sylvanite, MT], [Jessie, ND])  
) AS PivotTable;  

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

/****** Скрипт для команды SelectTopNRows из среды SSMS  ******/
  
SELECT CustomerName, AddressLine
FROM   
   (
   
		SELECT 
		   [CustomerName]
		  ,[DeliveryAddressLine1]
		  ,[DeliveryAddressLine2]
		  ,[DeliveryPostalCode]
		  ,[PostalAddressLine1]
		  ,[PostalAddressLine2]

	  FROM [WideWorldImporters].[Sales].[Customers]
	  WHERE CustomerName LIKE '%Tailspin Toys%'   
   ) p  
UNPIVOT  
   (AddressLine FOR CustomerName1 IN   
      ([DeliveryAddressLine1]
	  ,[DeliveryAddressLine2]
	  ,[PostalAddressLine1]
	  ,[PostalAddressLine2])  
)AS unpvt;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT CountryId, CountryName, Code
FROM   
(
	SELECT 
			CountryId
			, CountryName
			, IsoAlpha3Code
			, CAST(IsoNumericCode AS NVARCHAR(3)) AS IsoNumericCode
	FROM Application.Countries
) p  
UNPIVOT  
   (Code FOR CountryName1 IN   
      (IsoAlpha3Code, IsoNumericCode)  
)AS unpvt; 

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT 
		[Sales].[Customers].CustomerID
	  , [Sales].[Customers].CustomerName	  
	  , t1.StockItemID
	  , t1.UnitPrice
	  , t1.OrderDate
FROM [Sales].[Customers]
CROSS APPLY
(
	SELECT TOP(2)
	        [Sales].[OrderLines].StockItemID
		  , [Sales].[OrderLines].UnitPrice
		  , [Sales].[Orders].OrderDate
	
	FROM [Sales].[Orders]
	
	JOIN [Sales].[OrderLines]
	ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
	
	WHERE [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID	
) AS t1