-- PART 1

COPY users
FROM 'D:\SQL\data\users.csv'
DELIMITER ','
CSV HEADER;

COPY products
FROM 'D:\SQL\data\products.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM users;
SELECT * FROM products;

-- part 1_1
/* Для каждого города выведите число покупателей из соответствующей таблицы,
   сгруппированных по возрастным категориям и отсортированных по убыванию количества покупателей в каждой категории. */

SELECT
    city,
    CASE
        WHEN age::INTEGER < 20 THEN 'young'
        WHEN age::INTEGER BETWEEN 21 AND 49 THEN 'adult'
        WHEN age::INTEGER >= 50 THEN 'old'
    END AS age_category,
    COUNT(id) AS num_buyers
FROM users
GROUP BY city, age_category
ORDER BY city, num_buyers DESC;


--part 1_2
/* Рассчитайте среднюю цену категорий товаров в таблице products, в названиях товаров которых присутствуют слова «hair» или «home».
   Среднюю цену округлите до двух знаков после запятой. Столбец с полученным значением назовите avg_price. */

SELECT
    category,
    ROUND(AVG(price::NUMERIC), 2) AS avg_price
FROM products
WHERE LOWER(name) LIKE '%hair%' OR LOWER(name) LIKE '%home%'
GROUP BY category
ORDER BY avg_price DESC;


/* PART 2 */

COPY sellers
FROM 'D:\SQL\data\sellers.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM sellers;

-- part 2_2
/* Выведите для каждого продавца количество категорий, средний рейтинг его категорий, суммарную выручку, а также метку ‘poor’ или ‘rich’. */

SELECT
    seller_id,
    COUNT(DISTINCT category) AS total_categ,
    AVG(rating) AS avg_rating,
    SUM(revenue) AS total_revenue,
    CASE
        WHEN COUNT(DISTINCT category) > 1 AND SUM(revenue) > 50000 THEN 'rich'
        WHEN COUNT(DISTINCT category) > 1 AND SUM(revenue) <= 50000 THEN 'poor'
    END AS seller_type
FROM sellers
GROUP BY seller_id
HAVING COUNT(DISTINCT category) > 1
ORDER BY seller_id;

--part 2_2
/* Для каждого из неуспешных продавцов (из предыдущего задания) посчитайте, сколько полных месяцев прошло с даты регистрации продавца.
   Также выведите разницу между максимальным и минимальным сроком доставки среди неуспешных продавцов. */

SELECT
    seller_id,
    date_reg,
    COUNT(DISTINCT category) AS total_categ,
    SUM(revenue) AS total_revenue
FROM sellers
GROUP BY seller_id, date_reg
HAVING COUNT(DISTINCT category) > 1
    AND SUM(revenue) <= 50000;

SELECT
    seller_id,
    FLOOR((CURRENT_DATE - date_reg) / 30) AS month_from_registration,  -- Разница в днях / 30 для получения месяцев
    (SELECT MAX(delivery_days) - MIN(delivery_days)
     FROM sellers) AS max_delivery_difference
FROM sellers
ORDER BY seller_id;


--part 2_3
/* Выведите seller_id данных продавцов, а также столбец category_pair с наименованиями категорий, которые продают данные селлеры. */

SELECT
    seller_id,
    STRING_AGG(DISTINCT category, ' - ' ORDER BY category) AS category_pair
FROM
    sellers
WHERE
    EXTRACT(YEAR FROM date_reg) = 2022  -- Преобразуем поле с датой и сравниваем с 2022
GROUP BY
    seller_id
HAVING
    COUNT(DISTINCT category) = 2
    AND SUM(revenue) > 75000;



