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

-- A. Pizza Metrics
-- 1. How many pizzas were ordered?

SELECT
  COUNT(customer_orders.order_id) AS orders
FROM pizza_runner.customer_orders;



-- 2. How many unique customer orders were made?

SELECT
	COUNT(DISTINCT customer_orders.order_id) AS orders
FROM pizza_runner.customer_orders;



-- 3. How many successful orders were delivered by each runner?

SELECT
	runner_orders.runner_id,
	COUNT(runner_orders.runner_id) AS delivered
FROM pizza_runner.runner_orders
GROUP BY runner_orders.runner_id
ORDER BY runner_orders.runner_id ASC;



-- 4. How many of each type of pizza was delivered?

SELECT
	customer_orders.pizza_id,
  pizza_names.pizza_name,
  COUNT(customer_orders.pizza_id) AS total_orders
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names
	ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.pizza_id, pizza_names.pizza_name
ORDER BY customer_orders.pizza_id ASC;



-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT
	customer_orders.customer_id,
    pizza_names.pizza_name,
    COUNT(customer_orders.pizza_id) as total
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.pizza_names
	ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_orders.customer_id, pizza_names.pizza_name
ORDER BY customer_orders.customer_id ASC;



-- 6. What was the maximum number of pizzas delivered in a single order?

WITH pizza_cte AS
(
  SELECT
  	customer_orders.order_id,
  	COUNT(customer_orders.order_id) as total
  FROM pizza_runner.customer_orders
  INNER JOIN pizza_runner.runner_orders
  	ON customer_orders.order_id = runner_orders.order_id
  WHERE runner_orders.cancellation is NULL
  GROUP BY customer_orders.order_id
)

SELECT
	MAX(total) AS total
FROM pizza_cte;



-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT
	customer_orders.customer_id,
  SUM
  (
    CASE
      WHEN customer_orders.exclusions != '0' OR customer_orders.extras != '0'
      THEN 1
      ELSE 0
    END
  ) AS with_changes,
  SUM
  (
    CASE
      WHEN customer_orders.exclusions = '0' AND customer_orders.extras = '0'
      THEN 1
      ELSE 0
    END
  ) AS no_changes
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders
	ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY customer_orders.customer_id
ORDER BY customer_orders.customer_id ASC;



-- 8. How many pizzas were delivered that had both exclusions and extras?

WITH pizza_exclusions_extras_cte AS
(
SELECT
	customer_orders.customer_id,
  SUM
  (
    CASE
      WHEN customer_orders.exclusions != '0' AND customer_orders.extras != '0'
      THEN 1
      ELSE 0
    END
  ) AS count_exlcusions_extras
FROM pizza_runner.customer_orders
INNER JOIN pizza_runner.runner_orders
	ON customer_orders.order_id = runner_orders.order_id
WHERE runner_orders.cancellation IS NULL
GROUP BY customer_orders.customer_id
ORDER BY customer_orders.customer_id ASC
)

SELECT
	SUM(count_exlcusions_extras) AS count_exlcusions_extras
FROM pizza_exclusions_extras_cte;



-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT
	EXTRACT(HOUR FROM customer_orders.order_time) AS hour,
	COUNT(customer_orders.order_id) AS pizza_total
FROM pizza_runner.customer_orders
GROUP BY hour
ORDER BY hour ASC;



-- 10. What was the volume of orders for each day of the week?

SELECT 
	to_char(customer_orders.order_time, 'Day') AS day_of_week, 
  COUNT(customer_orders.order_id) AS pizza_ordered
FROM pizza_runner.customer_orders
GROUP BY day_of_week
ORDER BY pizza_ordered DESC;