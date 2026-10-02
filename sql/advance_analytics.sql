# top 20 customers by revenue
SELECT customer_id, customer_name, ROUND(SUM(revenue),2) revenue
FROM vw_sales_detail
GROUP BY customer_id, customer_name
ORDER BY revenue DESC
LIMIT 20;


# Customer order frequency
SELECT customer_id, customer_name, COUNT(DISTINCT order_id) order_count
FROM vw_sales_detail
GROUP BY customer_id, customer_name
ORDER BY order_count DESC;


# Repeat customers
SELECT customer_id, customer_name, COUNT(DISTINCT order_id) order_count
FROM vw_sales_detail
GROUP BY customer_id, customer_name
HAVING COUNT(DISTINCT order_id) > 1
ORDER BY order_count DESC;


# Repeat customer revenue percentage
WITH customer_orders AS (
    SELECT customer_id, COUNT(DISTINCT order_id) order_count, SUM(revenue) revenue
    FROM vw_sales_detail
    GROUP BY customer_id
)
SELECT ROUND(SUM(CASE WHEN order_count > 1 THEN revenue ELSE 0 END)/ SUM(revenue) * 100, 2) repeat_customer_revenue_pct
FROM customer_orders;


# Customer average order value
SELECT customer_id, customer_name,ROUND(SUM(revenue)/COUNT(DISTINCT order_id),2) avg_order_value
FROM vw_sales_detail
GROUP BY customer_id, customer_name
ORDER BY avg_order_value DESC;


# Customer lifetime value proxy
SELECT customer_id, customer_name,ROUND(SUM(revenue),2) lifetime_revenue
FROM vw_sales_detail
GROUP BY customer_id, customer_name
ORDER BY lifetime_revenue DESC;


# Customer recency
SELECT customer_id, customer_name,MAX(order_date) last_purchase,
	DATEDIFF((SELECT MAX(order_date) FROM orders), 
	MAX(order_date)) recency_days
FROM vw_sales_detail
GROUP BY customer_id, customer_name
ORDER BY recency_days;


# Customers inactive for more than 180 days
SELECT customer_id, customer_name,
       MAX(order_date) last_purchase,
       DATEDIFF((SELECT MAX(order_date) FROM orders), MAX(order_date)) recency_days
FROM vw_sales_detail
GROUP BY customer_id, customer_name
HAVING recency_days > 180
ORDER BY recency_days DESC;


# RFM raw metrics
WITH customer_rfm AS (
    SELECT customer_id,
        MAX(order_date) last_purchase,
        COUNT(DISTINCT order_id) frequency,
        SUM(revenue) monetary
    FROM vw_sales_detail
    GROUP BY customer_id
)
SELECT customer_id,
       DATEDIFF((SELECT MAX(order_date) FROM orders), last_purchase) recency,
       frequency,
       ROUND(monetary,2) monetary
FROM customer_rfm;


# RFM scoring and segmentation
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
SELECT *,
       CONCAT(r_score,f_score,m_score) rfm_score,
       CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'VIP'
           WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal'
           WHEN r_score >= 3 AND f_score >= 3 THEN 'Potential Loyalist'
           WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
           WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
           ELSE 'Regular'
       END segment
FROM scores
ORDER BY monetary DESC;
