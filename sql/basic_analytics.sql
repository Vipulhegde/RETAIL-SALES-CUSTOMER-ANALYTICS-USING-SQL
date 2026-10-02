USE retail_analytics;

CREATE VIEW vw_sales_detail AS
SELECT
    o.order_id,
    o.order_date,
    o.customer_id,
    c.customer_name,
    c.gender,
    c.age,
    c.city AS customer_city,
    c.state AS customer_state,
    c.region AS customer_region,
    o.store_id,
    s.store_name,
    s.city AS store_city,
    s.state AS store_state,
    s.region AS store_region,
    oi.order_item_id,
    oi.product_id,
    p.product_name,
    p.category,
    p.subcategory,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount),2) AS revenue,
	ROUND(oi.quantity * p.cost_price,2) AS cost,
    ROUND((oi.quantity * oi.unit_price * (1 - oi.discount))- (oi.quantity * p.cost_price),2) AS profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores s ON o.store_id = s.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;


SHOW FULL TABLES
WHERE Table_type = 'VIEW';


SELECT *
FROM vw_sales_detail
LIMIT 10;


select *
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores s ON o.store_id = s.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id;


# revenue
select quantity,unit_price,discount,quantity * unit_price * (1 - discount) AS revenue from order_items;

# cost
select quantity * cost_price as cost from order_items o join products p ON p.product_id=o.product_id;

# profit
select (oi.quantity * oi.unit_price * (1 - oi.discount)) - (oi.quantity * p.cost_price)
AS profit from order_items oi join products p ON p.product_id=oi.product_id;


# total orders, customers, units sold, revenue, profit, average order value, profit margin percentage
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    SUM(quantity) AS total_units_sold,
    ROUND(SUM(revenue), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id),2) AS average_order_value,
    ROUND(SUM(profit) / SUM(revenue) * 100,2) AS profit_margin_percentage
FROM vw_sales_detail;


# revenue, profit and profit margin percentage by category
SELECT category,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(profit), 2) AS profit,
    ROUND(SUM(profit) / SUM(revenue) * 100,2) AS profit_margin_percentage
FROM vw_sales_detail
GROUP BY category
ORDER BY profit_margin_percentage DESC;


#top 10 products by revenue
SELECT product_id, product_name,category,ROUND(SUM(revenue), 2) AS total_revenue
FROM vw_sales_detail
GROUP BY product_id,product_name,category
ORDER BY total_revenue DESC
LIMIT 10;


#top 10 products by profit
SELECT product_id,product_name,category,ROUND(SUM(profit), 2) AS total_profit
FROM vw_sales_detail
GROUP BY product_id,product_name,category
ORDER BY total_profit DESC
LIMIT 10;


#top 10 products by units sold
SELECT    product_id,product_name,category,SUM(quantity) AS units_sold
FROM vw_sales_detail
GROUP BY product_id,product_name,category
ORDER BY units_sold DESC
LIMIT 10;