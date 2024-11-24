-- Part 1

COPY customers
FROM 'D:\SQL\data\customers_new_3.csv'
DELIMITER ','
CSV HEADER;

COPY orders
FROM 'D:\SQL\data\orders_new_3.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM customers;
SELECT * FROM orders;

-- part 1_1
/* Найти клиента с самым долгим временем ожидания между заказом и доставкой. */

SELECT
    c.name,
    o.shipment_date - o.order_date AS wait_time
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
ORDER BY wait_time DESC
LIMIT 1;


-- part 1_2
/* Найти клиентов, сделавших наибольшее количество заказов, и для каждого из них найти среднее время между заказом и доставкой, а также общую сумму всех их заказов.
   Вывести клиентов в порядке убывания общей суммы заказов. */

SELECT
    c.name,
    COUNT(o.order_id) AS order_count,
    AVG(o.shipment_date - o.order_date) AS avg_wait_time,  -- Среднее время ожидания
    SUM(o.order_ammount) AS total_order_ammount  -- Общая сумма заказов
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_order_ammount DESC;


-- part 1_3
/* Найти клиентов, у которых были заказы, доставленные с задержкой более чем на 5 дней, и клиентов, у которых были заказы, которые были отменены.
   Для каждого клиента вывести имя, количество доставок с задержкой, количество отмененных заказов и их общую сумму.
   Результат отсортировать по общей сумме заказов в убывающем порядке. */

SELECT
    c.name,
    COUNT(CASE WHEN o.shipment_date - o.order_date > 5 THEN 1 END) AS delayed_deliveries,  -- Количество доставок с задержкой более 5 дней
    COUNT(CASE WHEN o.order_status = 'Cancel' THEN 1 END) AS cancelled_orders,  -- Количество отмененных заказов
    SUM(o.order_ammount) AS total_order_ammount  -- Общая сумма заказов
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE (o.shipment_date - o.order_date > 5 OR o.order_status = 'cancel')  -- Фильтруем заказы с задержкой > 5 дней или отмененные
GROUP BY c.customer_id, c.name
ORDER BY total_order_ammount DESC;



-- Part 2
/* Напишите SQL-запрос, который выполнит следующие задачи:
    Вычислит общую сумму продаж для каждой категории продуктов.
    Определит категорию продукта с наибольшей общей суммой продаж.
    Для каждой категории продуктов, определит продукт с максимальной суммой продаж в этой категории. */

COPY orders_new
FROM 'D:\SQL\data\orders_2.csv'
DELIMITER ','
CSV HEADER;

COPY products_new
FROM 'D:\SQL\data\products_3.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM orders_new;
SELECT * FROM products_new;


SELECT
    p.product_category,
    SUM(o.order_ammount) AS total_sales,
    -- Подзапрос для нахождения продукта с максимальной суммой продаж в категории
    (SELECT p2.product_name
     FROM orders_new o2
     JOIN products_new p2 ON o2.product_id = p2.product_id
     WHERE p2.product_category = p.product_category
     GROUP BY p2.product_name
     ORDER BY SUM(o2.order_ammount) DESC
     LIMIT 1) AS top_product_name
FROM
    orders_new o
JOIN
    products_new p ON o.product_id = p.product_id
GROUP BY
    p.product_category
ORDER BY
    total_sales DESC;



