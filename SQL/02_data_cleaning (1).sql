-- DATA CLEANING FOR sales_orders TABLE

	-- CHECKING FOR CORRELATIONS BETWEEN NULL VALUES IN order_date AND OTHER COLUMNS
	SELECT *
	FROM sales_orders
	WHERE order_date IS NULL;

	SELECT *
	FROM sales_orders
	WHERE order_date  IS NULL
	AND  discount_pct IS NULL; -- I noticed that nulls partially appear together in two columns, checking how often this occurs
							   -- It turned out that only 79 records have nulls in both columns simultaneously

	DELETE FROM sales_orders
	WHERE order_date IS NULL; -- Removing rows with NULL values in order_date column (629 rows)

	SELECT COUNT (*)
	FROM sales_orders; -- 260,780 - 629 = 260,151 rows remaining - count confirmed

	-- CHECKING FOR CORRELATIONS BETWEEN NULL VALUES IN discount_pct AND OTHER COLUMNS

	SELECT *
	FROM sales_orders
	WHERE discount_pct is NULL;

	SELECT *
	FROM sales_orders
	WHERE TRY_CAST(discount_pct AS decimal(10,2)) = 0 -- checking how records with discount_pct equal to 0 look like
	
	SELECT COUNT(*)
	FROM sales_orders
	WHERE TRY_CAST(discount_pct AS decimal(10,2)) = 0 -- checking how many records have discount_pct equal to 0

	UPDATE sales_orders
	SET discount_pct = 0
	WHERE discount_pct IS NULL;-- replacing null values with 0

	-- DUPLICATES IN order_id

	SELECT *
	FROM sales_orders
	WHERE order_id IN (
		SELECT order_id
		FROM sales_orders
		GROUP BY order_id
		HAVING COUNT(*) > 1
		)
	ORDER BY order_id;

	SELECT *, ROW_NUMBER () OVER (PARTITION BY order_id ORDER BY order_id ) AS ROW_NUM
	FROM sales_orders  -- checking how data looks when grouped by order_id

	WITH  ROW_NUM_CTE AS (
						SELECT *, ROW_NUMBER () OVER (PARTITION BY order_id ORDER BY order_id ) AS ROW_NUM
						FROM sales_orders)
	DELETE FROM ROW_NUM_CTE
	WHERE ROW_NUM>1; -- creating a temporary table and removing records where row_number is greater than 1.
	
	    -- 769 rows were removed, verifying with previous query whether any duplicates remain
		-- expected 780 removals, but the difference is likely due to records
		-- already removed in earlier operations - no duplicates remaining
	SELECT DISTINCT order_id
	FROM sales_orders

	-- STANDARDIZING VALUES IN status COLUMN

	UPDATE sales_orders
	SET status = 'SHIPPED'
	WHERE status IN ('Ship','Shipped');-- 'Ship' and 'Shipped' standardized to 'SHIPPED'

	UPDATE sales_orders
	SET status = 'COMPLETED'
	WHERE status IN ('complete','Completed'); -- 'complete' standardized to 'COMPLETED'

	UPDATE sales_orders
	SET status = 'DONE'
	WHERE status = 'done';-- 'done' standardized to 'DONE'



	-- STANDARDIZING country COLUMN TO ISO CODES

	UPDATE sales_orders
	SET country = 'DE'
	WHERE country IN ('Germany','Deutschland','GER');

	UPDATE sales_orders
	SET country = 'CZ'
	WHERE country IN ('Czech', 'Cz', 'Czechia', 'Czech Republic');

	UPDATE sales_orders
	SET country = 'SE'
	WHERE country = 'Sweden';

	UPDATE sales_orders
	SET country = 'SK'
	WHERE country IN ('slovak', 'SLOVAKIA');

	UPDATE sales_orders
	SET country = 'NL'
	WHERE country IN ('Holland','netherlands');

	UPDATE sales_orders
	SET country = 'PL'
	WHERE country IN ('POL','poland','pl','Polska');

	UPDATE sales_orders
	SET country = 'FR'
	WHERE country = 'France';

	UPDATE sales_orders
	SET country = 'ES'
	WHERE country = 'Spain';

	UPDATE sales_orders
	SET country = 'IT'
	WHERE country = 'italy';

	UPDATE sales_orders
	SET country = 'AT'
	WHERE country = 'austria';

	-- DATE CLEANING AND STANDARDIZATION

	SELECT *
	FROM sales_orders
	WHERE order_date LIKE '____-__'
	      OR order_date = 'not_a_date' -- checking for any correlations between incomplete dates and other columns

	SELECT  count(*) AS number
	FROM sales_orders
	WHERE order_date LIKE '____-__'; -- 697 dates in YYYY-MM format represent 0.3%

	SELECT  count(*) AS number
	FROM sales_orders
	WHERE order_date LIKE 'not_a_date'; -- 661 dates with value 'not_a_date' represent 0.3%

		 -- since invalid dates are below 1% we remove them 

	DELETE FROM sales_orders
	WHERE order_date LIKE '____-__'
	OR order_date = 'not_a_date'

	 -- STANDARDIZING DATE FORMATS
	 SELECT order_date,
	 CASE
	 WHEN order_date LIKE '__/__/____'
		THEN SUBSTRING (order_date, 7,4) + '-'
			 + SUBSTRING (order_date, 4,2) + '-'
			 + SUBSTRING (order_date, 1,2)
	WHEN order_date LIKE '__-__-____'
		THEN SUBSTRING (order_date, 7,4) + '-'
			 + SUBSTRING (order_date, 4,2) + '-'
			 + SUBSTRING (order_date, 1,2)
	WHEN order_date LIKE '____/__/__'
		THEN SUBSTRING (order_date, 1,4) + '-'
			 + SUBSTRING (order_date, 6,2) + '-'
			 + SUBSTRING (order_date, 9,2)
	ELSE order_date
	END
	FROM sales_orders; -- checking how data will look after changes

	UPDATE sales_orders
	SET order_date = CASE
	WHEN order_date LIKE '__/__/____'
		THEN SUBSTRING (order_date, 7,4) + '-'
			 + SUBSTRING (order_date, 4,2) + '-'
			 + SUBSTRING (order_date, 1,2)
	WHEN order_date LIKE '__-__-____'
		THEN SUBSTRING (order_date, 7,4) + '-'
			 + SUBSTRING (order_date, 4,2) + '-'
			 + SUBSTRING (order_date, 1,2)
	WHEN order_date LIKE '____/__/__'
		THEN SUBSTRING (order_date, 1,4) + '-'
			 + SUBSTRING (order_date, 6,2) + '-'
			 + SUBSTRING (order_date, 9,2)
	WHEN order_date LIKE '____.__.__'
		THEN SUBSTRING(order_date, 1, 4) + '-'
			+ SUBSTRING(order_date, 6, 2) + '-'
		    + SUBSTRING(order_date, 9, 2)
	ELSE order_date
	END; -- applying changes

	SELECT DISTINCT order_date
	FROM sales_orders
	WHERE order_date LIKE '__/__/____'
		OR order_date LIKE '__-__-____' 
		OR order_date LIKE '____/__/__'
		OR order_date LIKE '____.__.__'
		OR order_date LIKE '__.__.____'; -- verifying whether any old formats remain or any unexpected formats exist
										 -- found additional format YYYY.MM.DD — added to the query above

-- CLEANING quantity COLUMN

	SELECT *
	FROM sales_orders
	WHERE quantity = 0; --analyzing records where quantity = 0 to check if this makes business sense

	SELECT status, COUNT(*) AS number
	FROM sales_orders
	WHERE quantity = 0
	GROUP BY ROLLUP (status) -- checking count of quantity = 0 records by status
							 -- total: 1,028 records out of 258,793 which is 0.4%

	DELETE FROM sales_orders
	WHERE quantity = 0; -- removing 1,028 rows

	SELECT MIN(quantity) AS min, MAX(quantity) AS max
	FROM sales_orders --  verifying there are no fractional values such as 0.2 or 0.6

-- CLEANING unit_price COLUMN

	SELECT *
	FROM sales_orders
	WHERE TRY_CAST(unit_price AS decimal(10,2)) = 0 -- analyzing records where unit_price = 0 to check if this makes business sense
													-- having 4 or 5 items with price 0.0 across different orders, products and statuses
													-- is unlikely to represent free items, especially since some also have a discount applied

	SELECT status, COUNT(*)
	FROM sales_orders
	WHERE TRY_CAST(unit_price AS decimal(10,2)) = 0
	GROUP BY ROLLUP (status); -- checking count of unit_price = 0 records by status — 1.594 records found

	SELECT COUNT (*)
	FROM sales_orders -- 257.765 total records currently

	-- unit_price = 0 represents 0.6% — removing these records
	DELETE FROM sales_orders
	WHERE TRY_CAST(unit_price AS decimal(10,2)) = 0

	SELECT COUNT(*)
	FROM sales_orders;--VERIFYING NUMBER OF ROWS (2400)

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--DATA CLEANING FOR products_mmmgmeum TABLE

	-- HANDLING NULL VALUES IN launch_date COLUMN

	SELECT *
	FROM products_mmmgmeum
	WHERE launch_date is NULL; -- Checking whether there is any correlation between NULL values in launch_date and other columns
							   -- NULL values in launch_date show no correlation with other columns
							   -- since there are only 91 records representing 3.64% I decided to remove them
	DELETE FROM products_mmmgmeum
	WHERE launch_date is NULL;

	
	-- CHECKING INCOMPLETE RECORDS

	SELECT launch_date, COUNT (*) AS how_many_wrog_date
	FROM products_mmmgmeum
	WHERE launch_date  LIKE '____-__' 
	      OR launch_date  LIKE '____/__' 
		  OR launch_date  LIKE 'not_a_date'
	GROUP BY launch_date
	ORDER BY how_many_wrog_date; -- checking count of records with invalid date format
								 -- 9 records found, representing a very small percentage — removing them

	DELETE FROM products_mmmgmeum
	WHERE launch_date  LIKE '____-__' 
	      OR launch_date  LIKE '____/__' 
		  OR launch_date  LIKE 'not_a_date';

	-- DATE FORMAT STANDARDIZATION
	
		SELECT launch_date,
		CASE
		WHEN launch_date LIKE '__-__-____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '__/__/____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '__.__.____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '____/__/__'
		THEN SUBSTRING(launch_date, 1, 4) + '-'
		+SUBSTRING(launch_date, 6, 2) + '-'
		+SUBSTRING(launch_date, 9, 2)
		WHEN launch_date LIKE '____.__.__'
		THEN SUBSTRING(launch_date, 1, 4) + '-'
		+SUBSTRING(launch_date, 6, 2) + '-'
		+SUBSTRING(launch_date, 9, 2)
		ELSE launch_date
		END AS new_launch_date
		FROM products_mmmgmeum; -- previewing format changes before applying

		UPDATE products_mmmgmeum
		SET launch_date = CASE
		WHEN launch_date LIKE '__-__-____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '__/__/____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '__.__.____'
		THEN SUBSTRING(launch_date, 7, 4) + '-'
		+SUBSTRING(launch_date, 4, 2) + '-'
		+SUBSTRING(launch_date, 1, 2)
		WHEN launch_date LIKE '____/__/__'
		THEN SUBSTRING(launch_date, 1, 4) + '-'
		+SUBSTRING(launch_date, 6, 2) + '-'
		+SUBSTRING(launch_date, 9, 2)
		WHEN launch_date LIKE '____.__.__'
		THEN SUBSTRING(launch_date, 1, 4) + '-'
		+SUBSTRING(launch_date, 6, 2) + '-'
		+SUBSTRING(launch_date, 9, 2)
		ELSE launch_date
		END; -- applying date format standardization

		
		SELECT DISTINCT launch_date
			FROM products_mmmgmeum
		WHERE launch_date NOT LIKE '____-__-__';	-- verifying that all date formats have been successfully updated	 
		
		SELECT COUNT(*)
		FROM products_mmmgmeum; --VERIFYING NUMBER OF ROWS (2400)


-- ============================================================================================================================================================
-- DATA CLEANING FOR inventory_mmmgkubv TABLE

	-- STANDARDIZING COUNTRY NAMES IN warehouse_country COLUMN

	UPDATE inventory_mmmgkubv
	SET warehouse_country = 'DE'
	WHERE warehouse_country IN ('Germany', 'germany','GER', 'Deutschland');

	UPDATE inventory_mmmgkubv
	SET warehouse_country = 'PL'
	WHERE warehouse_country IN ('Polska', 'pl', 'poland', 'Poland', 'POL');
	
	UPDATE inventory_mmmgkubv
	SET warehouse_country = 'CZ'
	WHERE warehouse_country IN ('Czech', 'Czech Republic', 'Czechia');

	SELECT DISTINCT warehouse_country
		FROM inventory_mmmgkubv;
		-- ALL COUNTRIES STANDARDIZED, CURRENTLY WE HAVE: DE, PL, CZ


	-- HANDLING NULL VALUES IN last_stock_update COLUMN

	SELECT *
	FROM inventory_mmmgkubv
	WHERE last_stock_update IS NULL;
		-- NULL values in last_stock_update are random, showing no correlation with any other column
		-- since they are random and represent only 0.7% I am removing them from the table
		-- this should not negatively affect further analysis

	DELETE FROM inventory_mmmgkubv
	WHERE last_stock_update IS NULL; -- Removing rows with NULL values in last_stock_update column

	SELECT COUNT (*) 
	FROM inventory_mmmgkubv;
		-- VERIFYING CORRECT NUMBER OF ROWS REMOVED (3741 - 26 = 3715)

	-- ============================================================================================================================================================
	
