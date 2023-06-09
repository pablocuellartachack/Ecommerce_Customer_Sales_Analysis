SELECT *
FROM ecommerce_analysis_6.list_of_orders;

SELECT *
FROM ecommerce_analysis_6.order_details;

# Renaming columns for ease
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Sub-Category` sub_category VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Order ID` order_id VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Category` category VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Quantity` quantity VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Profit` profit VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.order_details CHANGE `Amount` sale_amount VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.list_of_orders CHANGE `Order Date` order_date VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.list_of_orders CHANGE `Order ID` order_id VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.list_of_orders CHANGE `CustomerName` customer_name VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.list_of_orders CHANGE `State` state VARCHAR(25);
ALTER TABLE ecommerce_analysis_6.list_of_orders CHANGE `City` city VARCHAR(25);


## Solving Mock Objective 1 ##

# Creating aggregate view of tables
CREATE VIEW combined_orders AS 
	SELECT od.order_id, od.sale_amount, od.profit, od.quantity, od.category, od.sub_category,
		   loo.order_date, loo.customer_name, loo.state, loo.city
	FROM order_details AS od
    INNER JOIN list_of_orders AS loo
    ON od.order_id = loo.order_id;

SELECT * 
FROM combined_orders;

# Segmenting customers into RFM (Recency, Frequency, Monetary Value) model for further analysis
CREATE VIEW customer_grouping AS
SELECT *,
CASE
	WHEN (R>=4 AND R<=5) AND (((F+M)/2)>=4 AND ((F+M)/2)<=5) THEN 'Champions!'
	WHEN (R>=2 AND R<=5) AND (((F+M)/2)>=3 AND ((F+M)/2)<=5) THEN 'Loyal Customers'
	WHEN (R>=3 AND R<=5) AND (((F+M)/2)>=1 AND ((F+M)/2)<=3) THEN 'Potential Loyalist'
	WHEN (R>=4 AND R<=5) AND (((F+M)/2)>=0 AND ((F+M)/2)<=1) THEN 'New Customers'
    WHEN (R>=3 AND R<=4) AND (((F+M)/2)>=0 AND ((F+M)/2)<=1) THEN 'Promising'
    WHEN (R>=2 AND R<=3) AND (((F+M)/2)>=2 AND ((F+M)/2)<=3) THEN 'Customers Needing Attention'
    WHEN (R>=2 AND R<=3) AND (((F+M)/2)>=0 AND ((F+M)/2)<=2) THEN 'About To Sleep'
	WHEN (R>=0 AND R<=2) AND (((F+M)/2)>=2 AND ((F+M)/2)<=5) THEN 'At Risk'
    WHEN (R>=0 AND R<=1) AND (((F+M)/2)>=4 AND ((F+M)/2)<=5) THEN 'Cant Lose Them'
    WHEN (R>=1 AND R<=2) AND (((F+M)/2)>=1 AND ((F+M)/2)<=2) THEN 'Hibernating'
    WHEN (R>=0 AND R<=2) AND (((F+M)/2)>=0 AND ((F+M)/2)<=2) THEN 'Lost'
		END AS customer_segmentation
FROM (
	SELECT
    MAX(STR_TO_DATE(order_date, '%d-%m-%y')) AS order_date,
    customer_name,
    DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%y'), MAX(STR_TO_DATE(order_date, '%d-%m-%y'))) AS recency,
    COUNT(DISTINCT order_id) AS frequency,
    SUM(sale_amount) AS monetary,
    NTILE(5) OVER (ORDER BY DATEDIFF(STR_TO_DATE('31-03-2019', '%d-%m-%y'), MAX(STR_TO_DATE(order_date, '%d-%m-%y'))) DESC) AS R,
    NTILE(5) OVER (ORDER BY COUNT(DISTINCT order_id) ASC) AS F,
    NTILE(5) OVER (ORDER BY SUM(sale_amount) ASC) AS M
    
	FROM combined_orders
	GROUP BY customer_name
    )rfm_table
GROUP BY customer_name;

SELECT *
FROM customer_grouping;

# Return the count & percentage of each segment
CREATE VIEW customer_segments AS
SELECT
	customer_segmentation,
    COUNT(DISTINCT customer_name) AS cnt_of_customers,
    ROUND(COUNT(DISTINCT customer_name) / (SELECT COUNT(*) FROM customer_grouping) *100,2) AS pct_of_customers
FROM customer_grouping
GROUP BY customer_segmentation
ORDER BY pct_of_customers DESC;

SELECT *
FROM customer_segments;

SELECT SUM(cnt_of_customers) AS distinct_customers
FROM customer_segments;

SELECT COUNT(DISTINCT(customer_name)) AS distinct_customers
FROM list_of_orders;


## Solving Mock Objective 2 ##

# Finding the count of orders, customers, cities, and states
CREATE VIEW summary_findings AS
SELECT COUNT(DISTINCT order_id) AS cnt_of_orders,
	   COUNT(DISTINCT customer_name) AS cnt_of_customers,
       COUNT(DISTINCT city) AS cnt_of_cities,
       COUNT(DISTINCT state) AS cnt_of_states
FROM combined_orders;

SELECT *
FROM summary_findings;


## Solving Mock Objective 3 ##

# Finding information on the top 5 customers in 2019 
# (Found out there's a difference between Y and y!)
CREATE VIEW top_customers_2019 AS
SELECT customer_name, state, city, SUM(sale_amount) AS sales
FROM combined_orders
WHERE YEAR(STR_TO_DATE(order_date, "%d-%m-%Y"))='2019'
GROUP BY customer_name, state, city
ORDER BY sales DESC
LIMIT 5;

SELECT *
FROM top_customers_2019;


## Solving Mock Objective 4 ##

# Finding the top 10 profitable states and cities count of customers, profits, and quantities sold
CREATE VIEW top_10_profitable_locations AS
SELECT state, city, COUNT(DISTINCT customer_name) AS cnt_of_customers, 
	   SUM(profit) AS total_profit, SUM(quantity) AS total_quantity
FROM combined_orders
GROUP BY state, city
ORDER BY total_profit DESC
LIMIT 10;

SELECT *
FROM top_10_profitable_locations;


## Solving Mock Objective 5 ##

# Creating a basic histogram of orders and sales for different days
CREATE VIEW avg_sales_per_day AS
SELECT order_day, LPAD('*', avg(cnt_of_orders), '*') AS cnt_of_orders, sales
FROM (
	SELECT DAYNAME(STR_TO_DATE(order_date, '%d-%m-%Y')) AS order_day,
        COUNT(DISTINCT order_id) AS cnt_of_orders,
        SUM(quantity) AS quantity,
        SUM(sale_amount) AS sales
    FROM combined_orders
    GROUP BY DAYNAME(STR_TO_DATE(order_date, '%d-%m-%Y'))
) sales_per_day
GROUP BY order_day, sales
ORDER BY sales DESC;

SELECT *
FROM avg_sales_per_day;


## Solving Mock Objective 6 ##

# Trying to find patterns amongst monthly profits and monthly quantity sold
CREATE VIEW monthly_sales_patterns AS 
SELECT CONCAT(MONTHNAME(STR_TO_DATE(order_date, '%d-%m-%Y')), "-", 
	YEAR(STR_TO_DATE(order_date, '%d-%m-%Y'))) AS month_of_year, 
    SUM(profit) AS total_profit, 
    SUM(quantity) AS total_quantity
FROM combined_orders
GROUP BY month_of_year
ORDER BY month_of_year ='April-2018'DESC,
		 month_of_year ='May-2018'DESC,
		 month_of_year ='June-2018'DESC,
         month_of_year ='July-2018'DESC,
         month_of_year ='August-2018'DESC,
         month_of_year ='September-2018'DESC,
         month_of_year ='October-2018'DESC,
         month_of_year ='November-2018'DESC,
         month_of_year ='December-2018'DESC,
         month_of_year ='January-2019'DESC,
         month_of_year ='Febraury-2019'DESC,
         month_of_year ='March-2019'DESC;

SELECT *
FROM monthly_sales_patterns;


## Solving Mock Objective 7 ##

# Finding total sales, profits, and quantity sold for each category and sub-category
CREATE VIEW order_details_by_totals AS
SELECT category, sub_category,
	SUM(quantity) AS total_quantity,
    SUM(profit) AS total_profit,
    SUM(sale_amount) AS total_sales
FROM order_details
GROUP BY sub_category, category
ORDER BY total_quantity DESC;

SELECT *
FROM order_details_by_totals;

# Finding the avg and max cost and sale price per unit for each subcategory
CREATE VIEW order_details_by_units AS
SELECT category, sub_category,
    FORMAT(AVG(cost_per_unit),2) AS avg_cost,
    FORMAT(AVG(price_per_unit),2) AS avg_price,
    MAX(cost_per_unit) AS max_cost,
    MAX(price_per_unit) AS max_price
FROM (
	SELECT *,
    round((sale_amount-profit)/quantity,2) AS cost_per_unit,
    round(sale_amount/quantity,2) AS price_per_unit
    FROM order_details) order_details_by_units
GROUP BY sub_category, category
ORDER BY max_cost DESC;

SELECT *
FROM order_details_by_units;

# Combining the order_details_by_unit and order_details_by_totals for further analysis
CREATE VIEW aggregate_order_details AS 
SELECT odt.category, odt.sub_category, odt.total_quantity, odt.total_profit, odt.total_sales,
	   odu.avg_cost, odu.avg_price, odu.max_cost, odu.max_price
FROM order_details_by_totals AS odt
INNER JOIN order_details_by_units AS odu
ON odt.sub_category = odu.sub_category;

SELECT *
FROM aggregate_order_details;



