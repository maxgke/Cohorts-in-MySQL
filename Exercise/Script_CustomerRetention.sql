-- || IMPORTING SECTION || --

-- TABLES WERE IMPORTED FROM IMPORT TABLE WIZARD, VIA CSV
-- THE schemas used was project_sql_cohort
-- ORIGINAL DATASET TAKEN FROM: 
-- https://www.w3schools.com/SQl/trymysql.asp?filename=trysql_func_mysql_concat
USE project_sql_cohort;

-- FINAL TOUCHES ON IMPORTING, CHANGING DATES WHICH ARE STRINGS, TO DATE FORMAT
--   SET SQL_SAFE_UPDATES = 0;
--   UPDATE Employees SET BirthDate = STR_TO_DATE(BirthDate, '%d/%m/%Y');
--   ALTER TABLE Employees CHANGE COLUMN BirthDate BirthDate DATE;
--   UPDATE Orders SET OrderDate = STR_TO_DATE(OrderDate, '%d/%m/%Y');
--   ALTER TABLE Orders CHANGE COLUMN OrderDate OrderDate DATE;
--   SET SQL_SAFE_UPDATES = 1;

-- || CODING SECTION || --
-- Done Step-by-Step, with Temporary Tables --

-- STEP1 : 
-- i) Getting The First Order Date for Each Customer.
DROP TABLE IF EXISTS `First_Order_Per_Customer`;
CREATE TEMPORARY TABLE `First_Order_Per_Customer`
SELECT Orders.CustomerID, MIN(Orders.OrderDate) AS `First_Order_Date`
FROM Orders
GROUP BY 1;
SELECT * FROM First_Order_Per_Customer;

-- STEP2 : 
-- i) Adding the first order date as a column to the orders table.
-- ii) Making a column with just year-month info for aggregations later on.

DROP TABLE IF EXISTS `Orders_W_First_Order_Date`;
CREATE TEMPORARY TABLE `Orders_W_First_Order_Date`
SELECT Orders.*, 
	   First_Order_Per_Customer.First_Order_Date,
       CONCAT(CAST(YEAR(First_Order_Per_Customer.First_Order_Date) AS CHAR), LPAD(MONTH(First_Order_Per_Customer.First_Order_Date),2,'0')) AS `PERIOD_FIRST_ORDER`
FROM Orders
LEFT JOIN First_Order_Per_Customer on Orders.CustomerID = First_Order_Per_Customer.CustomerID;
SELECT * FROM project_sql_cohort.orders_w_first_order_date;

-- STEP3 [Making the final table], Includes:
-- i) Making a column which is the difference in months from the first order date to the current date.
-- ii) Counting Unique Customer IDs

DROP TABLE IF EXISTS `Orders_per_Customers_Extensive_Format`;
CREATE TEMPORARY TABLE `Orders_per_Customers_Extensive_Format`
SELECT orders_w_first_order_date.CustomerID,
	   orders_w_first_order_date.OrderDate,
       orders_w_first_order_date.First_Order_Date,
       orders_w_first_order_date.PERIOD_FIRST_ORDER,
       ROUND(DATEDIFF(orders_w_first_order_date.OrderDate, orders_w_first_order_date.First_Order_Date)/30) AS `MONTHS_FROM_FIRST`,
       COUNT(DISTINCT CustomerID) AS `CUSTOMER_COUNT`
FROM orders_w_first_order_date
GROUP BY orders_w_first_order_date.PERIOD_FIRST_ORDER, MONTHS_FROM_FIRST
ORDER BY PERIOD_FIRST_ORDER, MONTHS_FROM_FIRST;
SELECT * FROM project_sql_cohort.Orders_per_Customers_Extensive_Format;

-- STEP4a [Making the table with percentages instead]:
-- i) FIRST TEMPORARY TABLE: Making a column which is just the number of customers that were first time customers in a given month
DROP TABLE IF EXISTS `GET_NUM_CUSTOMERS_FIRST_MONTH`;
CREATE TEMPORARY TABLE `GET_NUM_CUSTOMERS_FIRST_MONTH`
SELECT PERIOD_FIRST_ORDER,
	   CUSTOMER_COUNT AS `CUSTOMERS_COUNT_IN_FIRST_MONTH`
FROM Orders_per_Customers_Extensive_Format
WHERE MONTHS_FROM_FIRST = 0
GROUP BY PERIOD_FIRST_ORDER, MONTHS_FROM_FIRST;
SELECT * FROM `GET_NUM_CUSTOMERS_FIRST_MONTH`;

-- STEP4b [Making the table with percentages instead]:
-- i) Making FINAL TABLE: Getting the table of step 3 with the percentage retained using the auxiliary table of STEP4a
DROP TABLE IF EXISTS `SOLUTION`;
CREATE TABLE `SOLUTION`
SELECT Orders_per_Customers_Extensive_Format.*, Orders_per_Customers_Extensive_Format.CUSTOMER_COUNT / GET_NUM_CUSTOMERS_FIRST_MONTH.CUSTOMERS_COUNT_IN_FIRST_MONTH AS `PERCENTAGE_RETAINED`
FROM Orders_per_Customers_Extensive_Format
LEFT JOIN GET_NUM_CUSTOMERS_FIRST_MONTH on GET_NUM_CUSTOMERS_FIRST_MONTH.PERIOD_FIRST_ORDER = Orders_per_Customers_Extensive_Format.PERIOD_FIRST_ORDER;
SELECT * FROM Solution;