/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

CREATE FUNCTION GetMaxExpensivePurchase()
RETURNS INT
AS  
BEGIN
	DECLARE @CustomerID INT;
	SELECT 
		@CustomerID = CustomerID
	FROM
	(
		SELECT 
				TOP(1)
				CustomerID
				, SUM(PositionSum) AS PurchaseSum
		FROM
		(
			SELECT    
					  Sales.Customers.CustomerID
					, Sales.Customers.CustomerName
					, Sales.Invoices.InvoiceID
					, Sales.InvoiceLines.Quantity * Sales.InvoiceLines.UnitPrice AS PositionSum
			FROM Sales.Customers
			INNER JOIN Sales.Invoices
			ON Sales.Customers.CustomerID = Sales.Invoices.CustomerID
			INNER JOIN Sales.InvoiceLines
			ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID 
		) AS t1
		GROUP BY CustomerID
		ORDER BY PurchaseSum DESC
	) AS t1
	RETURN @CustomerID
END

-- Использование
PRINT dbo.GetMaxExpensivePurchase()

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

CREATE PROCEDURE GetClientPurchase(@CustomerID INT)
AS
BEGIN

	DECLARE @PositionSum FLOAT;
	
	SELECT    
			  @PositionSum = SUM(Sales.InvoiceLines.Quantity * Sales.InvoiceLines.UnitPrice)
	FROM Sales.Customers
	INNER JOIN Sales.Invoices
	ON Sales.Customers.CustomerID = Sales.Invoices.CustomerID
	INNER JOIN Sales.InvoiceLines
	ON Sales.Invoices.InvoiceID = Sales.InvoiceLines.InvoiceID 
	WHERE Sales.Customers.CustomerID = @CustomerID
	GROUP BY Sales.Customers.CustomerID
	
	PRINT @PositionSum 

END 

-- Использование
EXEC dbo.GetClientPurchase 123

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

CREATE PROCEDURE GetCustomerInvoicesProcedure (@CustomerID INT)
AS
BEGIN
    SELECT 
        *
    FROM
        Sales.Invoices
    WHERE
        CustomerID = @CustomerID
END			



-- Использование

-- Процедура
EXEC GetCustomerInvoicesProcedure 123

-- Функция (создана в п.4)
SELECT * 
FROM dbo.GetCustomerInvoices(123) 

-- План запроса идентичный, у обеих по 50%. Наверное, нужны уточнения в каком случае результат будет разный


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

CREATE FUNCTION GetCustomerInvoices (
    @CustomerID INT
)
RETURNS TABLE
AS
RETURN
    SELECT 
        *
    FROM
        Sales.Invoices
    WHERE
        CustomerID = @CustomerID
		
-- Использование
SELECT 
		Purchases.*
FROM Sales.Customers
CROSS APPLY dbo.GetCustomerInvoices(Sales.Customers.CustomerID) AS Purchases		

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
