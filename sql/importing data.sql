#importing  values and counting the rows
USE retail_analytics;

SELECT *
FROM customers
LIMIT 10;
SELECT COUNT(*)
FROM customers;

SELECT COUNT(*)
FROM products;

SELECT COUNT(*)
FROM stores;

SELECT COUNT(*)
FROM orders;

SELECT COUNT(*)
FROM order_items;

SELECT COUNT(*)
FROM returns;

# combining all counts using unions

SELECT 'Customers' AS table_name, COUNT(*) AS total_rows
FROM customers
UNION ALL
SELECT 'Products', COUNT(*)
FROM products
UNION ALL
SELECT 'Stores', COUNT(*)
FROM stores
UNION ALL
SELECT 'Orders', COUNT(*)
FROM orders
UNION ALL
SELECT 'Order Items', COUNT(*)
FROM order_items
UNION ALL
SELECT 'Returns', COUNT(*)
FROM returns;