/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT  
	YEAR([Sales].[Orders].OrderDate) AS OrderYear
	, MONTH([Sales].[Orders].OrderDate) AS OrderMonth
	, AVG([Sales].[OrderLines].UnitPrice) AS AvgPrice
	, SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) AS SumPrice
FROM [Sales].[Orders]
INNER JOIN [Sales].[OrderLines]
ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
GROUP BY 
		YEAR([Sales].[Orders].OrderDate)
	  , MONTH([Sales].[Orders].OrderDate)

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT    
		YEAR([Sales].[Orders].OrderDate) AS OrderYear
	  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
	  , SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) AS SumPrice
	  , SUM([Sales].[OrderLines].Quantity) AS QuantityAll
FROM [Sales].[Orders]
INNER JOIN [Sales].[OrderLines]
ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
GROUP BY 
		YEAR([Sales].[Orders].OrderDate)
		, MONTH([Sales].[Orders].OrderDate)
HAVING SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) > 4600000

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT    
		YEAR([Sales].[Orders].OrderDate) AS OrderYear
	  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
	  , Warehouse.StockItems.StockItemName
	  , SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) AS SumPrice
	  , MIN([Sales].[Orders].OrderDate) AS FirstDateSale
	  , SUM([Sales].[OrderLines].Quantity) AS CountUnits
FROM [Sales].[Orders]

INNER JOIN [Sales].[OrderLines]
ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID

INNER JOIN Warehouse.StockItems
ON Sales.OrderLines.StockItemID = Warehouse.StockItems.StockItemID

GROUP BY 
		YEAR([Sales].[Orders].OrderDate)
		, MONTH([Sales].[Orders].OrderDate)
		, Sales.OrderLines.StockItemID
		, Warehouse.StockItems.StockItemName
HAVING COUNT(*) < 50

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

-- Для каждого товара для каждого месяца в году, значения только если сумма продаже превысила 4600000
SELECT 
		Months.SalesMonth
	  , Years.SalesYear
	  , ISNULL(SumPrice,0) AS SumPrice
	  , ISNULL(QuantityAll,0) AS QuantityAll
FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS Months (SalesMonth) 
CROSS JOIN 
(SELECT DISTINCT YEAR(OrderDate) AS SalesYear FROM [Sales].[Orders]) AS Years
LEFT JOIN
(
	SELECT    
			YEAR([Sales].[Orders].OrderDate) AS OrderYear
		  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
		  , SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) AS SumPrice
		  , SUM([Sales].[OrderLines].Quantity) AS QuantityAll
	FROM [Sales].[Orders]
	INNER JOIN [Sales].[OrderLines]
	ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
	GROUP BY 
			YEAR([Sales].[Orders].OrderDate)
			, MONTH([Sales].[Orders].OrderDate)
	HAVING SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) > 4600000
) AS Sales
ON Months.SalesMonth = Sales.OrderMonth
AND Years.SalesYear = Sales.OrderYear


-- Для каждого товара для каждого месяца в году, значения только если товара продали меньше 50 шт в этом месяце
SELECT 
		Months.SalesMonth
	  , Years.SalesYear
	  , Warehouse.StockItems.StockItemName
	  , ISNULL(SumPrice, 0) AS SumPrice
	  , ISNULL(FirstDateSale, NULL) AS FirstDateSale
	  , ISNULL(CountUnits, 0) AS CountUnits

FROM (VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10), (11), (12)) AS Months (SalesMonth) 
CROSS JOIN 
(SELECT DISTINCT YEAR(OrderDate) AS SalesYear FROM [Sales].[Orders]) AS Years
CROSS JOIN Warehouse.StockItems
LEFT JOIN
(
	SELECT    
			YEAR([Sales].[Orders].OrderDate) AS OrderYear
		  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
		  , Warehouse.StockItems.StockItemName
		  , SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) AS SumPrice
		  , MIN([Sales].[Orders].OrderDate) AS FirstDateSale
		  , SUM([Sales].[OrderLines].Quantity) AS CountUnits
		  , Sales.OrderLines.StockItemID
	FROM [Sales].[Orders]

	INNER JOIN [Sales].[OrderLines]
	ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID

	INNER JOIN Warehouse.StockItems
	ON Sales.OrderLines.StockItemID = Warehouse.StockItems.StockItemID

	GROUP BY 
			YEAR([Sales].[Orders].OrderDate)
			, MONTH([Sales].[Orders].OrderDate)
			, Sales.OrderLines.StockItemID
			, Warehouse.StockItems.StockItemName
	HAVING COUNT(*) < 50
) AS Sales
ON Months.SalesMonth = Sales.OrderMonth
AND Years.SalesYear = Sales.OrderYear
AND Warehouse.StockItems.StockItemID = Sales.StockItemID