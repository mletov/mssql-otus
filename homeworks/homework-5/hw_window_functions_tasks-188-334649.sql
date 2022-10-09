/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

WITH cte_Totals
AS
(
	SELECT 
			  DATEADD(month, DATEDIFF(month, 0, [Sales].Invoices.InvoiceDate), 0) AS FirstDate
			, SUM([Sales].OrderLines.UnitPrice * [Sales].OrderLines.Quantity) AS Total
	FROM [Sales].Invoices
	JOIN [Sales].OrderLines
	ON [Sales].Invoices.OrderID = [Sales].OrderLines.OrderID

	GROUP BY 
				DATEADD(month, DATEDIFF(month, 0, [Sales].Invoices.InvoiceDate), 0)
),
cte_AccumulateTotals
AS
(
	SELECT 
			FirstDate
          , Total
		  , ISNULL((SELECT SUM(Total) FROM cte_Totals AS t1 WHERE cte_Totals.FirstDate > t1.FirstDate), 0) AS CumulativeTotal
	FROM cte_Totals
)

SELECT DISTINCT 
	   [Sales].Invoices.InvoiceDate
	 , cte_AccumulateTotals.CumulativeTotal
FROM [Sales].Invoices

INNER JOIN cte_AccumulateTotals
ON YEAR([Sales].Invoices.InvoiceDate) =  YEAR(cte_AccumulateTotals.FirstDate)
AND MONTH([Sales].Invoices.InvoiceDate) =  MONTH(cte_AccumulateTotals.FirstDate)

WHERE YEAR([Sales].Invoices.InvoiceDate) >= 2015
ORDER BY [Sales].Invoices.InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

WITH cte_Totals
AS
(
	SELECT 
			  DATEADD(month, DATEDIFF(month, 0, [Sales].Invoices.InvoiceDate), 0) AS FirstDate
			, SUM([Sales].OrderLines.UnitPrice * [Sales].OrderLines.Quantity) AS Total
	FROM [Sales].Invoices
	JOIN [Sales].OrderLines
	ON [Sales].Invoices.OrderID = [Sales].OrderLines.OrderID

	GROUP BY 
				DATEADD(month, DATEDIFF(month, 0, [Sales].Invoices.InvoiceDate), 0)
),
cte_AccumulateTotals
AS
(
	SELECT 
			FirstDate
          , Total
		  , SUM(Total) OVER (ORDER BY FirstDate) - Total AS CumulativeTotal
	FROM cte_Totals
)

SELECT 
	   DISTINCT 
	   [Sales].Invoices.InvoiceDate
	 , cte_AccumulateTotals.CumulativeTotal
FROM [Sales].Invoices

INNER JOIN cte_AccumulateTotals
ON YEAR([Sales].Invoices.InvoiceDate) =  YEAR(cte_AccumulateTotals.FirstDate)
AND MONTH([Sales].Invoices.InvoiceDate) =  MONTH(cte_AccumulateTotals.FirstDate)

WHERE YEAR([Sales].Invoices.InvoiceDate) >= 2015
ORDER BY [Sales].Invoices.InvoiceDate

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

;WITH cte_Stat
AS
(
	SELECT 
			  MONTH([Sales].[Orders].OrderDate) AS MonthNum
			, [Warehouse].[StockItems].StockItemID
			, [Warehouse].[StockItems].StockItemName
			, SUM([Sales].[OrderLines].Quantity) AS Quantity
	FROM [Sales].[OrderLines]

	JOIN [Sales].[Orders]
	ON [Sales].[Orders].OrderId = [Sales].[OrderLines].OrderID

	JOIN [Warehouse].[StockItems]
	ON [Sales].[OrderLines].StockItemID = [Warehouse].[StockItems].StockItemID

	WHERE YEAR([Sales].[Orders].OrderDate) = 2016

	GROUP BY 
			  MONTH([Sales].[Orders].OrderDate)
			, [Warehouse].[StockItems].StockItemID
			, [Warehouse].[StockItems].StockItemName
),
cte_StatRn
AS
(
	SELECT 
		  *
		, ROW_NUMBER() OVER(PARTITION BY MonthNum ORDER BY Quantity DESC) AS Rn
	FROM cte_Stat
)

SELECT 
		  *
FROM cte_StatRn
WHERE Rn <= 2
ORDER BY
		 MonthNum
	   , Rn


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/


SELECT 
		StockItemID
		, StockItemName
		, ROW_NUMBER() OVER(PARTITION BY SUBSTRING(StockItemName, 1, 1) ORDER BY StockItemName) AS RnByFirstLetter		
		, COUNT(*) OVER(ORDER BY StockItemName ROWs BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED Following) CountAll
		, COUNT(*) OVER(PARTITION BY SUBSTRING(StockItemName, 1, 1) ORDER BY StockItemName ROWs BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED Following) SumByFirstLetter		
		, LEAD(StockItemID) OVER (ORDER BY StockItemName) AS NextStockItemId
		, LAG(StockItemID) OVER (ORDER BY StockItemName) AS PrevStockItemId
		, ISNULL(LAG(StockItemName, 2) OVER (ORDER BY StockItemName), 'No item') AS StockItemName2RowsAgo
		, NTILE (30) OVER (ORDER BY TypicalWeightPerUnit) AS TypicalWeightPerUnitGroup
FROM [Warehouse].[StockItems]
ORDER BY StockItemName


/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT 
		SalespersonPersonID
	  , SalesPersonName
	  , CustomerID
	  , CustomerName
FROM
(
	SELECT 
			[Sales].[Orders].SalespersonPersonID
		  , Application.People.FullName AS SalesPersonName
		  , [WideWorldImporters].[Sales].[Orders].CustomerID		  
		  , [Sales].[Customers].CustomerName
		  , ROW_NUMBER() OVER(PARTITION BY [WideWorldImporters].[Sales].[Orders].SalespersonPersonID ORDER BY [WideWorldImporters].[Sales].[Orders].OrderDate DESC) AS rn
	FROM [Sales].[Orders]
	
	JOIN [Sales].[Customers]
	ON [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID
	
	JOIN Application.People
	ON People.PersonID = [Sales].[Orders].SalespersonPersonID
) AS t1
WHERE rn = 1

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
 
SELECT
		  CustomerID
		, CustomerName
		, StockItemID
		, UnitPrice
		, OrderDate
FROM
(
	SELECT 
			[Sales].[Customers].CustomerID
		  , [Sales].[Customers].CustomerName
		  , [Sales].[OrderLines].StockItemID
		  , [Sales].[OrderLines].UnitPrice
		  , [Sales].[Orders].OrderDate
		  , ROW_NUMBER() OVER(PARTITION BY [Sales].[Orders].CustomerID ORDER BY [Sales].[OrderLines].UnitPrice DESC) AS Rn
	FROM [Sales].[Orders]

	JOIN [Sales].[OrderLines]
	ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
	
	JOIN [Sales].[Customers]
	ON [Sales].[Orders].CustomerID = [Sales].[Customers].CustomerID
) AS t1
WHERE Rn <= 2

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 