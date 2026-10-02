USE retail_analytics;

DROP VIEW IF EXISTS vw_monthly_kpis;
CREATE VIEW vw_monthly_kpis AS
SELECT
    DATE_FORMAT(order_date,'%Y-%m') AS month,
    ROUND(SUM(revenue),2) AS revenue,
    ROUND(SUM(profit),2) AS profit,
    COUNT(DISTINCT order_id) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    SUM(quantity) AS units_sold
FROM vw_sales_detail
GROUP BY DATE_FORMAT(order_date,'%Y-%m');



DROP VIEW IF EXISTS vw_product_performance;
CREATE VIEW vw_product_performance AS
SELECT
    product_id,
    product_name,
    category,
    subcategory,
    ROUND(SUM(revenue),2) revenue,
    ROUND(SUM(profit),2) profit,
    SUM(quantity) units_sold,
    ROUND(SUM(profit)/NULLIF(SUM(revenue),0)*100,2) margin_pct
FROM vw_sales_detail
GROUP BY product_id, product_name, category, subcategory;



DROP VIEW IF EXISTS vw_customer_performance;
CREATE VIEW vw_customer_performance AS
SELECT
    customer_id,
    customer_name,
    customer_region,
    COUNT(DISTINCT order_id) order_count,
    ROUND(SUM(revenue),2) revenue,
    ROUND(SUM(profit),2) profit,
    ROUND(SUM(revenue)/COUNT(DISTINCT order_id),2) avg_order_value,
    MAX(order_date) last_purchase
FROM vw_sales_detail
GROUP BY customer_id, customer_name, customer_region;



DROP VIEW IF EXISTS vw_store_performance;
CREATE VIEW vw_store_performance AS
SELECT
    store_id,
    store_name,
    store_region,
    COUNT(DISTINCT order_id) orders,
    COUNT(DISTINCT customer_id) customers,
    ROUND(SUM(revenue),2) revenue,
    ROUND(SUM(profit),2) profit,
    ROUND(SUM(profit)/NULLIF(SUM(revenue),0)*100,2) margin_pct
FROM vw_sales_detail
GROUP BY store_id, store_name, store_region;



DROP PROCEDURE IF EXISTS GetSalesByDateRange;
DELIMITER //
CREATE PROCEDURE GetSalesByDateRange(IN start_date DATE, IN end_date DATE)
BEGIN
    SELECT
        DATE_FORMAT(order_date,'%Y-%m') month,
        ROUND(SUM(revenue),2) revenue,
        ROUND(SUM(profit),2) profit,
        COUNT(DISTINCT order_id) orders
    FROM vw_sales_detail
    WHERE order_date BETWEEN start_date AND end_date
    GROUP BY DATE_FORMAT(order_date,'%Y-%m')
    ORDER BY month;
END //
DELIMITER ;



#testing
CALL GetSalesByDateRange('2023-01-01', '2025-12-31');