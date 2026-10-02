# Find the date range of our data
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM orders;
#So our analysis covers approximately 3 years.


# Revenue by year
#How much revenue did we generate each year?
SELECT
    YEAR(order_date) AS sales_year,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM vw_sales_detail
GROUP BY YEAR(order_date)
ORDER BY sales_year;


# Profit by year
SELECT
    YEAR(order_date) AS sales_year,
    ROUND(SUM(profit), 2) AS total_profit
FROM vw_sales_detail
GROUP BY YEAR(order_date)
ORDER BY sales_year;


# Calculate yearly growth
WITH yearly_sales AS (
    SELECT
        YEAR(order_date) AS sales_year,
        SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY YEAR(order_date)
)
SELECT sales_year,
ROUND(revenue, 2) AS revenue,
ROUND(LAG(revenue) OVER (ORDER BY sales_year),2) AS previous_year_revenue,
ROUND( (revenue - LAG(revenue) OVER (ORDER BY sales_year))/LAG(revenue) OVER (ORDER BY sales_year)* 100,2) AS yoy_growth_percentage
FROM yearly_sales
ORDER BY sales_year;


# Monthly revenue
SELECT
    YEAR(order_date) AS sales_year,
    MONTH(order_date) AS sales_month,
	DATE_FORMAT(order_date, '%Y-%m') AS month,
	ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
GROUP BY
    YEAR(order_date),
    MONTH(order_date),
    DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


# Monthly revenue + profit
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / SUM(revenue) * 100,2) AS profit_margin_percentage
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


# Monthly order count
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(DISTINCT order_id) AS total_orders
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


# Monthly Average Order Value
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(revenue)/COUNT(DISTINCT order_id),2) AS average_order_value
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


# Month-over-Month Growth
WITH monthly_sales AS (
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS month,
	SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT month,
    ROUND(revenue, 2) AS revenue,
	ROUND(LAG(revenue) OVER (ORDER BY month),2) AS previous_month_revenue,
    ROUND((revenue-LAG(revenue) OVER (ORDER BY month))/LAG(revenue) OVER (ORDER BY month)* 100, 2) AS mom_growth_percentage
FROM monthly_sales
ORDER BY month;


# Find the best sales month
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY revenue DESC
LIMIT 1;


# Find the worst sales month
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY revenue ASC
LIMIT 1;


# Running/Cumulative Revenue
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
)
SELECT month,
	ROUND(revenue, 2) AS monthly_revenue,
    ROUND(SUM(revenue) OVER (
            ORDER BY month
            ROWS BETWEEN UNBOUNDED PRECEDING
            AND CURRENT ROW ),2) AS cumulative_revenue
FROM monthly_sales
ORDER BY month;
#This calculates the running total.


# Find the best-performing year
SELECT
    YEAR(order_date) AS sales_year,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit
FROM vw_sales_detail
GROUP BY YEAR(order_date)
ORDER BY revenue DESC
LIMIT 1;


# Monthly category performance
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    category,
    ROUND(SUM(revenue), 2) AS revenue
FROM vw_sales_detail
GROUP BY
    DATE_FORMAT(order_date, '%Y-%m'),
    category
ORDER BY month,revenue DESC;


# Find the best category for each month
WITH monthly_category_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        category,
        SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date, '%Y-%m'), category
),
ranked AS (
    SELECT month,category,revenue,
        RANK() OVER (
            PARTITION BY month
            ORDER BY revenue DESC
        ) AS category_rank
    FROM monthly_category_sales
)
SELECT month,category,ROUND(revenue, 2) AS revenue
FROM ranked
WHERE category_rank = 1
ORDER BY month;


# Find the highest-growth month
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
growth AS (
    SELECT month, revenue,LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_sales
)
SELECT month,
    ROUND(revenue, 2) AS revenue,
    ROUND((revenue - previous_revenue)/ previous_revenue * 100,2) AS growth_percentage
FROM growth
WHERE previous_revenue IS NOT NULL
ORDER BY growth_percentage DESC
LIMIT 10;


# Find the biggest decline
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(order_date, '%Y-%m') AS month,
        SUM(revenue) AS revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date, '%Y-%m')
),
growth AS (
    SELECT month,revenue,LAG(revenue) OVER (ORDER BY month) AS previous_revenue
    FROM monthly_sales
)
SELECT month,
    ROUND(revenue, 2) AS revenue,
    ROUND((revenue - previous_revenue)/ previous_revenue * 100,2) AS growth_percentage
FROM growth
WHERE previous_revenue IS NOT NULL
ORDER BY growth_percentage ASC
LIMIT 10;
