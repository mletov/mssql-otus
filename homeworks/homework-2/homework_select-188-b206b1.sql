/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT 
		StockItemID
	  , StockItemName
FROM Warehouse.StockItems
WHERE
		StockItemName LIKE '%urgent%'
		OR StockItemName LIKE 'Animal%' 

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT 
		Purchasing.Suppliers.SupplierID
	  , Purchasing.Suppliers.SupplierName
FROM Purchasing.Suppliers
LEFT JOIN Purchasing.PurchaseOrders
ON 
	Purchasing.Suppliers.SupplierID = Purchasing.PurchaseOrders.SupplierID
WHERE 
		Purchasing.PurchaseOrders.SupplierID IS NULL


/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


SELECT 
		Sales.Orders.OrderID
		, FORMAT(Sales.Orders.OrderDate, 'dd.MM.yyyy') AS OrderDate
		, FORMAT(Sales.Orders.OrderDate, 'MMMM') AS MonthName
		, DATEPART(quarter, Sales.Orders.OrderDate) AS QuarterName
		, (CASE
			WHEN MONTH(Sales.Orders.OrderDate) BETWEEN 1 AND 4
			THEN 1
			WHEN MONTH(Sales.Orders.OrderDate) BETWEEN 5 AND 8
			THEN 2
			WHEN MONTH(Sales.Orders.OrderDate) BETWEEN 9 AND 12
			THEN 3
		  END) AS ThirdName
		, Sales.Customers.CustomerName
FROM Sales.Orders

INNER JOIN Sales.Customers
ON Sales.Orders.CustomerID = Sales.Customers.CustomerID

INNER JOIN Sales.OrderLines
ON Sales.Orders.OrderID = Sales.OrderLines.OrderID

WHERE Sales.OrderLines.UnitPrice > 100
AND Sales.OrderLines.Quantity > 20
AND Sales.Orders.PickingCompletedWhen IS NOT NULL

GROUP BY Sales.Orders.OrderID
		, Sales.Orders.OrderDate
		, Sales.Customers.CustomerName

ORDER BY 
		 QuarterName,ThirdName,OrderDate

OFFSET 1000 ROWS
FETCH NEXT 100 ROWS ONLY		


/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
		Application.DeliveryMethods.DeliveryMethodName
		, Purchasing.PurchaseOrders.ExpectedDeliveryDate
		, Purchasing.Suppliers.SupplierName
		, Application.People.FullName AS ContactPersonName
FROM Purchasing.PurchaseOrders

INNER JOIN Application.DeliveryMethods
ON Purchasing.PurchaseOrders.DeliveryMethodID = Application.DeliveryMethods.DeliveryMethodID

INNER JOIN [Purchasing].[Suppliers]
ON Purchasing.PurchaseOrders.SupplierID = [Purchasing].[Suppliers].SupplierID

INNER JOIN Application.People
ON Purchasing.PurchaseOrders.ContactPersonId =  Application.People.PersonID

WHERE 
		YEAR(Purchasing.PurchaseOrders.ExpectedDeliveryDate) = 2013
		AND MONTH(Purchasing.PurchaseOrders.ExpectedDeliveryDate) = 1
		AND Application.DeliveryMethods.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')
		AND Purchasing.PurchaseOrders.IsOrderFinalized = 1


/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP(10)		
		Sales.Customers.CustomerName
	  , Application.People.FullName
		
FROM Sales.Orders

INNER JOIN Sales.Customers
ON Sales.Orders.CustomerID = Sales.Customers.CustomerID

INNER JOIN Application.People
ON Sales.Orders.SalespersonPersonID = Application.People.PersonID

ORDER BY 
			Sales.Orders.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT 
		Sales.Customers.CustomerID
		, Sales.Customers.CustomerName
		, Sales.Customers.PhoneNumber
FROM Sales.Customers

INNER JOIN Sales.Orders
ON Sales.Orders.CustomerID = Sales.Customers.CustomerID

INNER JOIN Sales.OrderLines
ON Sales.OrderLines.OrderID = Sales.Orders.OrderID

INNER JOIN Warehouse.StockItems
ON Sales.OrderLines.StockItemID = Warehouse.StockItems.StockItemID
AND Warehouse.StockItems.StockItemName = 'Chocolate frogs 250g'

GROUP BY 
		  Sales.Customers.CustomerID
		, Sales.Customers.CustomerName
		, Sales.Customers.PhoneNumber
