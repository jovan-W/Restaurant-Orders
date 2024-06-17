-- Query use on Power BI

SELECT
	order_id,
    order_details_id,
	order_date, dayname(order_date) dayname,hour(order_time) hour,
    CASE
		WHEN hour(order_time) BETWEEN 10 AND 11 THEN 'Morning'
        WHEN hour(order_time) BETWEEN 12 AND 18 THEN 'Afternoon'
        ELSE 'Night'
    END time_category,
    item_name,
    category,
    COUNT(DISTINCT(order_id)) total_customer,
    COUNT(order_details_id) total_order,
    SUM(price) total_sales
FROM order_details od JOIN menu_items mi
	ON od.item_id = mi.menu_item_id
GROUP BY 1, 2, 3, 4, 5, 6;

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
    CONCAT(ROUND((total_sales - previous_sales) / previous_sales * 100, 2), '%') growth_percentage
FROM ctetwo
ORDER BY month;
