-- Посчитать среднюю цену товара, общую сумму продажи по месяцам.
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

-- Отобразить все месяцы, где общая сумма продаж превысила 4 600 000.
SELECT    
		YEAR([Sales].[Orders].OrderDate) AS OrderYear
	  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
FROM [Sales].[Orders]
INNER JOIN [Sales].[OrderLines]
ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
GROUP BY 
		YEAR([Sales].[Orders].OrderDate)
		, MONTH([Sales].[Orders].OrderDate)
HAVING SUM([Sales].[OrderLines].UnitPrice * [Sales].[OrderLines].Quantity) > 4600000

-- Вывести сумму продаж, дату первой продажи и количество проданного по месяцам, по товарам, продажи которых менее 50 ед в месяц. Группировка должна быть по году, месяцу, товару.

SELECT    
		YEAR([Sales].[Orders].OrderDate) AS OrderYear
	  , MONTH([Sales].[Orders].OrderDate) AS OrderMonth		
	  , MIN([Sales].[Orders].OrderDate) AS FirstDateSale
FROM [Sales].[Orders]
INNER JOIN [Sales].[OrderLines]
ON [Sales].[Orders].OrderID = [Sales].[OrderLines].OrderID
GROUP BY 
		YEAR([Sales].[Orders].OrderDate)
		, MONTH([Sales].[Orders].OrderDate)
		, Sales.OrderLines.StockItemID
HAVING COUNT(*) < 50	


-- Опционально:
-- Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
-- то этот месяц также отображался бы в результатах, но там были нули.