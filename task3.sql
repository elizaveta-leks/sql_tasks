-- Part 1
/* Выведите список сотрудников с именами сотрудников, получающими самую высокую зарплату в отделе.
    Выведите аналогичный список, но теперь укажите сотрудников с минимальной зарплатой.
    В каждом случае реализуйте расчет двумя способами: с использованием функций min max (без оконных функций) и с использованием first/last value */

COPY selary
FROM 'D:\SQL\data\Salary.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM selary;

-- Сотрудники с самой высокой зарплатой в каждом отделе

-- без оконных функций
SELECT
    first_name,
    last_name,
    salary,
    industry,
    -- Имя сотрудника с самой высокой зарплатой в каждом отделе
    (SELECT first_name || ' ' || last_name
     FROM selary s2
     WHERE s2.industry = s1.industry
     ORDER BY salary DESC
     LIMIT 1) AS name_highest_sal
FROM selary s1
WHERE salary = (SELECT MAX(salary)
                FROM selary s2
                WHERE s2.industry = s1.industry)
ORDER BY industry;

-- с использованием first value
SELECT
    first_name,
    last_name,
    salary,
    industry,
    FIRST_VALUE(first_name || ' ' || last_name) OVER (PARTITION BY industry ORDER BY salary DESC) AS name_highest_sal
FROM selary
WHERE salary = (SELECT MAX(salary)
                FROM selary s2
                WHERE s2.industry = selary.industry)
ORDER BY industry;

-- Сотрудники с самой низкой зарплатой в каждом отделе

-- без оконных функций
SELECT
    first_name,
    last_name,
    salary,
    industry,
    -- Имя сотрудника с самой высокой зарплатой в каждом отделе
    (SELECT first_name || ' ' || last_name
     FROM selary s2
     WHERE s2.industry = s1.industry
     ORDER BY salary ASC
     LIMIT 1) AS name_highest_sal
FROM selary s1
WHERE salary = (SELECT MIN(salary)
                FROM selary s2
                WHERE s2.industry = s1.industry)
ORDER BY industry;

-- с использованием last value
SELECT
    first_name,
    last_name,
    salary,
    industry,
    LAST_VALUE(first_name || ' ' || last_name) OVER (PARTITION BY industry ORDER BY salary ASC) AS name_highest_sal
FROM selary
WHERE salary = (SELECT MIN(salary)
                FROM selary s2
                WHERE s2.industry = selary.industry)
ORDER BY industry;


-- Part 2

COPY goods
FROM 'D:/SQL/data/GOODS.csv'
DELIMITER ';'
CSV HEADER
ENCODING 'WIN1251';

COPY shops
FROM 'D:/SQL/data/SHOPS.csv'
DELIMITER ';'
CSV HEADER
ENCODING 'WIN1251';

COPY sales
FROM 'D:/SQL/data/SALES.csv'
DELIMITER ';'
CSV HEADER
ENCODING 'WIN1251';

SELECT * FROM goods;
SELECT * FROM shops;
SELECT * FROM sales;

-- part 2_1
/* Отберите данные по продажам за 2.01.2016. Укажите для каждого магазина его адрес, сумму проданных товаров в штуках, сумму проданных товаров в рублях.
        Столбцы в результирующей таблице: SHOPNUMBER , CITY , ADDRESS, SUM_QTY SUM_QTY_PRICE */

SELECT
    s."SHOPNUMBER",
    sh."CITY",
    sh."ADDRESS",
    SUM(s."QTY") OVER (PARTITION BY s."SHOPNUMBER") AS SUM_QTY,  -- Сумма проданных товаров в штуках
    SUM(s."QTY" * g."PRICE") OVER (PARTITION BY s."SHOPNUMBER") AS SUM_QTY_PRICE  -- Сумма проданных товаров в рублях
FROM sales s
JOIN shops sh ON s."SHOPNUMBER" = sh."SHOPNUMBER"
JOIN goods g ON s."ID_GOOD" = g."ID_GOOD"
WHERE s."DATE" = '2016-01-02'
ORDER BY s."SHOPNUMBER";


-- part 2_2
/* Отберите за каждую дату долю от суммарных продаж (в рублях на дату). Расчеты проводите только по товарам направления ЧИСТОТА.
    Столбцы в результирующей таблице: DATE_, CITY, SUM_SALES_REL */

SELECT
    s."DATE",
    sh."CITY",
    SUM(s."QTY" * g."PRICE")
    / SUM(SUM(s."QTY" * g."PRICE") ) OVER (PARTITION BY s."DATE") AS SUM_SALES_REL
FROM sales s
JOIN shops sh ON s."SHOPNUMBER" = sh."SHOPNUMBER"
JOIN goods g ON s."ID_GOOD" = g."ID_GOOD"
WHERE g."CATEGORY" = 'ЧИСТОТА'
GROUP BY s."DATE", sh."CITY"
ORDER BY s."DATE", sh."CITY";



-- part 2_3
/* Выведите информацию о топ-3 товарах по продажам в штуках в каждом магазине в каждую дату.
    Столбцы в результирующей таблице: DATE_ , SHOPNUMBER, ID_GOOD */





-- part 2_4
/* Выведите для каждого магазина и товарного направления сумму продаж в рублях за предыдущую дату. Только для магазинов Санкт-Петербурга.
    Столбцы в результирующей таблице: DATE_, SHOPNUMBER, CATEGORY, PREV_SALES */

SELECT
    "DATE",
    "SHOPNUMBER",
    "CATEGORY",
    SUM(COALESCE("PREV_SALES", 0))
FROM (
    SELECT
        s."DATE",
        s."SHOPNUMBER",
        g."CATEGORY",
        LEAD(s."QTY" * g."PRICE") OVER (PARTITION BY s."SHOPNUMBER", g."CATEGORY" ORDER BY s."DATE") AS "PREV_SALES"
    FROM sales s
    JOIN shops sh ON s."SHOPNUMBER" = sh."SHOPNUMBER"
    JOIN goods g ON s."ID_GOOD" = g."ID_GOOD"
    WHERE sh."CITY" = 'СПб'  -- Фильтруем только для магазинов в Санкт-Петербурге
      AND s."DATE" > '2016-01-01'  -- Убираем возможные проблемы с первой датой в данных
    ORDER BY s."SHOPNUMBER", s."DATE", g."CATEGORY"
     ) as ssg
GROUP BY "DATE", "SHOPNUMBER", "CATEGORY"; -- Группировка нужна для суммы


-- Part 3
/* Создайте таблицу query (количество строк - порядка 20) с данными о поисковых запросах на маркетплейсе.
    Поля в таблице: searchid, year, month, day, userid, ts, devicetype, deviceid, query. ts- время запроса в формате unix.
    Рекомендация по наполнению столбца query: Заносите последовательные поисковые запросы. Например, к, ку, куп, купить, купить кур, купить куртку. */

CREATE TABLE query (
    searchid SERIAL PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    userid INT,
    ts BIGINT, -- Время в формате Unix
    devicetype VARCHAR(50),
    deviceid VARCHAR(50),
    query VARCHAR(255)
);

-- Вставка данных (пример данных)
INSERT INTO query (year, month, day, userid, ts, devicetype, deviceid, query)
VALUES
(2024, 11, 24, 1, 1732160000, 'android', 'device1', 'к'),
(2024, 11, 24, 1, 1732160300, 'android', 'device1', 'ку'),
(2024, 11, 24, 1, 1732160600, 'android', 'device1', 'куп'),
(2024, 11, 24, 1, 1732160900, 'android', 'device1', 'купить'),
(2024, 11, 24, 1, 1732161200, 'android', 'device1', 'купить кур'),
(2024, 11, 24, 1, 1732161500, 'android', 'device1', 'купить куртку'),
(2024, 11, 24, 2, 1732160000, 'android', 'device2', 'телефон'),
(2024, 11, 24, 2, 1732160300, 'android', 'device2', 'купить телефон'),
(2024, 11, 24, 2, 1732160600, 'android', 'device2', 'купить телефон андроид'),
(2024, 11, 24, 2, 1732160661, 'android', 'device2', 'планшет'),
(2024, 11, 24, 2, 1732161200, 'android', 'device2', 'купить планшет'),
(2024, 11, 24, 3, 1732160000, 'android', 'device3', 'косметика'),
(2024, 11, 24, 3, 1732160300, 'android', 'device3', 'купить косметику'),
(2024, 11, 24, 3, 1732160600, 'android', 'device3', 'косметика для лица'),
(2024, 11, 24, 3, 1732160900, 'android', 'device3', 'шампунь'),
(2024, 11, 24, 4, 1732160000, 'android', 'device4', 'продукты'),
(2024, 11, 24, 4, 1732160300, 'android', 'device4', 'купить продукты'),
(2024, 11, 24, 4, 1732160600, 'android', 'device4', 'продукты питания'),
(2024, 11, 24, 5, 1732160000, 'android', 'device5', 'аксессуары'),
(2024, 11, 24, 5, 1732160300, 'android', 'device5', 'купить аксессуары'),
(2024, 11, 24, 5, 1732160900, 'android', 'device5', 'купить очки');


SELECT * FROM query;

/* Для каждого запроса определим значение is_final:
Если пользователь вбил запрос (с определенного устройства), и после данного запроса больше ничего не искал, то значение равно 1
Если пользователь вбил запрос (с определенного устройства), и до следующего запроса прошло более 3х минут, то значение также равно 1
Если пользователь вбил запрос (с определенного устройства), И следующий запрос был короче, И до следующего запроса прошло прошло более минуты, то значение равно 2
Иначе - значение равно 0
Выведите данные о запросах в определенный день (выберите сами), у которых is_final пользователей устройства android равен 1 или 2. */

SELECT
    year,
    month,
    day,
    userid,
    ts,
    devicetype,
    deviceid,
    query,
    LEAD(query) OVER (PARTITION BY userid, deviceid ORDER BY ts) AS next_query,
    LEAD(ts) OVER (PARTITION BY userid, deviceid ORDER BY ts) AS next_ts,
    -- Вычисляем is_final по правилам
    CASE
        WHEN LEAD(query) OVER (PARTITION BY userid, deviceid ORDER BY ts) IS NULL THEN 1  -- Если следующего запроса нет
        WHEN LEAD(ts) OVER (PARTITION BY userid, deviceid ORDER BY ts) - ts > 180 THEN 1  -- Если прошло больше 3 минут
        WHEN LENGTH(LEAD(query) OVER (PARTITION BY userid, deviceid ORDER BY ts)) < LENGTH(query)
             AND LEAD(ts) OVER (PARTITION BY userid, deviceid ORDER BY ts) - ts > 60 THEN 2  -- Если следующий запрос короче и прошло больше 1 минуты
        ELSE 0
    END AS is_final
FROM query
ORDER BY ts;












