/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

WITH cte_Customers
AS
(
	SELECT 
		     'Ivanov Ivan Ivanovich' AS [CustomerName]
		  , 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]

	UNION 
	SELECT 
		'Petrov Petr Petrovich' AS [CustomerName] 
		, 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]
	UNION 
	SELECT 
		'Sidorov Sidor Sidorovich' AS [CustomerName] 
		, 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]
	UNION 
	SELECT 
		'Vasiliev Vasiliy Vasilievich' AS [CustomerName] 
		, 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]
	UNION 
	SELECT 
		'Kuznecov Kuznec Kuznecivich' AS [CustomerName] 
		, 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]
)

INSERT INTO 
Sales.Customers 
(CustomerName , BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID
, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent
, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryPostalCode, PostalPostalCode
, PostalAddressLine1, LastEditedBy)
SELECT * FROM cte_Customers	 


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

WITH MyCTE 
AS 
(
	SELECT TOP(1) *
	FROM Sales.Customers 
	ORDER BY CustomerID DESC
)
DELETE FROM MyCTE


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

WITH MyCTE 
AS 
(
	SELECT TOP(1) *
	FROM Sales.Customers 
	ORDER BY CustomerID DESC
)
UPDATE TOP(1) Sales.Customers
SET WebsiteURL = 'https://otus.ru/'


/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers AS Base
USING
(
	SELECT 		  
		   'Ivanov Ivan Ivanovich' AS [CustomerName]
		  , 1 AS [BillToCustomerID]
		  , 3 AS [CustomerCategoryID]
		  , 1 AS [BuyingGroupID]
		  , 1025 AS [PrimaryContactPersonID]
		  , 1026 AS [AlternateContactPersonID]
		  , 3 AS [DeliveryMethodID]
		  , 32887 AS [DeliveryCityID]
		  , 24805 AS [PostalCityID]
		  , 2100 AS [CreditLimit]
		  , '2013-01-01' AS [AccountOpenedDate]
		  , 0 AS [StandardDiscountPercentage]
		  , 1 AS [IsStatementSent]
		  , 1 AS [IsOnCreditHold]
		  , 123 AS [PaymentDays]
		  , '1234567' AS [PhoneNumber]
		  , '1234567' AS [FaxNumber]
		  , 'https://yandex.ru' AS [WebsiteURL]
		  , 'SDf sdfg dsfg sdfg dfg' AS [DeliveryAddressLine1]
		  , '1234567' AS [DeliveryPostalCode]
		  , '12345' AS [PostalPostalCode]
		  , '43242352345' AS [PostalAddressLine1]
		  , 1 AS [LastEditedBy]
) AS Source
ON (Base.CustomerName = Source.CustomerName) --Условие объединения
WHEN MATCHED THEN --Если истина (UPDATE)
                 UPDATE SET WebsiteURL = 'https://otus.ru/', CreditLimit = 99999
WHEN NOT MATCHED THEN --Если НЕ истина (INSERT)
		 INSERT (
					CustomerName 
					, BillToCustomerID
					, CustomerCategoryID
					, BuyingGroupID
					, PrimaryContactPersonID
					, AlternateContactPersonID
					, DeliveryMethodID
				    , DeliveryCityID
				    , PostalCityID
				    , CreditLimit
				    , AccountOpenedDate
				    , StandardDiscountPercentage
				    , IsStatementSent
				    , IsOnCreditHold
				    , PaymentDays
				    , PhoneNumber
				    , FaxNumber
				    , WebsiteURL
					, DeliveryAddressLine1
				    , DeliveryPostalCode
				    , PostalPostalCode
					, PostalAddressLine1
				    , LastEditedBy
				) 
		 VALUES 
		 (
				Source.CustomerName 
				, Source.BillToCustomerID
				, Source.CustomerCategoryID
				, Source.BuyingGroupID
				, Source.PrimaryContactPersonID
				, Source.AlternateContactPersonID
				, Source.DeliveryMethodID
				, Source.DeliveryCityID
				, Source.PostalCityID
				, Source.CreditLimit
				, Source.AccountOpenedDate
				, Source.StandardDiscountPercentage
				, Source.IsStatementSent
				, Source.IsOnCreditHold
				, Source.PaymentDays
				, Source.PhoneNumber
				, Source.FaxNumber
				, Source.WebsiteURL
				, DeliveryAddressLine1
				, Source.DeliveryPostalCode
				, Source.PostalPostalCode
				, Source.PostalAddressLine1
				, Source.LastEditedBy		 
		 )
		--Посмотрим, что мы сделали
        OUTPUT $action AS [OperationName]
				  , Inserted.CustomerName
                  , Inserted.WebsiteURL
                  , Deleted.CustomerName
                  , Deleted.WebsiteURL; 
		 
      
      

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

/*
-- To allow advanced options to be changed.  
EXECUTE sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXECUTE sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO  */

-- Экспорт
DECLARE @Query AS VARCHAR(1000)
SET @Query = 'bcp [WideWorldImporters].Sales.Customers out "F:\DB\OTUS\mssql-otus\datafile.csv" -T -w -t"<delimeter>" -S ' + (SELECT @@SERVERNAME);

EXEC ..xp_cmdshell @Query

-- Импорт через bulk insert
-- Импортируем в CustomersNew (копию Customers), чтобы не было конфликта вставляемых имен пользователей
BULK INSERT [WideWorldImporters].Sales.CustomersNew
FROM 'F:\DB\OTUS\mssql-otus\datafile.csv'
WITH 
(
	FIELDTERMINATOR = '<delimeter>'
)