CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
    "customer_id" VARCHAR(1),
    "order_date" DATE,
    "product_id" INTEGER
);

INSERT INTO sales
    ("customer_id", "order_date", "product_id")
VALUES
    ('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');


CREATE TABLE menu (
    "product_id" INTEGER,
    "product_name" VARCHAR(5),
    "price" INTEGER
);

INSERT INTO menu
    ("product_id", "product_name", "price")
VALUES
    ('1', 'sushi', '10'),
    ('2', 'curry', '15'),
    ('3', 'ramen', '12');
  

CREATE TABLE members (
    "customer_id" VARCHAR(1),
    "join_date" DATE
);

INSERT INTO members
    ("customer_id", "join_date")
VALUES
    ('A', '2021-01-07'),
    ('B', '2021-01-09');


/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
	sales.customer_id,
    SUM(menu.price) AS total_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;




-- 2. How many days has each customer visited the restaurant?

SELECT
	customer_id,
    COUNT(DISTINCT(order_date))
FROM dannys_diner.sales
GROUP BY customer_id;




-- 3. What was the first item from the menu purchased by each customer?

WITH occurences as
(
	SELECT
 		sales.customer_id,
  		sales.order_date,
  		menu.product_name,
  		ROW_NUMBER() OVER (PARTITION BY sales.customer_id 
                           ORDER BY sales.order_date)
 		AS occurence
  	FROM dannys_diner.sales
  	INNER JOIN dannys_diner.menu
  		ON sales.product_id = menu.product_id
)

SELECT 
	customer_id,
    product_name
FROM occurences
WHERE occurence = 1
GROUP BY customer_id, product_name;




-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
	menu.product_name,
    COUNT(sales.product_id) AS total_purchase
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON menu.product_id = sales.product_id
GROUP BY menu.product_name
LIMIT 1;




-- 5. Which item was the most popular for each customer?

WITH popular AS
(
	SELECT
  		sales.customer_id,
  		menu.product_name,
  		COUNT(menu.product_id) AS order_count,
  		DENSE_RANK() OVER (
        	PARTITION BY sales.customer_id 
  			ORDER BY COUNT(sales.customer_id) DESC
        )
  		AS occurence
  	FROM dannys_diner.sales
  	INNER JOIN dannys_diner.menu
  		ON sales.product_id = menu.product_id
  	GROUP BY sales.customer_id, menu.product_name
)

SELECT
	customer_id,
    product_name,
    order_count
FROM popular
WHERE occurence = 1;




-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase AS
(
	SELECT
		sales.customer_id,
  		menu.product_name,
  		ROW_NUMBER () OVER 
  		(
        	PARTITION BY sales.customer_id
          	ORDER BY sales.customer_id
        ) AS occurence
  	FROM dannys_diner.sales
  	INNER JOIN dannys_diner.menu
  		ON sales.product_id = menu.product_id
  	INNER JOIN dannys_diner.members
  		ON sales.customer_id = members.customer_id
  		AND sales.order_date > members.join_date
)

SELECT
	customer_id,
    product_name
FROM first_purchase
WHERE occurence = 1
ORDER BY customer_id ASC;




-- 7. Which item was purchased just before the customer became a member?

WITH first_purchase AS
(
	SELECT
		sales.customer_id,
  		menu.product_name,
  		ROW_NUMBER () OVER 
  		(
        	PARTITION BY sales.customer_id
          	ORDER BY sales.customer_id
        ) AS occurence
  	FROM dannys_diner.sales
  	INNER JOIN dannys_diner.menu
  		ON sales.product_id = menu.product_id
  	INNER JOIN dannys_diner.members
  		ON sales.customer_id = members.customer_id
  		AND sales.order_date < members.join_date
)

SELECT
	customer_id,
    product_name
FROM first_purchase
WHERE occurence = 1
ORDER BY customer_id ASC;




-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
	sales.customer_id,
    COUNT(sales.product_id) as total_items,
    SUM(menu.price) AS amount_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
INNER JOIN dannys_diner.members
	ON sales.customer_id = members.customer_id
    AND sales.order_date < members.join_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;




-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH points_cte AS
(
	SELECT
  		menu.product_id,
  		CASE
  			WHEN product_id = 1 THEN price * 20
  			ELSE price * 10
  		END AS points
  	FROM dannys_diner.menu
)

SELECT
	sales.customer_id,
    SUM(points_cte.points) AS total_points
FROM dannys_diner.sales
INNER JOIN points_cte
	ON sales.product_id = points_cte.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;




-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH points_cte AS
(
	SELECT
  		menu.product_id,
  		menu.price * 20 AS points
  	FROM dannys_diner.menu
),

dates_cte AS (
  SELECT 
  	customer_id, 
  	join_date, 
  	join_date + 6 AS valid_date, 
  	DATE_TRUNC(
    	'month', '2021-01-31'::DATE)
  		+ interval '1 month' 
  		- interval '1 day' AS last_date
  FROM dannys_diner.members
)


SELECT
	sales.customer_id,
    SUM(points_cte.points) AS total_points
FROM dannys_diner.sales
INNER JOIN points_cte
	ON sales.product_id = points_cte.product_id
INNER JOIN dates_cte
	ON sales.customer_id = dates_cte.customer_id
    AND sales.order_date >= dates_cte.join_date
    AND sales.order_date <= dates_cte.last_date
    AND dates_cte.join_date <= dates_cte.valid_date
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;




-- Bonus Questions
-- 11. Join All The Things

SELECT
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
    	WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END AS member
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
LEFT JOIN dannys_diner.members
	ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date ASC;




-- 12. Rank All The Things

WITH data_cte AS
(
  SELECT
	sales.customer_id,
    sales.order_date,
    menu.product_name,
    menu.price,
    CASE
    	WHEN members.join_date > sales.order_date THEN 'N'
        WHEN members.join_date <= sales.order_date THEN 'Y'
        ELSE 'N'
    END AS member
  FROM dannys_diner.sales
  INNER JOIN dannys_diner.menu
      ON sales.product_id = menu.product_id
  LEFT JOIN dannys_diner.members
      ON sales.customer_id = members.customer_id
  ORDER BY sales.customer_id, sales.order_date ASC
)

SELECT
	*,
    CASE
    	WHEN data_cte.member = 'N' THEN NULL
        ELSE DENSE_RANK() OVER (PARTITION BY
        	customer_id, data_cte.member
          	ORDER BY order_date
        ) END AS rankings
FROM data_cte;