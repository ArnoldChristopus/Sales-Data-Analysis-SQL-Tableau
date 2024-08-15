-- https://data.world/thegove/redcat/workspace/file?filename=WageEmployee
/*
DATA CLEANING
*/
-- Checking for nulls or empty strings in products table
-- Since these tables have a lot of rows, I use IS NULL to quickly find if there is empty data in the table
SELECT *
FROM dbsales.products
WHERE
	NULLIF(productid, ' ') IS NULL OR
	NULLIF(productname, ' ') IS NULL OR
    NULLIF(manufacturerid, ' ') IS NULL OR
    NULLIF(composition, ' ') IS NULL OR
    NULLIF(listprice, ' ') IS NULL OR
    NULLIF(gender, ' ') IS NULL OR
    NULLIF(category, ' ') IS NULL OR
    NULLIF(color, ' ') IS NULL OR
    NULLIF(description, ' ') IS NULL;


SELECT composition
FROM dbsales.products
WHERE composition LIKE '%made%'
ORDER BY composition;


-- Changing the variation of 'man made' so that they're all the same
UPDATE dbsales.products
SET composition = LOWER(composition);


UPDATE
	dbsales.products
SET
	composition = REPLACE(
		REPLACE(
			REPLACE(
				composition, 'man made', 'man-made'
			), 'all ', ''
		), 'materials', 'material'
	);


UPDATE dbsales.products
SET composition = CONCAT(UPPER(LEFT(composition, 1)), RIGHT(composition, LENGTH(composition)-1));


-- Checking for nulls or empty strings in customer table
SELECT *
FROM dbsales.customer
WHERE NULLIF(customerid, '') IS NULL OR
	NULLIF(firstname, '') IS NULL OR
    NULLIF(lastname, '') IS NULL OR
    NULLIF(streetaddress, '') IS NULL OR
    NULLIF(city, '') IS NULL OR
    NULLIF(state, '') IS NULL OR
    NULLIF(postalcode, '') IS NULL OR
    NULLIF(country, '') IS NULL OR
    NULLIF(phone, '') IS NULL;



-- Checking for nulls or empty strings in sale table
ALTER TABLE dbsales.sale
DROP COLUMN tax;


UPDATE dbsales.sale
SET saledate = LEFT(saledate,10);


SELECT *
FROM dbsales.sale
WHERE
	saleid IN ('', NULL) OR
    saledate IN ('', NULL) OR
    customerid IN ('', NULL) OR
    shipping IN ('', NULL);



-- Checking for nulls or empty strings in purchaseitem table
SELECT *
FROM dbsales.saleitem
WHERE NULLIF(productid, '') IS NULL OR
	NULLIF(itemsize, '') IS NULL OR
    NULLIF(saleid, '') IS NULL OR
    NULLIF(quantity, '') IS NULL OR
    NULLIF(saleprice, '') IS NULL;
    
    

-- Checking for nulls or empty strings in purchase table
SELECT *
FROM dbsales.purchase
WHERE
	purchaseid IN ('', NULL) OR
	purchasedate IN ('', NULL) OR
    employeeid IN ('', NULL) OR
    expecteddeliverydate IN ('', NULL) OR
    manufacturerid IN ('', NULL) OR
    shipping IN ('', NULL);


-- Checking for nulls or empty strings in purchaseitem table
SELECT *
FROM dbsales.purchaseitem
WHERE NULLIF(productid, '') IS NULL OR
	NULLIF(itemsize, '') IS NULL OR
    NULLIF(purchaseid, '') IS NULL OR
    NULLIF(quantity, '') IS NULL OR
    NULLIF(purchaseprice, '') IS NULL;
    
    
-- Checking for nulls or empty strings in employee table
-- Since these tables have few rows, it would be easy to spot empty data, so there's no need to use IS NULL
SELECT *
FROM dbsales.employee;
    
    
-- Checking for nulls or empty strings in salaryemployee table
SELECT *
FROM dbsales.salaryemployee;
    
    
-- Checking for nulls or empty strings in wageemployee table
SELECT *
FROM dbsales.wageemployee;
    

/*
EXPLORATORY DATA ANALYSIS
*/
-- Product with the highest sales
SELECT si.productid, ProductName, sum(SalePrice*quantity) as TotalRevenue, sum(Quantity) as TotalQuantity
FROM dbsales.saleitem si
LEFT JOIN dbsales.products pd ON si.productid = pd.productid
GROUP BY si.productid, ProductName
ORDER BY TotalRevenue DESC
LIMIT 10;


-- Most popular color
SELECT color, count(color) AS Count
FROM dbsales.saleitem si
JOIN dbsales.products pd ON si.productid = pd.productid
GROUP BY color
ORDER BY Count DESC;


-- States with the highest shipping price
SELECT country, state, max(shipping) AS HighestShipping
FROM dbsales.sale s
JOIN dbsales.customer c ON s.customerid = c.customerid
GROUP BY country, state
ORDER BY HighestShipping DESC;


-- Most common addresses
SELECT country, state, count(s.customerid) AS Count
FROM dbsales.sale s
JOIN dbsales.customer c ON s.customerid = c.customerid
GROUP BY country, state
ORDER BY Count DESC;


-- Most frequent customers
SELECT s.customerid, concat(firstname, ' ', lastname) as FullName, count(s.customerid) as purchases
FROM dbsales.sale s
JOIN dbsales.saleitem si ON s.saleid = si.saleid
JOIN dbsales.customer c ON s.customerid = c.customerid
GROUP BY s.customerid, firstname, lastname
ORDER BY purchases DESC
LIMIT 10;


SELECT s.saleid, si.ProductID, productname
FROM dbsales.sale s
JOIN dbsales.saleitem si ON s.saleid = si.saleid
JOIN dbsales.customer c ON s.customerid = c.customerid
JOIN dbsales.products p ON si.ProductID = p.ProductID
WHERE s.customerid = 5135;

-- Most common composition
SELECT composition, COUNT(composition) AS Count
FROM dbsales.saleitem si
JOIN dbsales.products pd ON si.productid = pd.productid
GROUP BY composition
ORDER BY Count DESC;
-- LIMIT 10;


-- Creating temporary tables for the total price of each sales and total price of each purchases 
CREATE TEMPORARY TABLE dbsales.sales 
	SELECT productid, sum(Quantity*SalePrice) AS totalsale
	FROM dbsales.sale s
	JOIN dbsales.saleitem si ON s.saleid = si.saleid
	GROUP BY productid;
    
CREATE TEMPORARY TABLE dbsales.purchases 
	SELECT productid, SUM(quantity*purchaseprice) AS totalpurchase
	FROM dbsales.purchase pc
	JOIN dbsales.purchaseitem pi ON pc.PurchaseID = pi.purchaseid
	GROUP BY productid;

-- Most profitable category
SELECT category, productname, profit
FROM (
	SELECT purchases.productid, totalsale - totalpurchase AS profit
	FROM dbsales.sales
	JOIN dbsales.purchases ON purchases.productid = sales.productid
) AS profits
JOIN dbsales.products p ON p.productid = profits.productid
ORDER BY profit DESC
LIMIT 10;


-- Most profitable category
SELECT category, ROUND(SUM(profit), 2) AS TotalProfit
FROM (
	SELECT pu.productid, totalsale - totalpurchase AS profit
	FROM dbsales.sales s
	JOIN dbsales.purchases pu ON pu.productid = s.productid
) AS profits
JOIN dbsales.products p ON p.productid = profits.productid
GROUP BY category
ORDER BY totalprofit DESC;


-- Most popular category
SELECT category, COUNT(category) AS count
FROM dbsales.sale s
JOIN dbsales.saleitem si ON s.saleid = si.saleid
JOIN dbsales.products p ON p.productid = si.productid
GROUP BY category
ORDER BY count DESC;


-- Most common shoe size
SELECT itemsize, COUNT(itemsize) AS count
FROM dbsales.saleitem
GROUP BY itemsize
ORDER BY count DESC;


-- Counts of sales by footwear gender category
SELECT gender, COUNT(gender) AS Count
FROM dbsales.saleitem si
JOIN (
	SELECT productid,
		CASE
			WHEN gender = 'M' THEN 'Male'
            WHEN gender = 'F' THEN 'Female'
            WHEN gender = 'U' THEN 'Unisex'
		END AS gender
	FROM dbsales.products
) AS p ON si.productid = p.productid
GROUP BY gender
ORDER BY Count DESC;


-- Shipping profit
SELECT (
	SELECT SUM(shipping)
	FROM dbsales.sale
) - (
	SELECT SUM(shipping)
	FROM dbsales.purchase
) AS shippingprofit;


-- Average purchases made by customers
SELECT AVG(total)
FROM (
	SELECT customerid, SUM(quantity) AS total
	FROM dbsales.sale s
	JOIN dbsales.saleitem si ON s.saleid = si.saleid
	GROUP BY customerid
) AS tmp;


-- Biggest discount for each products
SELECT p.productid, productname, MAX((listprice - saleprice)/listprice*100) AS discount
FROM dbsales.sale s
JOIN dbsales.saleitem si ON s.saleid = si.saleid
JOIN dbsales.products p ON p.productid = si.productid
GROUP BY p.productid, productname
ORDER BY discount DESC;


-- Percentage of each purchases made by customers from their total purchases
SELECT
	customerid,
	saleprice*quantity AS revenue,
	saleprice*quantity/(sum(saleprice*quantity) OVER(PARTITION BY customerid))*100 AS PercentageFromTotalRevenue,
    quantity,
	quantity/(sum(quantity) OVER(PARTITION BY customerid))*100 AS PercentageFromTotalQuantity
FROM
	dbsales.saleitem si
JOIN
	dbsales.sale s ON si.saleid = s.saleid;
    
    

-- Monthly income
WITH 
	purchases AS (
		SELECT 
			YEAR(purchasedate) AS year, 
			MONTHNAME(purchasedate) AS month, 
            SUM(purchaseprice*quantity + shipping) AS totalpurchases
		FROM 
			dbsales.purchase pc
		JOIN 
			dbsales.purchaseitem pi
		ON pc.purchaseid = pi.purchaseid
		GROUP BY year, month
        ORDER BY year, month
	),
	sales AS (
		SELECT
			YEAR(saledate) AS year,
            MONTHNAME(saledate) AS month,
            SUM(saleprice*quantity + shipping) AS totalsales
		FROM
			dbsales.sale ps
		JOIN
            dbsales.saleitem pi
		ON ps.saleid = pi.saleid
		GROUP BY year, month
        ORDER BY year, month
	)
SELECT
	CONCAT(SUBSTRING(sales.month, 1,3 ), ' ', sales.year) AS Months,
	CASE
		WHEN totalsales IS NULL THEN totalpurchases*(-1)
		WHEN totalpurchases IS NULL THEN totalsales
        ELSE totalsales - totalpurchases
	END AS MonthlyProfit
FROM purchases
RIGHT JOIN sales
ON
	purchases.year = sales.year
	AND purchases.month = sales.month
ORDER BY
	sales.year,
	MONTH(STR_TO_DATE(CONCAT('01 ', Months), '%d %M %Y'));



-- Employees payroll and number of days they have worked
SELECT E.employeeid, payroll, datediff(curdate(), hiredate) AS DaysWork
FROM (
	SELECT employeeid, salary AS payroll
    FROM dbsales.salaryemployee 
    UNION ALL
    SELECT * 
    FROM (
		SELECT employeeid, wage*maxhours*52 AS payroll
        FROM dbsales.wageemployee
	) AS wage
) AS salary
JOIN dbsales.employee E ON salary.employeeid = E.employeeid;
