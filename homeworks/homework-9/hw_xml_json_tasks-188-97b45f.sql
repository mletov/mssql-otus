/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- ***************************************************************************************************************************************************
-- OPEN XML
-- ***************************************************************************************************************************************************

IF OBJECT_ID('tempdb..#tmp_StockItems') IS NOT NULL BEGIN DROP TABLE #tmp_StockItems; END

-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument  xml

-- Считываем XML-файл в переменную
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT *
INTO #tmp_StockItems
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH 
( 
	[StockItemName] NVARCHAR(100)  '@Name',
	[SupplierID] INT 'SupplierID',
	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] DECIMAL(18,2) 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] INT 'LeadTimeDays',	
	[IsChillerStock] BIT 'IsChillerStock',
	[TaxRate] DECIMAL(18,3) 'TaxRate',
	[UnitPrice] DECIMAL(18,2) 'UnitPrice'
)

SELECT *
FROM #tmp_StockItems


MERGE Warehouse.StockItems AS Base
USING #tmp_StockItems AS Source
ON (Base.StockItemName = Source.StockItemName) --Условие объединения
WHEN MATCHED THEN --Если истина (UPDATE)
UPDATE SET StockItemName = Source.StockItemName, 
		SupplierID = Source.SupplierID, 
		UnitPackageID = Source.UnitPackageID, 
		OuterPackageID = Source.OuterPackageID, 
		QuantityPerOuter = Source.QuantityPerOuter, 
		TypicalWeightPerUnit = Source.TypicalWeightPerUnit, 
		LeadTimeDays = Source.LeadTimeDays,	
		IsChillerStock = Source.IsChillerStock, 
		TaxRate = Source.TaxRate, 
		UnitPrice = Source.UnitPrice
WHEN NOT MATCHED THEN

INSERT
([StockItemName], [SupplierID], [UnitPackageID], [OuterPackageID], [QuantityPerOuter], [TypicalWeightPerUnit], [LeadTimeDays],	[IsChillerStock], [TaxRate], [UnitPrice], [LastEditedBy])
VALUES
(Source.StockItemName, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays,	Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, 1)
OUTPUT $action AS [OperationName]
				  , Inserted.StockItemName
                  , Deleted.StockItemName; 
				  
-- ***************************************************************************************************************************************************				  
-- XQuery
-- ***************************************************************************************************************************************************

IF OBJECT_ID('tempdb..#tmp_StockItems') IS NOT NULL BEGIN DROP TABLE #tmp_StockItems; END

-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument  xml

-- Считываем XML-файл в переменную
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItems-188-1fb5df.xml', 
 SINGLE_CLOB)
as data 

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument as [@xmlDocument]

DECLARE @docHandle int
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

SELECT *
INTO #tmp_StockItems
FROM 
(

	SELECT
				   StockItems.Item.value(N'@Name', N'NVARCHAR(100)') AS StockItemName
				,  StockItems.Item.value(N'SupplierID[1]', N'INT') AS SupplierID
				,  StockItems.Item.value(N'(Package[1]/UnitPackageID[1])', N'INT') AS UnitPackageID
				,  StockItems.Item.value(N'(Package[1]/OuterPackageID[1])', N'INT') AS OuterPackageID
				,  StockItems.Item.value(N'(Package[1]/QuantityPerOuter[1])', N'INT') AS QuantityPerOuter
				,  StockItems.Item.value(N'(Package[1]/TypicalWeightPerUnit)[1]', N'DECIMAL(18,2)') AS TypicalWeightPerUnit
				,  StockItems.Item.value(N'LeadTimeDays[1]', N'INT') AS LeadTimeDays
				,  StockItems.Item.value(N'IsChillerStock[1]', N'BIT') AS IsChillerStock
				,  StockItems.Item.value(N'TaxRate[1]', N'DECIMAL(18,3)') AS TaxRate
				,  StockItems.Item.value(N'UnitPrice[1]', N'DECIMAL(18,2)') AS UnitPrice
	FROM       @xmlDocument.nodes(N'/StockItems/Item') AS StockItems(Item)

) AS t1

SELECT *
FROM #tmp_StockItems


MERGE Warehouse.StockItems AS Base
USING #tmp_StockItems AS Source
ON (Base.StockItemName = Source.StockItemName) --Условие объединения
WHEN MATCHED THEN --Если истина (UPDATE)
UPDATE SET StockItemName = Source.StockItemName, 
		SupplierID = Source.SupplierID, 
		UnitPackageID = Source.UnitPackageID, 
		OuterPackageID = Source.OuterPackageID, 
		QuantityPerOuter = Source.QuantityPerOuter, 
		TypicalWeightPerUnit = Source.TypicalWeightPerUnit, 
		LeadTimeDays = Source.LeadTimeDays,	
		IsChillerStock = Source.IsChillerStock, 
		TaxRate = Source.TaxRate, 
		UnitPrice = Source.UnitPrice
WHEN NOT MATCHED THEN

INSERT
([StockItemName], [SupplierID], [UnitPackageID], [OuterPackageID], [QuantityPerOuter], [TypicalWeightPerUnit], [LeadTimeDays],	[IsChillerStock], [TaxRate], [UnitPrice], [LastEditedBy])
VALUES
(Source.StockItemName, Source.SupplierID, Source.UnitPackageID, Source.OuterPackageID, Source.QuantityPerOuter, Source.TypicalWeightPerUnit, Source.LeadTimeDays,	Source.IsChillerStock, Source.TaxRate, Source.UnitPrice, 1)
OUTPUT $action AS [OperationName]
				  , Inserted.StockItemName
                  , Deleted.StockItemName; 				  



/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/


DECLARE @Query AS VARCHAR(2000), @Query2 AS VARCHAR(2000)
SET @Query2 =  'SELECT StockItemName AS ""Item/@Name"", SupplierID AS ""Item/SupplierID"", UnitPackageID AS ""Item/Package/UnitPackageID"", OuterPackageID AS ""Item/Package/OuterPackageID"", QuantityPerOuter AS ""Item/Package/QuantityPerOuter"", TypicalWeightPerUnit AS ""Item/Package/TypicalWeightPerUnit"", LeadTimeDays AS ""Item/LeadTimeDays"", IsChillerStock AS ""Item/IsChillerStock"", TaxRate AS ""Item/TaxRate"", UnitPrice AS ""Item/UnitPrice"" FROM WideWorldImporters.Warehouse.StockItems FOR XML PATH('''') , ROOT(''StockItems''), TYPE;';
SET @Query = 'bcp "' +  @Query2 + '" queryout "F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItemsExport.xml" -T -w';
EXEC ..xp_cmdshell @Query


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

SELECT 
	   StockItemID
     , StockItemName
	 , CustomFields
	 , JSON_VALUE(CustomFields, '$.CountryOfManufacture') AS CountryOfManufacture
	 , JSON_VALUE(CustomFields, '$.Tags[0]') AS FirstTag
FROM Warehouse.StockItems

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

WITH cte
AS
(
	SELECT 
		   StockItemID
		 , StockItemName
		 , CustomFields
		 , j2.Value AS Tag
	FROM WideWorldImporters.Warehouse.StockItems
	CROSS APPLY OPENJSON(CustomFields, '$.Tags') j2
)

SELECT 
		StockItemID
	  , StockItemName
	  , STRING_AGG(Tag, ', ') AS Tags
FROM cte
WHERE StockItemID IN
(
	SELECT StockItemID
	FROM cte
	WHERE Tag = 'Vintage'
)
GROUP BY 
		   StockItemID
		 , StockItemName
		 , CustomFields
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
		 
/*
SELECT STUFF
(
    (
        SELECT CHAR(10) + tbl.TestText --you might use 13 and 10 here
        FROM @tbl AS tbl
        FOR XML PATH(''),TYPE
    ).value('.','nvarchar(max)'),1,1,''
)

SELECT 
	   StockItemName AS "Item/@Name"
	   , SupplierID AS "Item/SupplierID"
	   , UnitPackageID AS "Item/Package/UnitPackageID"
	   , OuterPackageID AS "Item/Package/OuterPackageID"
	   , QuantityPerOuter AS "Item/Package/QuantityPerOuter"
	   , TypicalWeightPerUnit AS "Item/Package/TypicalWeightPerUnit"

	   , LeadTimeDays AS "Item/LeadTimeDays"
	   , IsChillerStock AS "Item/IsChillerStock"
	   , TaxRate AS "Item/TaxRate"
	   , UnitPrice AS "Item/UnitPrice"
FROM Warehouse.StockItems FOR XML PATH('StockItems')


DECLARE @Query AS VARCHAR(1000)
SET @Query = 'bcp "SELECT * FROM [WideWorldImporters].[Warehouse].[StockItems] FOR XML PATH(''StockItems'')" queryout "F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItemsExport.xml" -T -c -t';

EXEC ..xp_cmdshell @Query

DECLARE @Query AS VARCHAR(2000)
SET @Query = 'bcp "SELECT 
StockItemName AS "Item/@Name"
, SupplierID AS "Item/SupplierID"

, UnitPackageID AS "Item/Package/UnitPackageID"
, OuterPackageID AS "Item/Package/OuterPackageID"
, QuantityPerOuter AS "Item/Package/QuantityPerOuter"
, TypicalWeightPerUnit AS "Item/Package/TypicalWeightPerUnit"

, LeadTimeDays AS "Item/LeadTimeDays"
, IsChillerStock AS "Item/IsChillerStock"
, TaxRate AS "Item/TaxRate"
, UnitPrice AS "Item/UnitPrice"
FROM Warehouse.StockItems FOR XML PATH(''StockItems'')" queryout "F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItemsExport.xml" -T -c -t';

EXEC ..xp_cmdshell @Query
*/

/*
SELECT 
	   StockItemName AS "Item/@Name"
	   , SupplierID AS "Item/SupplierID"
	   , UnitPackageID AS "Item/Package/UnitPackageID"
	   , OuterPackageID AS "Item/Package/OuterPackageID"
	   , QuantityPerOuter AS "Item/Package/QuantityPerOuter"
	   , TypicalWeightPerUnit AS "Item/Package/TypicalWeightPerUnit"
	   , LeadTimeDays AS "Item/LeadTimeDays"
	   , IsChillerStock AS "Item/IsChillerStock"
	   , TaxRate AS "Item/TaxRate"
	   , UnitPrice AS "Item/UnitPrice"
FROM Warehouse.StockItems FOR XML PATH('StockItems')


DECLARE @Query AS VARCHAR(2000), @Query2 AS VARCHAR(2000)
SET @Query2 =  'SELECT 
	   StockItemName AS "Item/@Name"
	   , SupplierID AS "Item/SupplierID"
	   , UnitPackageID AS "Item/Package/UnitPackageID"
	   , OuterPackageID AS "Item/Package/OuterPackageID"
	   , QuantityPerOuter AS "Item/Package/QuantityPerOuter"
	   , TypicalWeightPerUnit AS "Item/Package/TypicalWeightPerUnit"

	   , LeadTimeDays AS "Item/LeadTimeDays"
	   , IsChillerStock AS "Item/IsChillerStock"
	   , TaxRate AS "Item/TaxRate"
	   , UnitPrice AS "Item/UnitPrice"
FROM Warehouse.StockItems FOR XML PATH(''StockItems'')';


SET @Query = 'bcp "' +  @Query2 + '" queryout "F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItemsExport.xml" -T -c -t';

EXEC ..xp_cmdshell @Query


DECLARE @Query AS VARCHAR(2000), @Query2 AS VARCHAR(2000)
SET @Query2 =  'SELECT StockItemName AS "Item/@Name", SupplierID AS "Item/SupplierID", UnitPackageID AS "Item/Package/UnitPackageID", OuterPackageID AS "Item/Package/OuterPackageID", QuantityPerOuter AS "Item/Package/QuantityPerOuter", TypicalWeightPerUnit AS "Item/Package/TypicalWeightPerUnit", LeadTimeDays AS "Item/LeadTimeDays", IsChillerStock AS "Item/IsChillerStock", TaxRate AS "Item/TaxRate", UnitPrice AS "Item/UnitPrice" FROM Warehouse.StockItems FOR XML PATH(''StockItems'')';
SET @Query = 'bcp "' +  @Query2 + '" queryout "F:\DB\OTUS\mssql-otus\homeworks\homework-9\StockItemsExport.xml" -T -c -t';
EXEC ..xp_cmdshell @Query
*/
		 