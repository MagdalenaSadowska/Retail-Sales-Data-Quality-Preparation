-- ============================================================================================================

-- ROW COUNT CHECK

SELECT COUNT (*) AS total_rows 
FROM sales_orders               -- 260780

SELECT COUNT (*) AS total_rows 
FROM inventory_mmmgkubv         -- 3741

SELECT COUNT (*) AS total_rows 
FROM products_mmmgmeum          --2500

-- ============================================================================================================

-- COLUMN NAMES AND INITIAL DATA REVIEW FOR sales_orders
SELECT TOP 5 *
FROM sales_orders 


-- NULL VALUES CHECK FOR sales_orders

SELECT COUNT (*) AS total_rows, -
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
	SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date,
	SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
	SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
	SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
	SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END)AS null_quantity,
	SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) AS null_quantity,
	SUM(CASE WHEN discount_pct IS NULL THEN 1 ELSE 0 END) AS null_discount_pct,
	SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END) AS null_status
FROM sales_orders;
	-- 629 null values in order_date column, which is 0.2%
	-- 31.322 null values in discount_pct column, which is 12%
	--Missing values in this case most likely indicate no discount applied,
	-- so initially I can assume this will not affect the analysis results


--DUPLICATE CHECK FOR order_id

SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT order_id) AS unique_orders
FROM sales_orders;
	--780 duplicates found


--CHECKING WHAT IS DUPLICATED IN ORDER_ID

SELECT order_id, COUNT(*) AS quantity_duplicates
FROM sales_orders
GROUP BY order_id
HAVING COUNT(*)>1;
	--DUPLICATES: 390 records are duplicated
	-- Duplicates will be removed


--DUPLICATE CHECK FOR status
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT status) AS unique_status
FROM sales_orders;
	-- 6 unique values found


-- CHECKING VALUES AND LOOKING FOR TYPOS

SELECT status, COUNT(*) AS name_duplicates
FROM sales_orders
GROUP BY status

	-- STATUS: 6 unique values, inconsistent letter casing
	-- 'complete' vs 'COMPLETED' - likely the same status
	-- 'SHIP' vs 'Shipped' - likely the same status as well
	-- To standardize: unify letter casing and naming conventions


-- DUPLICATE CHECK FOR country
SELECT COUNT(*) AS total_rows,
	COUNT(DISTINCT country) AS unique_status
FROM sales_orders;
	-- 28 unique values found


-- CHECKING VALUES AND LOOKING FOR TYPOS

SELECT country, COUNT(*) AS name_duplicates
FROM sales_orders
GROUP BY country

	-- country: 26 unique values, inconsistent letter casing, country abbreviations mixed with full names
	-- duplicate country names e.g. 'DE' vs 'Germany' vs 'Deutschland'
	-- To standardize: unify country naming conventions


-- NUMERIC RANGE CHECK FOR quantity AND unit_price

SELECT
	MAX (quantity) AS max_value,
	MIN (quantity) AS min_value,
	MAX (unit_price) AS max_unite_price,
	MIN (unit_price) AS min_unite_price
FROM sales_orders
WHERE quantity IS NOT NULL AND unit_price IS NOT NULL;

-- NUMERIC RANGES:
    -- quantity: MIN=0, MAX=608
    -- unit_price: MIN=0.0, MAX=99.99
    -- quantity=0 and unit_price=0 require business verification
    -- possible reasons: cancelled orders, free items, returns/complaints
    -- To check: whether quantity=0 and unit_price=0 correlate with CANCELLED status

SELECT quantity,status
FROM sales_orders
WHERE quantity=0;

	-- quantity=0 appears across ALL statuses, not only CANCELLED
	-- This is a data error - an order cannot be COMPLETED with quantity 0

SELECT unit_price, status
FROM sales_orders
WHERE CAST(unit_price AS decimal(10,2)) = 0

	 -- unit_price=0 also appears across all statuses
	 -- This is a data error - COMPLETED/SHIPPED orders should not have price 0
     -- Exception: CANCELLED orders may have price 0

-- DATE CHECK

SELECT DISTINCT 
    LEFT(order_date, 5) AS first_4_signs,
    LEN(order_date) AS lenght,
    COUNT(*) AS liczba
FROM sales_orders
WHERE order_date IS NOT NULL
GROUP BY LEFT(order_date, 5), LEN(order_date)
ORDER BY liczba DESC
	-- order_date: 3 date formats found
	-- Dominant format: YYYY-MM-DD (majority of rows)
	-- Minority formats: DD-MM-YYYY, MM-DD-YYYY
	-- To fix: standardize to YYYY-MM-DD and change column type to DATE

SELECT DISTINCT order_date
FROM sales_orders
WHERE TRY_CAST(order_date AS date) IS NULL
AND order_date IS NOT NULL
AND order_date NOT LIKE '__/__/____'
AND order_date NOT LIKE '____-__-__'
AND order_date NOT LIKE '__-__-____'
	-- Invalid values found in order_date:
		-- dates in YYYY-MM format (missing day)
		-- text value: 'not_a_date'
		-- remaining ~40,000 rows contain dates in various formats DD/MM/YYYY and DD-MM-YYYY
		-- To fix during data cleaning


-- ============================================================================================================================================================

-- COLUMN NAMES AND INITIAL DATA REVIEW FOR products_mmmgmeum 
SELECT TOP 5 *
FROM products_mmmgmeum 


--NULL VALUES CHECK FOR products_mmmgmeum

SELECT COUNT (*) AS total_rows, 
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
SUM(CASE WHEN sub_category IS NULL THEN 1 ELSE 0 END) AS null_sub_category,
SUM(CASE WHEN base_price IS NULL THEN 1 ELSE 0 END) AS base_price,
SUM(CASE WHEN launch_date IS NULL THEN 1 ELSE 0 END) AS launch_date
FROM products_mmmgmeum; 
-- null values found in launch_date column: 91 rows, which is 3.64%
-- this is a small amount and should not negatively affect further analysis. 
-- to be decided during data cleaning what to do with these records

-- DUPLICATE CHECK FOR product_id

SELECT 
	COUNT(*) as all_rows,
	COUNT(DISTINCT product_id) AS unique_product_id
FROM products_mmmgmeum; 
	-- no duplicates found

-- UNIQUE VALUES CHECK

	-- CATEGORY COLUMN
	SELECT category, COUNT(*) AS all_rows
	FROM products_mmmgmeum
	GROUP BY ROLLUP(category)
	ORDER BY all_rows
		-- no typos found, 5 categories present

	-- SUB_CATEGORY COLUMN
	SELECT sub_category, COUNT(*) AS all_rows
	FROM products_mmmgmeum
	GROUP BY ROLLUP (sub_category)
	ORDER BY all_rows;
		 -- no typos or errors found, 22 subcategories present

--BASE_PRICE COLUMN CHECK

SELECT base_price
FROM products_mmmgmeum
WHERE CAST(base_price AS decimal(10,2)) < 0.01;

SELECT 
	MIN(CAST(base_price AS decimal(10,2))) AS min_price,
	MAX(CAST(base_price AS decimal(10,2))) AS max_price
FROM products_mmmgmeum;
	-- NO NEGATIVE OR ZERO PRICES FOUND


-- CHECKING FOR INVALID DATE VALUES

SELECT DISTINCT launch_date
FROM products_mmmgmeum
WHERE TRY_CAST(launch_date AS date) IS NULL
AND launch_date IS NOT NULL
AND launch_date NOT LIKE '__/__/____'
AND launch_date NOT LIKE '____-__-__'
AND launch_date NOT LIKE '__-__-____';
		-- Invalid values found in launch_date:
		-- YYYY-MM format (missing day), text value found
		-- To fix during data cleaning

-- ============================================================================================================================================================

-- COLUMN NAMES AND INITIAL DATA REVIEW FOR inventory_mmmgkubv
SELECT TOP 5 *
FROM inventory_mmmgkubv

-- NULL VALUES CHECK FOR inventory_mmmgkubv

SELECT COUNT (*) AS total_rows, 
SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
SUM(CASE WHEN warehouse_country IS NULL THEN 1 ELSE 0 END) AS null_warehouse_country,
SUM(CASE WHEN stock_quantity IS NULL THEN 1 ELSE 0 END) AS null_stock_quantity,
SUM(CASE WHEN last_stock_update IS NULL THEN 1 ELSE 0 END) AS last_stock_update
FROM inventory_mmmgkubv; 
	--26 null values found in last_stock_update column, which is 0.7%
	-- this should not negatively affect further analysis
	-- to be decided during data cleaning what to do with these records

-- CHECKING product_id FOR NEGATIVE VALUES AND NON-NUMERIC VALUES

SELECT product_id
FROM inventory_mmmgkubv
WHERE product_id<0;
	-- NO NEGATIVE VALUES FOUND

SELECT product_id
FROM inventory_mmmgkubv
WHERE TRY_CAST(product_id AS NUMERIC) IS NULL;
	-- NO NON-NUMERIC VALUES FOUND

-- UNIQUE VALUES CHECK FOR warehouse_country

SELECT DISTINCT warehouse_country
FROM inventory_mmmgkubv;
	-- country names need to be standardized e.g. 'Polska' vs 'POL' vs 'PL'

-- CHECKING stock_quantity FOR NEGATIVE VALUES

SELECT stock_quantity
FROM inventory_mmmgkubv
WHERE stock_quantity<0;
	-- no negative values found

-- DATE VALIDITY CHECK

SELECT DISTINCT last_stock_update
FROM inventory_mmmgkubv
WHERE TRY_CAST( last_stock_update AS date) IS NULL
AND last_stock_update IS NOT NULL
AND last_stock_update LIKE '____-__-__'
AND last_stock_update LIKE '__-__-____'
AND last_stock_update LIKE '____/__/__'
AND last_stock_update LIKE '__/__/____'

SELECT DISTINCT last_stock_update
FROM inventory_mmmgkubv

-- All dates are in YYYY-MM-DD format
