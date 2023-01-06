-- 1-What is the total amount each customer spent at the restaurant?

SELECT 
     s.customer_id ,
     SUM( m.price ) as total_amount
FROM sales s
JOIN
menu m 
ON
s.product_id = m.product_id 
GROUP BY 1 ;

-- 2-How many days has each customer visited the restaurant?

SELECT
    customer_id ,
    COUNT(DISTINCT order_date) AS visited_days
FROM sales
GROUP BY 1;

-- 3-What was the first item from the menu purchased by each customer?


WITH result AS
(
SELECT 
     s.customer_id ,
     s.order_date ,
     m.product_name ,
     RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC ) AS num_purchase
FROM sales s 
LEFT JOIN 
menu m 
ON 
s.product_id = m.product_id
)
SELECT 
    DISTINCT customer_id ,
     order_date ,
     product_name
FROM result 
WHERE num_purchase = 1 ; 

-- 4-What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
     m.product_name ,
     COUNT(s.product_id) AS num_purchased
 FROM menu m
 JOIN 
 sales s 
 ON 
 m.product_id = s.product_id
 GROUP BY 1 
 ORDER BY 2 DESC
 LIMIT 1;
     
-- 5-Which item was the most popular for each customer?

WITH semi_result AS
(
SELECT s.customer_id , m.product_name , COUNT(s.order_date) AS num_purchase
FROM sales s 
JOIN 
menu m 
on 
s.product_id = m.product_id 
GROUP BY 1,2
) ,
 result as
 (
SELECT
       * ,
       RANK() OVER (PARTITION BY customer_id ORDER BY num_purchase desc) as num 
FROM semi_result 
)
SELECT customer_id , product_name FROM result
WHERE num = 1 ;

-- 6-Which item was purchased first by the customer after they became a member?

WITH result AS
(
SELECT s.customer_id ,
	s.order_date , 
    mem.join_date , 
    s.product_id,
    RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS ranks
FROM sales s
JOIN 
members mem 
ON
s.customer_id  = mem.customer_id
where s.order_date >= mem.join_date 
)
SELECT r.customer_id , m.product_name , r.order_date
FROM result r 
JOIN 
menu m 
on 
 r.product_id = m.product_id
WHERE ranks = 1
ORDER BY 1 ;

-- 7-Which item was purchased just before the customer became a member?


WITH result AS 
(
SELECT s.customer_id , s.order_date , mem.join_date , m.product_name ,
       RANK() OVER (PARTITION BY customer_id ORDER BY s.order_date DESC) as num 
FROM sales s
JOIN 
menu m
ON 
s.product_id = m.product_id 
JOIN 
members mem 
ON 
s.customer_id = mem.customer_id
where s.order_date < mem.join_date
)
SELECT customer_id , 
       product_name ,
       order_date
FROM result 
WHERE num = 1 ;





-- 8-What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id , COUNT(s.product_id) as total_items , SUM(m.price) total_amount
FROM sales s
JOIN 
menu m 
ON 
s.product_id = m.product_id
RIGHT JOIN 
members mem 
on 
s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date
GROUP BY 1 ;




-- 9-If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH result AS
(
SELECT s.customer_id , s.product_id , m.product_name , m.price ,
       CASE WHEN m.product_name = 'sushi' THEN m.price*2*10 ELSE m.price*10 END  AS points
FROM sales s
JOIN 
menu m 
ON 
s.product_id = m.product_id 
) 
SELECT
	   customer_id ,
       SUM(points) as total_points 
FROM result
GROUP BY 1 ;





-- 10-In the first week after a customer joins the program (including their join date) they earn 2x points on all items,not just sushi - how many points do customer A and B have at the end of January?
 
WITH result as 
(
SELECT s.customer_id , s.order_date , mem.join_date , m.product_name ,  m.price  ,
 CASE WHEN   m.product_name = 'sushi' THEN  m.price*2*10 
      WHEN   s.order_date >= mem.join_date AND  s.order_date < date_add(mem.join_date , interval 1 WEEK) THEN m.price*2*10
      ELSE m.price*10 END AS POINT
FROM sales s 
JOIN
menu m 
ON 
s.product_id = m.product_id 
JOIN 
members mem 
ON 
s.customer_id = mem.customer_id
where s.order_date <= '2021-01-31'
)
SELECT customer_id , SUM(POINT) as total_points 
FROM result 
GROUP BY 1
ORDER BY 1;


-- BONUS QUESTION 
-- Join All The Table - Recreate the table  : customer_id,order_date ,product_name,	price,member (Y/N)

SELECT s.customer_id , s.order_date , m.product_name , m.price , 
  case when mem.join_date is null then 'N'
       WHEN mem.join_date is not null AND s.order_date < mem.join_date THEN 'N'
       ELSE 'Y' END AS member 
FROM sales s
LEFT JOIN 
menu m 
on 
s.product_id = m.product_id
LEFT JOIN 
members mem 
on 
s.customer_id = mem.customer_id
order by 1 ;

-- Rank All The Things
-- Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking
-- for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.


WITH result AS 
(
SELECT s.customer_id , s.order_date , m.product_name , m.price , 
  case when mem.join_date is null then 'N'
       WHEN mem.join_date is not null AND s.order_date < mem.join_date THEN 'N'
       ELSE 'Y' END AS member 
FROM sales s
LEFT JOIN 
menu m 
on 
s.product_id = m.product_id
LEFT JOIN 
members mem 
on 
s.customer_id = mem.customer_id
order by 1
)
SELECT * , 
case when member = 'Y' THEN RANK() OVER (PARTITION BY customer_id ,member ORDER BY order_date) 
     ELSE NULL END AS ranking
FROM result ;
