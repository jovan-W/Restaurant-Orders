-- Count total
SELECT COUNT(*) total FROM order_details;

-- Count total missing values
SELECT COUNT(*) missing_values FROM order_details
WHERE item_id IS NULL;

-- DROP NULL
DELETE FROM order_details
WHERE item_id IS NULL;

-- Count total after drop null
SELECT COUNT(*) total FROM order_details;


-- What were the least and most ordered items? What categories were they in?
SELECT 
	mi.item_name, 
    category, 
    COUNT(*) total 
FROM 
	order_details od JOIN menu_items mi
		ON od.item_id = mi.menu_item_id
GROUP BY 1, 2
ORDER BY 3 DESC;

WITH most_order AS(
	SELECT 
		mi.item_name, 
		category, 
		COUNT(*) total 
    FROM 
		order_details od JOIN menu_items mi
			ON od.item_id = mi.menu_item_id
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1
),
least_order AS(
	SELECT 
		mi.item_name, 
		category, 
		COUNT(*) total 
    FROM 
		order_details od JOIN menu_items mi
			ON od.item_id = mi.menu_item_id
GROUP BY 1, 2
ORDER BY 3
LIMIt 1
)
SELECT *, 'most_order' orders FROM most_order
UNION
SELECT *, 'least_order' orders FROM least_order;
-- Hamburger is the most order with 622 orders and Chicken Tacos is the least order with 123 orders

-- What do the highest spend orders look like? Which items did they buy and how much did they spend?
SELECT order_id, SUM(price) total_spent FROM order_details od JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

WITH highest_spend AS(
SELECT order_id, SUM(price) total_spent FROM order_details od JOIN menu_items mi
ON od.item_id = mi.menu_item_id
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1)
SELECT hs.order_id, item_name, price,
sum(price) OVER() total_spent FROM order_details od JOIN menu_items mi
ON od.item_id = mi.menu_item_id
JOIN highest_spend hs ON od.order_id = hs.order_id;
-- Order ID number 440 is the most order with 13 orders and total spent 192.15

-- Were there certain times that had more or less orders?
SELECT HOUR(order_time) hour, COUNT(*) total FROM order_details
GROUP BY 1
ORDER BY hour;
WITH more_orders AS (
SELECT HOUR(order_time) hour, COUNT(*) total FROM order_details
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1
),
less_orders AS (
SELECT HOUR(order_time) hour, COUNT(*) total FROM order_details
GROUP BY 1
ORDER BY 2
LIMIT 1
)
SELECT *, 'more_orders' orders FROM more_orders
UNION
SELECT *, 'less_orders' orders FROM less_orders;
-- 12 am is the most orders and 10 pm is the less orders

-- Which cuisines should we focus on developing more menu items for based on the data?
SELECT category, COUNT(*) total_sold, SUM(price) total_sales
FROM order_details od JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY 1
ORDER BY 2 DESC;
-- We should focus on Asian and Italian Category

-- Category
SELECT DISTINCT(category) total_category FROM menu_items;
-- Total four category

-- Total Menu
SELECT COUNT(item_name) total_menu FROM menu_items;
-- Total 32 menu	

-- Total Menu per Category
SELECT category, COUNT(item_name) total_menu FROM menu_items
GROUP BY 1;
-- There are 6 menu in American Category,
-- 8 menu in Asian Category,
-- 9 menu in Mexican Category, and
-- 9 menu in Italian Category

-- Average Daily Sales
WITH total_sales_per_day AS (
SELECT order_date, SUM(PRICE) total_sales
FROM order_details od JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY 1
)
SELECT ROUND(AVG(total_sales), 2) average_sales_daily FROM total_sales_per_day;
-- Average Daily Sales is 1769.09

-- Average Customer
WITH avgcus AS (
SELECT 
	order_date, 
	COUNT(DISTINCT(order_id)) total_customer
FROM order_details
GROUP BY 1
)
SELECT ROUND(AVG(total_customer)) average_total_customer FROM avgcusg;
-- The Average Customer is 59 customer

-- Total Sales, Total Order, Total Customer
SELECT 
	COUNT(DISTINCT(order_id)) total_customer,
    COUNT(order_details_id) total_order,
    SUM(price) total_sales
FROM order_details od JOIN menu_items mi
	ON od.item_id = mi.menu_item_id;
-- Total Customer is 5343, Total Order 12097, and Total Sales 159217.90

-- Total Customer, Total Order, and Total Sales by Dayname, hour, and Timecategory
SELECT
	dayname(order_date) day_name, 
    hour(order_time) hour,
    CASE
		WHEN hour(order_time) BETWEEN 10 AND 11 THEN 'Morning'
        WHEN hour(order_time) BETWEEN 12 AND 18 THEN 'Afternoon'
        ELSE 'Night'
    END time_category,
    COUNT(DISTINCT(order_id))  total_customer,
    COUNT(order_details_id) total_order,
    SUM(price) total_sales
FROM order_details od JOIN menu_items mi
	ON od.item_id = mi.menu_item_id
GROUP BY 1, 2, 3;

-- Total Sales Cummulative from January to March
WITH rt AS (
SELECT 
order_date date,
SUM(price) total
FROM order_details od JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY 1)
SELECT *,
SUM(total) OVER(PARTITION BY MONTH(date) ORDER BY date) total_sales_cummulative,
SUM(total) OVER(PARTITION BY MONTH(date)) total_sales
FROM rt
ORDER BY 1, 2;

-- Comparison Daily Total Sales and Average Total Sales
WITH rts AS (
SELECT 
order_date,
SUM(price) total_sales
FROM order_details od JOIN menu_items mi ON od.item_id = mi.menu_item_id
GROUP BY 1
)
SELECT *,
ROUND(AVG(total_sales) OVER(), 2) average_total_sales
FROM rts
ORDER BY 1, 2;

-- DoD Growth
WITH cte1 AS (
SELECT order_date, SUM(price) total_sales
FROM order_details od JOIN menu_items mi
	ON od.item_id = mi.menu_item_id
GROUP BY 1
),
cte2 AS(
SELECT *,
	COALESCE(LAG(total_sales) OVER(ORDER BY order_date), total_sales) previous_sales
FROM cte1
)
SELECT
	*,
    CONCAT(ROUND((total_sales - previous_sales) / previous_sales * 100, 2), '%') growth_percentage
FROM cte2;

-- MoM Growth
WITH cteone AS (
SELECT DATE_FORMAT(order_date, '%Y-%m') month, SUM(price) total_sales
FROM order_details od JOIN menu_items mi

	ON od.item_id = mi.menu_item_id
GROUP BY 1
),
ctetwo AS(
SELECT *,
	COALESCE(LAG(total_sales) OVER(ORDER BY month), total_sales) previous_sales
FROM cteone
)
SELECT
	*,
    CONCAT(ROUND((total_sales - previous_sales) 
    / 
    previous_sales * 100, 2), '%') growth_percentage
FROM ctetwo
ORDER BY month;