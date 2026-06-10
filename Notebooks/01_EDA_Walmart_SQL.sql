/* =========================================================
   PROJETO WALMART - EDA EM SQL SERVER
   Objetivo:
   - limpar e organizar orders em uma VIEW
   - combinar tabelas por IDs
   - responder às perguntas do projeto
   - preparar base para ML posterior no Python
   ========================================================= */


/* =========================================================
   0) INSPEÇÃO INICIAL
   ========================================================= */

SELECT COUNT(*) AS total_orders FROM orders;
SELECT COUNT(*) AS total_missing_items_rows FROM missing_items_data;
SELECT COUNT(*) AS total_drivers FROM drivers_data;
SELECT COUNT(*) AS total_products FROM products_data;
SELECT COUNT(*) AS total_customers FROM customers_data;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'orders',
    'missing_items_data',
    'drivers_data',
    'products_data',
    'customers_data'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;


/* =========================================================
   1) QUALIDADE DOS DADOS - NULOS
   ========================================================= */

SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN [date] IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN order_amount IS NULL THEN 1 ELSE 0 END) AS null_order_amount,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN items_delivered IS NULL THEN 1 ELSE 0 END) AS null_items_delivered,
    SUM(CASE WHEN items_missing IS NULL THEN 1 ELSE 0 END) AS null_items_missing,
    SUM(CASE WHEN delivery_hour IS NULL THEN 1 ELSE 0 END) AS null_delivery_hour,
    SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) AS null_driver_id,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id
FROM orders;

SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN product_id_1 IS NULL THEN 1 ELSE 0 END) AS null_product_id_1,
    SUM(CASE WHEN product_id_2 IS NULL THEN 1 ELSE 0 END) AS null_product_id_2,
    SUM(CASE WHEN product_id_3 IS NULL THEN 1 ELSE 0 END) AS null_product_id_3
FROM missing_items_data;

SELECT
    SUM(CASE WHEN driver_id IS NULL THEN 1 ELSE 0 END) AS null_driver_id,
    SUM(CASE WHEN driver_name IS NULL THEN 1 ELSE 0 END) AS null_driver_name,
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS null_driver_age,
    SUM(CASE WHEN trips IS NULL THEN 1 ELSE 0 END) AS null_trips
FROM drivers_data;

SELECT
    SUM(CASE WHEN produc_id IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END) AS null_product_name,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS null_price
FROM products_data;

SELECT
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END) AS null_customer_name,
    SUM(CASE WHEN customer_age IS NULL THEN 1 ELSE 0 END) AS null_customer_age
FROM customers_data;


/* =========================================================
   2) DUPLICADOS
   ========================================================= */

SELECT order_id, COUNT(*) AS qtd
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*) AS qtd
FROM missing_items_data
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT driver_id, COUNT(*) AS qtd
FROM drivers_data
GROUP BY driver_id
HAVING COUNT(*) > 1;

SELECT produc_id, COUNT(*) AS qtd
FROM products_data
GROUP BY produc_id
HAVING COUNT(*) > 1;

SELECT customer_id, COUNT(*) AS qtd
FROM customers_data
GROUP BY customer_id
HAVING COUNT(*) > 1;


/* =========================================================
   3) VIEW LIMPA DE ORDERS
   ========================================================= */


CREATE VIEW dbo.vw_orders_clean AS
SELECT
    order_id,
    TRY_CONVERT(date, [date]) AS order_date,

    YEAR(TRY_CONVERT(date, [date]))  AS order_year,
    MONTH(TRY_CONVERT(date, [date])) AS order_month,
    DATENAME(MONTH, TRY_CONVERT(date, [date])) AS month_name,

    TRY_CAST(
        REPLACE(REPLACE(LTRIM(RTRIM(order_amount)), '$', ''), ',', '')
        AS DECIMAL(18,2)
    ) AS order_amount_num,

    region,

    TRY_CAST(items_delivered AS INT) AS items_delivered_num,
    TRY_CAST(items_missing AS INT) AS items_missing_num,

    ISNULL(TRY_CAST(items_delivered AS INT),0) +
    ISNULL(TRY_CAST(items_missing AS INT),0) AS items_total,

    CAST(ISNULL(TRY_CAST(items_missing AS INT),0) AS FLOAT) /
    NULLIF(
        ISNULL(TRY_CAST(items_delivered AS INT),0) +
        ISNULL(TRY_CAST(items_missing AS INT),0),
        0
    ) AS missing_rate,

    CASE
        WHEN ISNULL(TRY_CAST(items_missing AS INT),0) > 0 THEN 1
        ELSE 0
    END AS has_missing,

    delivery_hour,

    CASE
        WHEN TRY_CONVERT(time, delivery_hour) IS NOT NULL
            THEN DATEPART(HOUR, TRY_CONVERT(time, delivery_hour))
        ELSE NULL
    END AS delivery_hour_only,

    CASE
        WHEN TRY_CONVERT(time, delivery_hour) IS NULL THEN 'Unknown'
        WHEN DATEPART(HOUR, TRY_CONVERT(time, delivery_hour)) BETWEEN 0 AND 5 THEN 'Madrugada'
        WHEN DATEPART(HOUR, TRY_CONVERT(time, delivery_hour)) BETWEEN 6 AND 11 THEN 'Manha'
        WHEN DATEPART(HOUR, TRY_CONVERT(time, delivery_hour)) BETWEEN 12 AND 17 THEN 'Tarde'
        ELSE 'Noite'
    END AS delivery_period,

    driver_id,
    customer_id
FROM orders;


SELECT TOP 20 *
FROM dbo.vw_orders_clean;


/* =========================================================
   4) VIEW LIMPA DE PRODUTOS
   ========================================================= */

IF OBJECT_ID('dbo.vw_products_clean', 'V') IS NOT NULL
    DROP VIEW dbo.vw_products_clean;
GO

CREATE VIEW dbo.vw_products_clean AS
SELECT
    produc_id,
    product_name,
    category,
    TRY_CAST(
        REPLACE(REPLACE(LTRIM(RTRIM(price)), '$', ''), ',', '')
        AS DECIMAL(18,2)
    ) AS price_num
FROM products_data;
GO

SELECT TOP 20 *
FROM dbo.vw_products_clean;


/* =========================================================
   5) VIEW LONG DE ITENS FALTANTES
   transforma product_id_1,2,3 em linhas
   ========================================================= */

IF OBJECT_ID('dbo.vw_missing_items_long', 'V') IS NOT NULL
    DROP VIEW dbo.vw_missing_items_long;
GO

CREATE VIEW dbo.vw_missing_items_long AS
SELECT order_id, product_id_1 AS product_id
FROM missing_items_data
WHERE product_id_1 IS NOT NULL

UNION ALL

SELECT order_id, product_id_2 AS product_id
FROM missing_items_data
WHERE product_id_2 IS NOT NULL

UNION ALL

SELECT order_id, product_id_3 AS product_id
FROM missing_items_data
WHERE product_id_3 IS NOT NULL;
GO

SELECT TOP 20 *
FROM dbo.vw_missing_items_long;

SELECT * FROM DBO.missing_items_data;
SELECT * FROM DBO.vw_missing_items_long;


/* =========================================================
   6) VIEW ANALÍTICA PRINCIPAL
   junta orders + drivers + customers
   ========================================================= */

IF OBJECT_ID('dbo.vw_delivery_analysis_base', 'V') IS NOT NULL
    DROP VIEW dbo.vw_delivery_analysis_base;
GO

CREATE VIEW dbo.vw_delivery_analysis_base AS
SELECT
    o.order_id,
    o.order_date,
    o.order_year,
    o.order_month,
    o.month_name,
    o.order_amount_num,
    o.region,
    o.items_delivered_num,
    o.items_missing_num,
    o.items_total,
    o.missing_rate,
    o.has_missing,
    o.delivery_hour,
    o.delivery_hour_only,
    o.delivery_period,
    o.driver_id,
    d.driver_name,
    d.age AS driver_age,
    d.trips AS driver_total_trips_2023,
    o.customer_id,
    c.customer_name,
    c.customer_age
FROM dbo.vw_orders_clean o
LEFT JOIN drivers_data d
    ON o.driver_id = d.driver_id
LEFT JOIN customers_data c
    ON o.customer_id = c.customer_id;
GO

SELECT TOP 20 *
FROM dbo.vw_delivery_analysis_base;


/* =========================================================
   7) EDA GERAL
   ========================================================= */

SELECT COUNT(*) AS total_orders
FROM dbo.vw_orders_clean;

SELECT
    SUM(has_missing) AS total_orders_with_missing_items,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS pct_orders_with_missing_items
FROM dbo.vw_orders_clean;

SELECT
    MIN(order_amount_num) AS min_order_amount,
    MAX(order_amount_num) AS max_order_amount,
    AVG(CAST(order_amount_num AS FLOAT)) AS avg_order_amount,
    STDEV(CAST(order_amount_num AS FLOAT)) AS std_order_amount
FROM dbo.vw_orders_clean;

SELECT
    MIN(items_total) AS min_items_total,
    MAX(items_total) AS max_items_total,
    AVG(CAST(items_total AS FLOAT)) AS avg_items_total,
    STDEV(CAST(items_total AS FLOAT)) AS std_items_total
FROM dbo.vw_orders_clean;

SELECT
    MIN(missing_rate) AS min_missing_rate,
    MAX(missing_rate) AS max_missing_rate,
    AVG(CAST(missing_rate AS FLOAT)) AS avg_missing_rate
FROM dbo.vw_orders_clean
WHERE missing_rate IS NOT NULL;


/* =========================================================
   8) DISTRIBUIÇÃO POR REGIÃO
   ========================================================= */

SELECT
    region,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS orders_with_missing_items,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct,
    AVG(CAST(order_amount_num AS FLOAT)) AS avg_order_amount,
    AVG(CAST(items_missing_num AS FLOAT)) AS avg_items_missing
FROM dbo.vw_delivery_analysis_base
GROUP BY region
ORDER BY problem_rate_pct DESC, total_orders DESC;


/* =========================================================
   9) DISTRIBUIÇÃO POR HORA E PERÍODO
   ========================================================= */

SELECT
    delivery_hour_only,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_orders_clean
GROUP BY delivery_hour_only
ORDER BY delivery_hour_only;

SELECT
    delivery_period,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_orders_clean
GROUP BY delivery_period
ORDER BY problem_rate_pct DESC;


/* =========================================================
   10) EVOLUÇÃO AO LONGO DO TEMPO
   ========================================================= */

SELECT
    order_month,
    month_name,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_orders_clean
GROUP BY order_month, month_name
ORDER BY order_month;

SELECT
    order_date,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_orders_clean
GROUP BY order_date
ORDER BY order_date;


/* =========================================================
   11) MOTORISTAS ACIMA DA MÉDIA
   requisito central do projeto
   ========================================================= */

WITH driver_summary AS (
    SELECT
        driver_id,
        MAX(driver_name) AS driver_name,
        MAX(driver_age) AS driver_age,
        MAX(driver_total_trips_2023) AS driver_total_trips_2023,
        COUNT(*) AS total_orders,
        SUM(has_missing) AS problem_orders,
        CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct,
        AVG(CAST(order_amount_num AS FLOAT)) AS avg_order_amount,
        AVG(CAST(items_missing_num AS FLOAT)) AS avg_items_missing
    FROM dbo.vw_delivery_analysis_base
    GROUP BY driver_id
),
overall AS (
    SELECT
        CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS overall_problem_rate_pct
    FROM dbo.vw_orders_clean
)
SELECT
    d.*,
    o.overall_problem_rate_pct
FROM driver_summary d
CROSS JOIN overall o
WHERE d.problem_rate_pct > o.overall_problem_rate_pct
ORDER BY d.problem_rate_pct DESC, d.total_orders DESC;


/* =========================================================
   12) MOTORISTA X HORÁRIO
   correlação entre motorista e ordens problemáticas
   ========================================================= */

SELECT
    driver_id,
    MAX(driver_name) AS driver_name,
    delivery_hour_only,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_delivery_analysis_base
GROUP BY driver_id, delivery_hour_only
HAVING COUNT(*) >= 5
ORDER BY problem_rate_pct DESC, total_orders DESC;


/* =========================================================
   13) MOTORISTA X REGIÃO
   ajuda a separar problema individual de problema sistêmico
   ========================================================= */

SELECT
    driver_id,
    MAX(driver_name) AS driver_name,
    region,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS problem_rate_pct
FROM dbo.vw_delivery_analysis_base
GROUP BY driver_id, region
HAVING COUNT(*) >= 5
ORDER BY problem_rate_pct DESC, total_orders DESC;


/* =========================================================
   14) CLIENTES COM RECORRÊNCIA DE RECLAMAÇÃO
   útil para investigar hipótese de fraude do consumidor
   ========================================================= */

SELECT
    customer_id,
    MAX(customer_name) AS customer_name,
    MAX(customer_age) AS customer_age,
    COUNT(*) AS total_orders,
    SUM(has_missing) AS problem_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS complaint_rate_pct,
    AVG(CAST(order_amount_num AS FLOAT)) AS avg_order_amount
FROM dbo.vw_delivery_analysis_base
GROUP BY customer_id
HAVING COUNT(*) >= 3
ORDER BY complaint_rate_pct DESC, problem_orders DESC;


/* =========================================================
   15) PEDIDOS COM MAIS ITENS FALTANDO
   ========================================================= */

SELECT TOP 50
    order_id,
    order_date,
    region,
    driver_id,
    customer_id,
    order_amount_num,
    items_total,
    items_missing_num,
    missing_rate,
    delivery_hour_only
FROM dbo.vw_orders_clean
WHERE has_missing = 1
ORDER BY items_missing_num DESC, missing_rate DESC, order_amount_num DESC;


/* =========================================================
   16) ANÁLISE DE PRODUTOS E CATEGORIAS
   ========================================================= */

SELECT
    p.category,
    COUNT(*) AS total_missing_products,
    COUNT(DISTINCT ml.order_id) AS affected_orders,
    SUM(ISNULL(p.price_num,0)) AS estimated_loss,
    AVG(CAST(p.price_num AS FLOAT)) AS avg_price
FROM dbo.vw_missing_items_long ml
LEFT JOIN dbo.vw_products_clean p
    ON ml.product_id = p.produc_id
GROUP BY p.category
ORDER BY total_missing_products DESC, estimated_loss DESC;

SELECT TOP 20
    ml.product_id,
    p.product_name,
    p.category,
    COUNT(*) AS times_reported_missing,
    COUNT(DISTINCT ml.order_id) AS affected_orders,
    SUM(ISNULL(p.price_num,0)) AS estimated_loss
FROM dbo.vw_missing_items_long ml
LEFT JOIN dbo.vw_products_clean p
    ON ml.product_id = p.produc_id
GROUP BY ml.product_id, p.product_name, p.category
ORDER BY times_reported_missing DESC, estimated_loss DESC;


/* =========================================================
   17) PRODUTO / CATEGORIA X REGIÃO
   ========================================================= */

SELECT
    o.region,
    p.category,
    COUNT(*) AS total_missing_products,
    COUNT(DISTINCT ml.order_id) AS affected_orders
FROM dbo.vw_missing_items_long ml
INNER JOIN dbo.vw_orders_clean o
    ON ml.order_id = o.order_id
LEFT JOIN dbo.vw_products_clean p
    ON ml.product_id = p.produc_id
GROUP BY o.region, p.category
ORDER BY total_missing_products DESC;


/* =========================================================
   18) PRODUTO / CATEGORIA X MOTORISTA
   ========================================================= */

SELECT TOP 30
    o.driver_id,
    d.driver_name,
    p.category,
    COUNT(*) AS total_missing_products,
    COUNT(DISTINCT ml.order_id) AS affected_orders,
    SUM(ISNULL(p.price_num,0)) AS estimated_loss
FROM dbo.vw_missing_items_long ml
INNER JOIN dbo.vw_orders_clean o
    ON ml.order_id = o.order_id
LEFT JOIN drivers_data d
    ON o.driver_id = d.driver_id
LEFT JOIN dbo.vw_products_clean p
    ON ml.product_id = p.produc_id
GROUP BY o.driver_id, d.driver_name, p.category
HAVING COUNT(DISTINCT ml.order_id) >= 3
ORDER BY estimated_loss DESC, total_missing_products DESC;


/* =========================================================
   19) ENTREGAS COMPLETAS X RECLAMAÇÃO
   aqui usamos a proxy disponível:
   pedido marcado com items_missing > 0
   ========================================================= */

SELECT
    driver_id,
    MAX(driver_name) AS driver_name,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN items_delivered_num = items_total THEN 1 ELSE 0 END) AS full_delivery_records,
    SUM(has_missing) AS complained_orders,
    CAST(100.0 * SUM(has_missing) / COUNT(*) AS DECIMAL(10,2)) AS complaint_rate_pct
FROM dbo.vw_delivery_analysis_base
GROUP BY driver_id
ORDER BY complaint_rate_pct DESC, complained_orders DESC;


/* =========================================================
   20) BASE DE FEATURES PARA PYTHON / ML
   sem score manual
   ========================================================= */

IF OBJECT_ID('dbo.vw_orders_features_for_ml', 'V') IS NOT NULL
    DROP VIEW dbo.vw_orders_features_for_ml;
GO

CREATE VIEW dbo.vw_orders_features_for_ml AS
SELECT
    o.order_id,
    o.order_date,
    o.order_month,
    o.order_amount_num,
    o.region,
    o.items_delivered_num,
    o.items_missing_num,
    o.items_total,
    o.missing_rate,
    o.has_missing,
    o.delivery_hour_only,
    o.delivery_period,
    o.driver_id,
    d.age AS driver_age,
    d.trips AS driver_total_trips_2023,
    o.customer_id,
    c.customer_age,

    AVG(CAST(o.has_missing AS FLOAT)) OVER (PARTITION BY o.driver_id) AS driver_problem_rate,
    AVG(CAST(o.has_missing AS FLOAT)) OVER (PARTITION BY o.region) AS region_problem_rate,
    AVG(CAST(o.has_missing AS FLOAT)) OVER (PARTITION BY o.customer_id) AS customer_problem_rate,

    COUNT(*) OVER (PARTITION BY o.driver_id) AS driver_orders_count,
    COUNT(*) OVER (PARTITION BY o.customer_id) AS customer_orders_count,
    AVG(CAST(o.order_amount_num AS FLOAT)) OVER (PARTITION BY o.driver_id) AS driver_avg_order_amount
FROM dbo.vw_orders_clean o
LEFT JOIN drivers_data d
    ON o.driver_id = d.driver_id
LEFT JOIN customers_data c
    ON o.customer_id = c.customer_id;
GO

SELECT TOP 50 *
FROM dbo.vw_orders_features_for_ml;
