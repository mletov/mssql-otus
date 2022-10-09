/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT 
		PersonID
		, FullName
FROM Application.People
WHERE Application.People.IsSalesperson = 1
AND Application.People.PersonID
NOT IN
(
	SELECT SalespersonPersonID
	FROM [WideWorldImporters].[Sales].[Invoices]
	WHERE CAST(InvoiceDate AS DATE) = '2015-07-04'
)

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

-- 1
SELECT 
		StockItemID
	  , StockItemName
FROM Warehouse.StockItems
WHERE Warehouse.StockItems.UnitPrice = (SELECT MIN(Warehouse.StockItems.UnitPrice) FROM Warehouse.StockItems)

-- 2
SELECT 
		StockItemID
	  , StockItemName
FROM Warehouse.StockItems
WHERE Warehouse.StockItems.UnitPrice = (SELECT TOP(1) Warehouse.StockItems.UnitPrice FROM Warehouse.StockItems ORDER BY  Warehouse.StockItems.UnitPrice)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

-- 1
SELECT 
		CustomerID
	  , CustomerName
FROM Sales.Customers
WHERE CustomerID IN
(
	SELECT TOP(5) CustomerID
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)

-- 2
;WITH cte AS
(
	SELECT TOP(5) CustomerID
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC
)

SELECT 
		CustomerID
	  , CustomerName
FROM Sales.Customers
WHERE CustomerID IN
(
	SELECT CustomerID
	FROM cte
)

-- 3
SELECT 
		DISTINCT CustomerID
		, CustomerName
FROM
(
	SELECT TOP(5) 
				Sales.CustomerTransactions.CustomerID
				, Sales.Customers.CustomerName
	FROM Sales.CustomerTransactions
	INNER JOIN Sales.Customers
	ON Sales.CustomerTransactions.CustomerID =  Sales.Customers.CustomerID
	ORDER BY Sales.CustomerTransactions.TransactionAmount DESC
) AS t1

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT DISTINCT
		[Application].[Cities].CityID
		, [Application].[Cities].CityName
		, [Sales].[Invoices].PackedByPersonID
FROM [Sales].[OrderLines]

JOIN [Sales].[Orders]
ON [Sales].[Orders].OrderId = [Sales].[OrderLines].OrderID

JOIN [Sales].[Customers]
ON [Sales].[Customers].CustomerID = [Sales].[Orders].CustomerID

JOIN [Application].[Cities]
ON [Application].[Cities].CityID = [Sales].[Customers].DeliveryCityID


JOIN [Sales].[Invoices]
ON [Sales].[Invoices].OrderID = [Sales].[Orders].OrderID

WHERE [Sales].[OrderLines].StockItemID IN
(
	SELECT TOP(3) StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC
)

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

GO         
SET STATISTICS IO ON;  
GO 

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- Соотношение стоимости с изначальным запросом 73% / 27%


;WITH cte_Invoices 
AS
(
	SELECT 
		  Sales.InvoiceLines.InvoiceId 
		  , SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY 
			Sales.InvoiceLines.InvoiceId
	HAVING SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) > 27000
),
cte_OrderSums
AS
(
	SELECT 
			Sales.Orders.OrderId
		  , MAX(cte_Invoices.TotalSumm) AS TotalSumm
		  , SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) AS TotalSummForPickedItems
	FROM Sales.OrderLines
	
	JOIN Sales.Orders
	ON Sales.Orders.OrderId = Sales.OrderLines.OrderId
	AND Orders.PickingCompletedWhen IS NOT NULL
	
	JOIN Sales.Invoices 
	ON Sales.Orders.OrderId = Invoices.OrderId
	
	JOIN cte_Invoices 
	ON Sales.Invoices.InvoiceID  = cte_Invoices.InvoiceID
	
	GROUP BY 
				Sales.Orders.OrderId
)

SELECT 
	Invoices.InvoiceID
	, Invoices.InvoiceDate
	, Application.People.FullName AS SalesPersonName
	, cte_OrderSums.TotalSumm AS TotalSummByInvoice
	, cte_OrderSums.TotalSummForPickedItems AS TotalSummForPickedItems
	
FROM cte_OrderSums 

JOIN Sales.Invoices
ON cte_OrderSums.OrderId = Invoices.OrderId

JOIN Application.People
ON People.PersonID = Sales.Invoices.SalespersonPersonID

ORDER BY 
			TotalSumm DESC





/*

-- 1

;WITH cte 
AS
(
	SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) > 27000
),
cte_OrderSums
AS
(
	SELECT 
			Sales.Orders.OrderId
		  , SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) AS TotalSummForPickedItems
	FROM Sales.OrderLines
	
	JOIN Sales.Orders
	ON Sales.Orders.OrderId = Sales.OrderLines.OrderId
	AND Orders.PickingCompletedWhen IS NOT NULL
	
	GROUP BY Sales.Orders.OrderId
)

SELECT 
	Invoices.InvoiceID
	, Invoices.InvoiceDate
	, Application.People.FullName AS SalesPersonName
	, SalesTotals.TotalSumm AS TotalSummByInvoice
	, cte_OrderSums.TotalSummForPickedItems AS TotalSummForPickedItems
	
FROM Sales.Invoices 

JOIN cte AS SalesTotals
ON Invoices.InvoiceID = SalesTotals.InvoiceID

JOIN Application.People
ON People.PersonID = Sales.Invoices.SalespersonPersonID

JOIN cte_OrderSums
ON cte_OrderSums.OrderId = Invoices.OrderId

ORDER BY TotalSumm DESC




-- 2
;WITH cte_OrderSums
AS
(
	SELECT 
			Sales.Orders.OrderId
		  , SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice) AS TotalSummForPickedItems
	FROM Sales.OrderLines
	
	JOIN Sales.Orders
	ON Sales.Orders.OrderId = Sales.OrderLines.OrderId
	AND Orders.PickingCompletedWhen IS NOT NULL
	
	GROUP BY Sales.Orders.OrderId
)

SELECT 
	Invoices.InvoiceID
	, Invoices.InvoiceDate
	, Application.People.FullName AS SalesPersonName
	, SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) AS TotalSumm
	, cte_OrderSums.TotalSummForPickedItems
	
FROM Sales.Invoices 

JOIN Application.People
ON People.PersonID = Sales.Invoices.SalespersonPersonID

JOIN Sales.InvoiceLines
ON Invoices.InvoiceID = Sales.InvoiceLines.InvoiceId

JOIN cte_OrderSums
ON cte_OrderSums.OrderId = Invoices.OrderId

GROUP BY 
		  Invoices.InvoiceID
		, Invoices.InvoiceDate
		, Application.People.FullName
		, Sales.Invoices.OrderID
		, cte_OrderSums.TotalSummForPickedItems
		
HAVING SUM(Sales.InvoiceLines.Quantity*Sales.InvoiceLines.UnitPrice) > 27000

GO  
SET STATISTICS IO OFF;  
GO 


-- 3
*/