--Data Type Conversion

SELECT TOP 5 *
FROM sales_orders; 


--Converting the data type of the order_date column

ALTER TABLE sales_orders
ALTER COLUMN order_date date;--Converting data type from nvarchar(50) to date

SELECT DISTINCT order_date
FROM sales_orders
WHERE TRY_CAST(order_date AS date) IS NULL
AND order_date IS NOT NULL;-- A message appeared indicating that some values could not be converted,
						   -- so we check for any invalid values.
						   -- It turned out that there is a date 2024-13-40. This month and day do not exist
						   -- and need to be analyzed to decide what to do with this value.
SELECT *
FROM sales_orders
WHERE order_date = '2024-13-40'; -- This invalid value has no correlation with other columns.


DELETE FROM sales_orders
WHERE order_date = '2024-13-40'; -- Removed 598 rows (0.23% of total) with invalid order_date value 2024-13-40. 
							     --Investigation of original data showed no systematic pattern 
								 -- rows represent random countries, products and order values. Data loss considered acceptable.


-- Converting the data type of the product_id column

ALTER TABLE sales_orders
ALTER COLUMN product_id int; -- Converting data type from smallint to int

-- Corventing the data type of the unit_price column

ALTER TABLE sales_orders
ALTER COLUMN unit_price decimal(10,2); --Converting data type from nvarchar to decimal

--Converting the data type of the discount_pct column 

ALTER TABLE sales_orders
ALTER COLUMN discount_pct decimal(10,2); --Converting data type from nvarchar(50) to decimal.
										 -- There are some values that cannot be converted to a number.


SELECT TOP 1000 discount_pct
FROM sales_orders
WHERE TRY_CAST(discount_pct AS decimal(10,2)) IS NULL; -- Checking what these values are. 
													   -- They contain the "%" sign 
													   -- these need to be converted to values without the "%" sign.


SELECT TOP 10000 discount_pct,
	REPLACE (discount_pct, '%', '') AS without_%
FROM sales_orders
WHERE TRY_CAST(discount_pct AS decimal(10,2)) IS NULL -- Checking if the conversion is working correctly.

UPDATE sales_orders
SET discount_pct = REPLACE (discount_pct, '%', '')
WHERE discount_pct LIKE '%[%]%';

-------------------------

SELECT TOP 5 *
FROM products_mmmgmeum;
 

--Converting the data type of the base_price  column from nvarchar(50) to decimal

ALTER TABLE products_mmmgmeum
ALTER COLUMN base_price decimal(10,2);

-- Converting the data type of the launch_date  column from nvarchar(50) to date

ALTER TABLE products_mmmgmeum
ALTER COLUMN launch_date date; -- An error appears indicating that not all values can be converted. I need to check what these values are.


SELECT DISTINCT launch_date
FROM products_mmmgmeum
WHERE TRY_CAST (launch_date AS date) IS NULL
AND launch_date IS NOT NULL; -- The column contains a non-existent date 2024-13-40. I need to check if it is correlated with any other columns.

SELECT *
FROM products_mmmgmeum
WHERE launch_date = '2024-13-40'; -- We have 4 results.

SELECT *
FROM sales_orders
WHERE product_id IN ('412','1611','2212','2398');

DELETE FROM products_mmmgmeum
WHERE launch_date = '2024-13-40';-- Removed 4 rows with invalid launch_date value '2024-13-40'.
								 -- Products (product_id: 412, 1611, 2212, 2398) had related orders in sales_orders,
								 
----------------------------------------------

SELECT TOP 5 *
FROM inventory_mmmgkubv;

SELECT MAX(stock_quantity)
FROM inventory_mmmgkubv; -- Checking the maximum value in the column to determine whether it makes sense to convert from smallint to int.
						 -- The maximum value is 567, so I will leave it as it is.


