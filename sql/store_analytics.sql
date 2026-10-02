# Store revenue
SELECT store_id, store_name,
       ROUND(SUM(revenue),2) revenue
FROM vw_sales_detail
GROUP BY store_id, store_name
ORDER BY revenue DESC;


# Store profit
SELECT store_id, store_name,
       ROUND(SUM(profit),2) profit
FROM vw_sales_detail
GROUP BY store_id, store_name
ORDER BY profit DESC;


# Region performance
SELECT store_region region,
       ROUND(SUM(revenue),2) revenue,
       ROUND(SUM(profit),2) profit,
       COUNT(DISTINCT order_id) orders
FROM vw_sales_detail
GROUP BY store_region
ORDER BY revenue DESC;


# Store revenue vs profit
SELECT store_name,
       ROUND(SUM(revenue),2) revenue,
       ROUND(SUM(profit),2) profit,
       ROUND(SUM(profit)/SUM(revenue)*100,2) margin_pct
FROM vw_sales_detail
GROUP BY store_name
ORDER BY revenue DESC;


# Best store by region
WITH store_perf AS (
    SELECT store_region, store_name, SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY store_region, store_name
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY store_region ORDER BY revenue DESC) rnk
    FROM store_perf
)
SELECT store_region, store_name, ROUND(revenue,2) revenue
FROM ranked
WHERE rnk = 1;


# Stores with above-average revenue
WITH store_sales AS (
    SELECT store_id, store_name, SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY store_id, store_name
)
SELECT *
FROM store_sales
WHERE revenue > (SELECT AVG(revenue) FROM store_sales)
ORDER BY revenue DESC;


# Total returns
SELECT COUNT(*) total_returns FROM returns;


# Return rate
SELECT ROUND(
    COUNT(DISTINCT r.return_id) / COUNT(DISTINCT oi.order_item_id) * 100, 2
) return_rate_pct
FROM order_items oi
LEFT JOIN returns r
ON oi.order_item_id = (
    SELECT MIN(oi2.order_item_id)
    FROM order_items oi2
    WHERE oi2.order_id=oi.order_id AND oi2.product_id=oi.product_id
);


# Returns by reason
SELECT reason, COUNT(*) return_count
FROM returns
GROUP BY reason
ORDER BY return_count DESC;


# Products with most returns
SELECT p.product_name, p.category, COUNT(*) return_count
FROM returns r
JOIN products p ON r.product_id=p.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY return_count DESC
LIMIT 15;


# Returns by category
SELECT p.category, COUNT(*) return_count
FROM returns r
JOIN products p ON r.product_id=p.product_id
GROUP BY p.category
ORDER BY return_count DESC;



# Advance window functions
# Running monthly revenue
WITH monthly AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') month,
           SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
)
SELECT month,
       ROUND(revenue,2) revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month),2) running_revenue
FROM monthly
ORDER BY month;


# Rank customers within each region
WITH customer_region AS (
    SELECT customer_region, customer_id, customer_name,
           SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY customer_region, customer_id, customer_name
)
SELECT *,
       RANK() OVER (PARTITION BY customer_region ORDER BY revenue DESC) regional_rank
FROM customer_region
ORDER BY customer_region, regional_rank;


# Top 3 products per category
WITH product_sales AS (
    SELECT category, product_id, product_name, SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY category, product_id, product_name
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY revenue DESC) rn
    FROM product_sales
)
SELECT category, product_id, product_name, ROUND(revenue,2) revenue
FROM ranked
WHERE rn <= 3
ORDER BY category, rn;


# Customer purchase sequence
SELECT customer_id, order_id, order_date,
       ROW_NUMBER() OVER (
           PARTITION BY customer_id ORDER BY order_date
       ) purchase_number
FROM orders;


# Days between customer purchases
SELECT customer_id, order_id, order_date,
       LAG(order_date) OVER (
           PARTITION BY customer_id ORDER BY order_date
       ) previous_order_date,
       DATEDIFF(
           order_date,
           LAG(order_date) OVER (
               PARTITION BY customer_id ORDER BY order_date
           )
       ) days_since_previous_order
FROM orders;


# Monthly category ranking
WITH monthly_category AS (
    SELECT DATE_FORMAT(order_date,'%Y-%m') month,
           category,
           SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY DATE_FORMAT(order_date,'%Y-%m'), category
)
SELECT *,
       RANK() OVER (PARTITION BY month ORDER BY revenue DESC) category_rank
FROM monthly_category
ORDER BY month, category_rank;


# Revenue contribution by category
WITH cat AS (
    SELECT category, SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY category
)
SELECT category,
       ROUND(revenue,2) revenue,
       ROUND(revenue / SUM(revenue) OVER () * 100,2) contribution_pct
FROM cat
ORDER BY revenue DESC;


#High revenue but low margin products
SELECT product_id, product_name,
       ROUND(SUM(revenue),2) revenue,
       ROUND(SUM(profit)/SUM(revenue)*100,2) margin_pct
FROM vw_sales_detail
GROUP BY product_id, product_name
HAVING SUM(revenue) > (
    SELECT AVG(x.revenue)
    FROM (
        SELECT SUM(revenue) revenue
        FROM vw_sales_detail
        GROUP BY product_id
    ) x
)
AND SUM(profit)/SUM(revenue) < 0.20
ORDER BY revenue DESC;


# Customer segment distribution
WITH rfm AS (
    SELECT customer_id,
           DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(order_date)) recency,
           COUNT(DISTINCT order_id) frequency,
           SUM(revenue) monetary
    FROM vw_sales_detail
    GROUP BY customer_id
),
scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency DESC) r_score,
        NTILE(5) OVER (ORDER BY frequency) f_score,
        NTILE(5) OVER (ORDER BY monetary) m_score
    FROM rfm
)
SELECT
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
        WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalist'
        WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
        ELSE 'Regular'
    END segment,
    COUNT(*) customers
FROM scores
GROUP BY segment
ORDER BY customers DESC;


# Missing customer IDs in orders
SELECT COUNT(*) missing_customer_links
FROM orders o
LEFT JOIN customers c ON o.customer_id=c.customer_id
WHERE c.customer_id IS NULL;


# Invalid product links
SELECT COUNT(*) invalid_product_links
FROM order_items oi
LEFT JOIN products p ON oi.product_id=p.product_id
WHERE p.product_id IS NULL;


# Negative/zero quantity check
SELECT COUNT(*) invalid_quantity_rows
FROM order_items
WHERE quantity <= 0;


# Duplicate order IDs
SELECT order_id, COUNT(*) cnt
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;


# Discount validation
SELECT COUNT(*) invalid_discounts
FROM order_items
WHERE discount < 0 OR discount > 1;
