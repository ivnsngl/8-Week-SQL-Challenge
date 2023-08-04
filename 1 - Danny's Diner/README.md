# Case Study 1: Danny's Diner

## Problem Statement
Danny wants to analyze customer data to understand visiting patterns, spending, and favorite menu items. This will help him improve the personalized experience for loyal customers. He also needs assistance in generating basic datasets for easy inspection by his team without using SQL. Danny has shared three key datasets: `sales`, `menu`, and `members` for this case study.

***

## Questions And Solutions
**1. What is the total amount each customer spent at the restaurant?**

#### Answer:
````sql
SELECT
	sales.customer_id,
	SUM(menu.price) AS total_spent
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY sales.customer_id ASC;
````

#### Output:
| customer_id | total_sales |
| ----------- | ----------- |
| A           | 76          |
| B           | 74          |
| C           | 36          |

***

**2. How many days has each customer visited the restaurant?**

#### Answer:
````sql
SELECT
	customer_id,
    	COUNT(DISTINCT(order_date))
FROM dannys_diner.sales
GROUP BY customer_id;
````

#### Output:
| customer_id | count       |
| ----------- | ----------- |
| A           | 4           |
| B           | 6           |
| C           | 2           |

***

**3. What was the first item from the menu purchased by each customer?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | product_name|
| ----------- | ----------- |
| A           | curry       |
| B           | curry       |
| C           | ramen       |

***

**4. What is the most purchased item on the menu and how many times was it purchased by all customers?**

#### Answer:
````sql
SELECT
	menu.product_name,
    	COUNT(sales.product_id) AS total_purchase
FROM dannys_diner.sales
INNER JOIN dannys_diner.menu
	ON menu.product_id = sales.product_id
GROUP BY menu.product_name
LIMIT 1;
````

#### Output:
| product_name | total_purchase |
| -----------  | -------------  |
| ramen        | 8              |

***

**5. Which item was the most popular for each customer?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | product_name | order_count |
| ----------- | ------------ | ----------- |
| A           | ramen        | 3           |
| B           | ramen        | 2           |
| B           | curry        | 2           |
| B           | sushi        | 2           |
| C           | ramen        | 3           |

***

**6. Which item was purchased first by the customer after they became a member?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | product_name |
| ----------- | ------------ |
| A           | ramen        |
| B           | sushi        |

***

**7. Which item was purchased just before the customer became a member?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | product_name |
| ----------- | ------------ |
| A           | sushi        |
| B           | sushi        |

***

**8. What is the total items and amount spent for each member before they became a member?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | total_items | amount_spent |
| ----------- | ----------- | ------------ |
| A           | 2           | 25           |
| B           | 3           | 40           |

***

**9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 860          |
| B           | 940          |
| C           | 360          |

***

**10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?**

#### Answer:
````sql
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
````

#### Output:
| customer_id | total_points |
| ----------- | ------------ |
| A           | 1020         |
| B           | 440          |

***

## Bonus Question

**1. Join All The Things**

#### Answer:
````sql
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
````

#### Output:
| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***

**2. Rank All The Things**

#### Answer:
````sql
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
````

#### Output:
| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL    |
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |

***
