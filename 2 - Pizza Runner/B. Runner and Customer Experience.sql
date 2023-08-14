CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
	"runner_id" INTEGER,
	"registration_date" DATE
);
INSERT INTO runners
	("runner_id", "registration_date")
VALUES
	(1, '2021-01-01'),
	(2, '2021-01-03'),
	(3, '2021-01-08'),
	(4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
	"order_id" INTEGER,
	"customer_id" INTEGER,
	"pizza_id" INTEGER,
	"exclusions" VARCHAR(4),
	"extras" VARCHAR(4),
	"order_time" TIMESTAMP
);

INSERT INTO customer_orders
	("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
VALUES
	('1', '101', '1', '0', '0', '2020-01-01 18:05:02'),
	('2', '101', '1', '0', '0', '2020-01-01 19:00:52'),
	('3', '102', '1', '0', '0', '2020-01-02 23:51:23'),
	('3', '102', '2', '0', '0', '2020-01-02 23:51:23'),
	('4', '103', '1', '4', '0', '2020-01-04 13:23:46'),
	('4', '103', '1', '4', '0', '2020-01-04 13:23:46'),
	('4', '103', '2', '4', '0', '2020-01-04 13:23:46'),
	('5', '104', '1', '0', '1', '2020-01-08 21:00:29'),
	('6', '101', '2', '0', '0', '2020-01-08 21:03:13'),
	('7', '105', '2', '0', '1', '2020-01-08 21:20:29'),
	('8', '102', '1', '0', '0', '2020-01-09 23:54:33'),
	('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
	('10', '104', '1', '0', '0', '2020-01-11 18:34:49'),
	('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
	"order_id" INTEGER,
	"runner_id" INTEGER,
	"pickup_time" TIMESTAMP,
	"distance" FLOAT,
	"duration" INTEGER,
	"cancellation" VARCHAR(23)
);

INSERT INTO runner_orders
	("order_id", "runner_id", "pickup_time", "distance", "duration", "cancellation")
VALUES
	('1', '1', '2020-01-01 18:15:34', '20', '32', NULL),
	('2', '1', '2020-01-01 19:10:54', '20', '27', NULL),
	('3', '1', '2020-01-03 00:12:37', '13.4', '20', NULL),
	('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
	('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
	('6', '3', NULL, '0', '0', 'Restaurant Cancellation'),
	('7', '2', '2020-01-08 21:30:45', '25', '25', NULL),
	('8', '2', '2020-01-10 00:15:02', '23.4', '15', NULL),
	('9', '2', NULL, '0', '0', 'Customer Cancellation'),
	('10', '1', '2020-01-11 18:50:20', '10', '10', NULL);


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
	"pizza_id" INTEGER,
	"pizza_name" TEXT
);
INSERT INTO pizza_names
	("pizza_id", "pizza_name")
VALUES
	(1, 'Meatlovers'),
	(2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
	"pizza_id" INTEGER,
	"toppings" TEXT
);
INSERT INTO pizza_recipes
	("pizza_id", "toppings")
VALUES
	(1, '1, 2, 3, 4, 5, 6, 8, 10'),
	(2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
	"topping_id" INTEGER,
	"topping_name" TEXT
);
INSERT INTO pizza_toppings
	("topping_id", "topping_name")
VALUES
	(1, 'Bacon'),
	(2, 'BBQ Sauce'),
	(3, 'Beef'),
	(4, 'Cheese'),
	(5, 'Chicken'),
	(6, 'Mushrooms'),
	(7, 'Onions'),
	(8, 'Pepperoni'),
	(9, 'Peppers'),
	(10, 'Salami'),
	(11, 'Tomatoes'),
	(12, 'Tomato Sauce');



-- B. Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT
	to_char(runners.registration_date, 'W') AS week,
	COUNT(*) as runner_count
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1;

--| week | runner_count |
--| ---- | ------------ |
--| 1    | 2            |
--| 2    | 1            |
--| 3    | 1            |



-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH avg_time_cte AS
(
SELECT
	co.customer_id,
	EXTRACT(EPOCH FROM ro.pickup_time - co.order_time) / 60 AS minutes_difference
FROM pizza_runner.customer_orders AS co
INNER JOIN pizza_runner.runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1, 2
ORDER BY 1
)

SELECT
	ROUND(AVG(minutes_difference)) AS average
FROM avg_time_cte;

--| average |
--| ------- |
--| 16      |



-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?




-- 4. What was the average distance travelled for each customer?

SELECT
	co.customer_id,
	AVG(ro.distance) AS average
FROM pizza_runner.customer_orders AS co
INNER JOIN pizza_runner.runner_orders AS ro
	ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY 1
ORDER BY 1;

--| customer_id | average            |
--| ----------- | ------------------ |
--| 101         | 20                 |
--| 102         | 16.73333333333333  |
--| 103         | 23.399999999999995 |
--| 104         | 10                 |
--| 105         | 25                 |



-- 5. What was the difference between the longest and shortest delivery times for all orders?

SELECT
	MAX(ro.duration) - MIN(ro.duration) AS difference
FROM pizza_runner.runner_orders AS ro
WHERE ro.duration != '0'
ORDER BY 1;

--| difference |
--| ---------- |
--| 30         |



-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?



-- 7. What is the successful delivery percentage for each runner?

WITH counter_cte AS
(
SELECT
	ro.runner_id,
	CASE
		WHEN ro.duration != '0' THEN 1
		ELSE 0
	END AS count
FROM pizza_runner.runner_orders AS ro
ORDER BY 1
)

SELECT
	runner_id,
	ROUND(100 * SUM(count)) / COUNT(runner_id) AS percentage
FROM counter_cte
GROUP BY 1;

--| runner_id | percentage |
--| --------- | ---------- |
--| 1         | 100        |
--| 2         | 75         |
--| 3         | 50         |
