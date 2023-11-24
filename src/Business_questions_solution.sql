USE `magist`;
-- How many orders are there in the dataset?
SELECT 
    COUNT(*) AS orders_count
FROM
    orders;

-- Are orders actually delivered? 

SELECT 
    order_status, 
    COUNT(*) AS orders
FROM
    orders
GROUP BY order_status;

-- Is Magist having user growth? 

SELECT 
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    COUNT(DISTINCT order_id) AS order_count
FROM
    orders
GROUP BY order_year , order_month
ORDER BY order_year , order_month;

-- Which are the categories with the most products?

SELECT 
    COUNT(DISTINCT product_id) AS products_count
FROM
    products;
    
-- Which are the categories with the most products?
SELECT 

    product_category_name,
    COUNT(DISTINCT product_id) AS product_id
FROM
    products
GROUP BY product_category_name
ORDER BY COUNT(product_id) DESC;

-- How many of those products were present in actual transactions?
SELECT 
    COUNT(DISTINCT oi.product_id) AS products_in_transactions
FROM
    order_items oi
        JOIN
    products p ON oi.product_id = p.product_id;
    
-- 7. What’s the price for the most expensive and cheapest products?

SELECT 
    MAX(price) AS most_expensive, MIN(price) AS cheapest
FROM
    order_items;
-- What are the highest and lowest payment values?
SELECT 
    MAX(payment_value) AS max_payment,
    MIN(payment_value) AS low_payment
FROM
    order_payments;

-- 3.1. In relation to the products:
-- What categories of tech products does Magist have?
-- pcs', 'informatica_acessorios', 'eletronicos', 'sinalizacao_e_seguranca', 'telefonia
-- How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?

-- all categories
SELECT
    COUNT(DISTINCT o.product_id) / COUNT(DISTINCT o.order_id) * 100 AS percentage_sold,
    p.product_category_name AS category
FROM
    order_items AS o
INNER JOIN
    products AS p ON p.product_id = o.product_id
GROUP BY
    p.product_category_name;

-- What’s the average price of the products being sold?
SELECT 
    AVG(price) AS average_price
FROM
    order_items;
-- Are expensive tech products popular? 

SELECT
    AVG(o.price) AS avg_price,
    p.product_category_name AS category,
    CASE
        WHEN AVG(o.price) > 100 THEN 'Expensive'
        WHEN AVG(o.price) > 50 THEN 'Moderate'
        ELSE 'Inexpensive'
    END AS price_category
FROM
    order_items AS o
INNER JOIN
    products AS p ON p.product_id = o.product_id
GROUP BY
    p.product_category_name;
  
-- 3.2. In relation to the sellers:

-- How many months of data are included in the magist database?

SELECT DISTINCT
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month
FROM
    orders;

-- How many sellers are there? 

SELECT 
    COUNT(DISTINCT seller_id) AS many_sellers
FROM
    sellers;

-- How many Tech sellers are there? I included all categories

SELECT 
    COUNT(DISTINCT s.seller_id) AS many_sellers,
    p.product_category_name AS category
FROM
    sellers AS s
        INNER JOIN
    order_items AS o ON o.seller_id = s.seller_id
        INNER JOIN
    products AS p ON p.product_id = o.product_id
GROUP BY p.product_category_name;

-- What percentage of overall sellers are Tech sellers?
-- Calculate total sellers

SET @total_sellers = (SELECT COUNT(seller_id) FROM sellers);
-- Calculate the count of tech sellers
SET @tech_sellers = (
    SELECT COUNT(distinct product_category_name)
    FROM products
    WHERE product_category_name IN ('pcs', 'informatica_acessorios', 'eletronicos', 'sinalizacao_e_seguranca', 'telefonia')
);
-- Select the variables and calculate the percentage
SELECT 
    @total_sellers,
    @tech_sellers,
    @tech_sellers / @total_sellers * 100 AS tech_sellers_percentage;

--  What is the total amount earned by all sellers? 
 
SELECT 
    SUM(ordpay.payment_value) AS total__amount_earned
FROM
    order_payments AS ordpay
        JOIN
    order_items AS o ON o.order_id = ordpay.order_id;

-- What is the total amount earned by all Tech sellers?
SELECT 
    SUM(op.payment_value) AS total_earnings,
    (SELECT 
            SUM(op_tech.payment_value)
        FROM
            order_payments op_tech
                JOIN
            order_items oi_tech ON op_tech.order_id = oi_tech.order_id
        WHERE
            oi_tech.seller_id IN (SELECT 
                    seller_id
                FROM
                    products
                WHERE
                    product_category_name IN ('pcs' , 'informatica_acessorios',
                        'eletronicos',
                        'sinalizacao_e_seguranca',
                        'telefonia'))) AS tech_earnings
FROM
    order_payments op
        JOIN
    order_items oi ON op.order_id = oi.order_id;

--  Can you work out the average monthly income of all sellers? -- Can you work out the average monthly income of Tech sellers?

    SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    AVG(op.payment_value) AS average_year_income,
    AVG(CASE
        WHEN
            p.product_category_name IN ('pcs' , 'informatica_acessorios',
                'eletronicos',
                'sinalizacao_e_seguranca',
                'telefonia')
        THEN
            op.payment_value
        ELSE NULL
    END) AS average_tech_monthly_income
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
GROUP BY YEAR(o.order_purchase_timestamp);

-- 3.3. In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered?
-- Is it right to assume that order_delivered_carrier_date is the timestamp of the package being handed over to the carrier service?

SELECT 
    AVG(DATEDIFF(day,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date)) AS average_delivery_time_days
FROM
    orders o
WHERE
    o.order_delivered_customer_date IS NOT NULL;
SELECT 
    YEAR(o.order_purchase_timestamp) AS order_year,
    MONTH(o.order_purchase_timestamp) AS order_month,
    AVG(op.payment_value) AS average_monthly_income,
    AVG(CASE
        WHEN
            p.product_category_name IN ('pcs' , 'informatica_acessorios',
                'eletronicos',
                'sinalizacao_e_seguranca',
                'telefonia')
        THEN
            op.payment_value
        ELSE NULL
    END) AS average_tech_monthly_income
FROM
    order_payments op
        JOIN
    orders o ON op.order_id = o.order_id
        JOIN
    order_items oi ON o.order_id = oi.order_id
        JOIN
    products p ON oi.product_id = p.product_id
GROUP BY order_year , order_month;

-- 3.3. In relation to the delivery time:
-- What’s the average time between the order being placed and the product being delivered?

-- Is it right to assume that order_delivered_carrier_date is the timestamp of the package being handed over to the carrier service?

SELECT 
    AVG(DATEDIFF(day,
            o.order_purchase_timestamp,
            o.order_delivered_customer_date)) AS average_delivery_time_days
FROM
    orders o
WHERE
    o.order_delivered_customer_date IS NOT NULL;
SELECT 
    order_status, COUNT(*) AS orders
FROM
    orders
GROUP BY order_status;
-- To calculate the average time between the order being placed and the product being delivered in SQL, you can use the DATEDIFF function to find the difference in days, hours, minutes, etc., between two datetime values. 
SELECT 
avg(datediff(DATE(order_delivered_carrier_date), DATE(order_purchase_timestamp)) )as `time to post`,
avg(datediff(DATE(order_delivered_customer_date), DATE(order_delivered_carrier_date))) as `time post to customer` ,
avg(datediff(DATE(order_delivered_customer_date), DATE(order_purchase_timestamp))) as `total delivery time`
FROM orders;

-- How many orders are delivered on time vs orders delivered with a delay?
-- To calculate the number of orders delivered on time versus orders delivered with a delay, you can use a SQL query similar to the following. This example assumes that you have a column named order_delivered_customer_date indicating the delivery timestamp and a column named order_estimated_delivery_date indicating the estimated delivery timestamp.
SELECT
    CASE
        WHEN order_delivered_customer_date <= order_estimated_delivery_date THEN 'On Time'
        ELSE 'Delayed'
    END AS delivery_status,
    COUNT(*) AS order_count
FROM
    orders
WHERE
    order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
GROUP BY
delivery_status;

-- Is there any pattern for delayed orders, e.g. big products being delayed more often?

SELECT 
    t.product_category_name_english AS translated_category_name,
    AVG(DATEDIFF(o.order_delivered_customer_date,
            o.order_purchase_timestamp)) AS avg_delivery_delay_days
FROM
    order_items oi
        JOIN
    orders o ON oi.order_id = o.order_id
        JOIN
    products p ON oi.product_id = p.product_id
        JOIN
    product_category_name_translation t ON p.product_category_name = t.product_category_name
WHERE
    DATEDIFF(o.order_delivered_customer_date,
            o.order_purchase_timestamp) > 0
GROUP BY t.product_category_name_english
ORDER BY avg_delivery_delay_days DESC;
