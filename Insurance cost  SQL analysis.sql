CREATE TABLE insurance (
    age INT,
    sex VARCHAR(10),
    bmi FLOAT,
    children INT,
    smoker VARCHAR(5),
    region VARCHAR(20),
    charges FLOAT
);


--Selecting Every Column
SELECT * FROM insurance;

/*DATASET  INFORMATION
age: age of primary beneficiary
sex: insurance contractor gender, female, male
bmi: Body mass index, providing an understanding of body, weights that are relatively high or low relative to height,objective index of body weight (kg / m ^ 2) using the ratio of height to weight, ideally 18.5 to 24.9
children: Number of children covered by health insurance / Number of dependents
smoker: Smoking
region: the beneficiary's residential area in the US, northeast, southeast, southwest, northwest.
charges: Individual medical costs billed by health insurance */


-- Database Size
SELECT pg_size_pretty(pg_database_size('project'));

-- Table Size
SELECT pg_size_pretty(pg_relation_size('insurance'));


/***Count the number of records in the insurance table. */
SELECT COUNT(*) as Row_Count
FROM insurance

/* column count of data */
SELECT COUNT(*) as column_Count
from information_schema.columns
where table_name = 'insurance';

/* Check Dataset Information */
SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
where table_name = 'insurance'

/*  get column names of insurance data */
SELECT COUNT(*) column_name
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='insurance'

--Find the average age of individuals in the dataset.
SELECT round(avg(age),2) as Average_age FROM insurance;

--Calculate the total charges billed by health insurance.
SELECT sum(charges) as total_bill FROM insurance; 

--Count the number of smokers in the dataset.
SELECT count(smoker) as total_smoker FROM insurance;

--Find the highest BMI in the dataset.
SELECT max(bmi) FROM insurance;

--Find the region with the highest average BMI
SELECT region,AVG(bmi) AS average_bmi
FROM insurance
GROUP BY region
ORDER BY average_bmi DESC
LIMIT 1;

--Find the maximum bmi among each region.
select region, max(bmi)as Maximum_bmi from insurance
group by region;

--Calculate the average charges for smokers and non-smokers separately.
select distinct(smoker),avg(charges) OVER (PARTITION BY smoker) AS avg_smoker
from insurance;
--Alternative query
SELECT
    smoker,
    AVG(charges) AS average_charges
FROM
    insurance
GROUP BY
    smoker;
	
--Count the number of males and females in the dataset.
select count(sex) from insurance
group by sex;
	
--Calculate the average number of children for each region.
select region,avg(children)as avg_children from insurance
group by region;
	
--Find the top 5 records with the highest charges.
select * from insurance
order by charges desc
limit 5;

--Calculate the percentage of smokers in each region.
SELECT
    region,
    (COUNT(CASE WHEN smoker = 'yes' THEN 1 END)* 100.0  / COUNT(*)) AS percentage_smokers
FROM
    insurance
GROUP BY
    region;

--Find the age of the oldest individual in each region.
select region, max(age) from insurance
group by region;

--or
select region, max(age) over (partition by region) as max_age
from insurance;

--Calculate the average BMI for individuals with more than 2 children.
select avg(bmi) from insurance
where children>2;

--Find the region with the lowest average medical charges.
select region ,min(charges) from insurance
group by region
order by min(charges)
limit 1;

--Count the number of records where BMI is within the ideal range (18.5 to 24.9).
SELECT COUNT(*)
FROM insurance
WHERE bmi >= 18.5 AND bmi <= 24.9;

--Calculate the median charges for individuals in the southeast region.
WITH SoutheastCharges AS (
    SELECT charges, ROW_NUMBER() OVER (ORDER BY charges) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM insurance
    WHERE region = 'southeast'
)
SELECT
    AVG(charges) AS median_charges
FROM
    SoutheastCharges
WHERE
    row_num BETWEEN (total_rows + 1) / 2 AND (total_rows + 2) / 2;

--Find the top 10% of records with the highest charges.
WITH ChargePercentiles AS (
    SELECT
        charges,
        NTILE(10) OVER (ORDER BY charges DESC) AS percentile
    FROM
        insurance
)

SELECT
    charges
FROM
    ChargePercentiles
WHERE
    percentile = 1;

--Calculate the average age for individuals with BMI greater than 30.
select avg(age) from insurance
where bmi>30

--Identify individuals with the same age and calculate their average charges.
select age, avg(charges) from insurance
group by age
order by age;
--or
WITH SameAgeAvgCharges AS (
    SELECT
        age,
        AVG(charges) AS avg_charges
    FROM
        insurance
    GROUP BY
        age
    HAVING
        COUNT(*) > 1
)

SELECT
    age,
    avg_charges
FROM
    SameAgeAvgCharges
order by age;

--Find the region with the highest ratio of smokers to non-smokers.
WITH SmokerRatio AS (
    SELECT
        region,
        SUM(CASE WHEN smoker = 'yes' THEN 1 ELSE 0 END) AS smokers,
        SUM(CASE WHEN smoker = 'no' THEN 1 ELSE 0 END) AS non_smokers
    FROM
        insurance
    GROUP BY
        region
)

SELECT
    region,
    COALESCE(CAST(smokers AS DECIMAL) / NULLIF(non_smokers, 0), 0) AS smoker_ratio
FROM
    SmokerRatio
ORDER BY
    smoker_ratio DESC
LIMIT 1;

--Calculate the average charges between males and females.
SELECT
    'male' AS gender,
    AVG(charges) - AVG(CASE WHEN sex = 'male' THEN charges ELSE 0 END) AS charges_difference
FROM
    insurance

UNION ALL

SELECT
    'female' AS gender,
    AVG(charges) - AVG(CASE WHEN sex = 'female' THEN charges ELSE 0 END) AS charges_difference
FROM
    insurance;

---Charges difference between male and female
SELECT
    AVG(CASE WHEN sex = 'female' THEN charges ELSE 0 END) -
    AVG(CASE WHEN sex = 'male' THEN charges ELSE 0 END) AS charges_difference
FROM
    insurance
WHERE
    sex IN ('male', 'female');

--Find individuals with similar BMI values and calculate the difference in their charges.
SELECT
    t1.bmi AS bmi_1,
    t2.bmi AS bmi_2,
    AVG(t1.charges) AS avg_charges_1,
    AVG(t2.charges) AS avg_charges_2,
    ABS(AVG(t1.charges) - AVG(t2.charges)) AS charges_difference
FROM
    insurance t1
JOIN
    insurance t2 ON t1.bmi = t2.bmi
WHERE
    t1.charges != t2.charges and t1.bmi = t2.bmi
GROUP BY
    t1.bmi, t2.bmi
HAVING
    COUNT(*) > 1;

--Identify individuals with the same number of children and find their average charges.
SELECT
    children,
    AVG(charges) AS avg_charges
FROM
    insurance
GROUP BY
    children

ORDER BY 
	children



--Calculate the average BMI for individuals with charges above the 75th percentile.
WITH HighChargeBMI AS (
    SELECT
        bmi,
        charges
    FROM
        insurance
    WHERE
        charges > (SELECT PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY charges) FROM insurance)
)

SELECT
    AVG(bmi) AS avg_bmi
FROM
    HighChargeBMI;


--Find the region with the highest standard deviation in charges.
SELECT
    region,
    STDDEV(charges) AS charges_std_dev
FROM
    insurance
GROUP BY
    region
ORDER BY
    charges_std_dev DESC
LIMIT 1;

---Identify outliers in the charges column using the Z-score method.
WITH ChargeZScores AS (
    SELECT
        *,
        (charges - AVG(charges) OVER ()) / STDDEV(charges) OVER () AS z_score
    FROM
        insurance
)

SELECT
    *
FROM
    ChargeZScores
WHERE
    ABS(z_score) > 3
ORDER BY charges;

---Calculate the correlation between age and charges.
SELECT
    CORR(age, charges) AS correlation
FROM
    insurance;
---Find the average charges for individuals with BMI in the underweight range (BMI < 18.5).
SELECT
    AVG(charges) AS average_charges_underweight
FROM
    insurance
WHERE
    bmi < 18.5;
---Determine if there is a significant difference in charges between smokers and non-smokers using a statistical test.
WITH SmokerCharges AS (
    SELECT
        charges,
        CASE WHEN smoker = 'yes' THEN 1 ELSE 0 END AS smoker_indicator
    FROM
        insurance
)

SELECT
    smoker_indicator,
    AVG(charges) AS avg_charges,
    COUNT(*) AS sample_size
FROM
    SmokerCharges
GROUP BY
    smoker_indicator;





















































/* get column names with data type of store data */
select column_name,data_type
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='store'


/* checking null values of insurance data */
/* Using Nested Query */
SELECT * FROM insurance
WHERE (select column_name
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='insurance')= NULL;
/* No Missing Values Found */


/* Check the count of United States */
select count(*) AS US_Count 
from store 
where country = 'United States'
/* This row isn't important for modeling purposes, but important for auto-generating latitude and longitude on Tableau. So, We won't drop it.*/

/* PRODUCT LEVEL ANALYSIS*/
/* What are the unique product categories? */
select distinct (Category) from store

/* What is the number of products in each category? */
SELECT Category, count(*) AS No_of_Products
FROM store
GROUP BY Category
order by  count(*) desc
--Same result using subquery
SELECT Category, COUNT(*) AS No_of_Products
FROM store
GROUP BY Category
ORDER BY (SELECT COUNT(*) FROM store WHERE Category = store.Category) DESC;


/* Find the number of Subcategories products that are divided. */
select count(distinct (Sub_Category)) As No_of_Sub_Categories
from store

/* Find the number of products in each sub-category. */
SELECT Sub_Category, count(*) As No_of_products
FROM store
GROUP BY Sub_Category
order by  count(*) desc
-- same query using subquery
SELECT Sub_Category, COUNT(*) AS No_of_Products
FROM store
GROUP BY Sub_Category
ORDER BY (SELECT COUNT(*) FROM store WHERE Sub_Category = store.Sub_Category) DESC;
/* Find the number of unique product names. */
select count(distinct (Product_Name)) As No_of_unique_products
from store

/* Which are the Top 10 Products that are ordered frequently? */
SELECT Product_Name, count(*) AS No_of_products
FROM store
GROUP BY Product_Name
order by  count(*) desc
limit 10

/* Calculate the cost for each Order_ID with respective Product Name. */
select Order_Id,Product_Name,ROUND(CAST((sales-profit) AS NUMERIC), 2)as cost
from store

/* Calculate % profit for each Order_ID with respective Product Name. */
select Order_Id,Product_Name,ROUND(CAST((profit/((sales-profit))*100)AS NUMERIC),2) as percentage_profit 
from store

/* Calculate the overall profit of the store. */
select ROUND(CAST(((SUM(profit)/((sum(sales)-sum(profit))))*100)AS NUMERIC),2) as percentage_profit 
from store

/* Calculate percentage profit and group by them with Product Name and Order_Id. */
/* Introducing method using WITH */
WITH store_new as(
select a.*,b.percentage_profit
from store as a
left join
(select ((profit/((sales-profit))*100)) as percentage_profit,order_id,Product_Name from store
group by percentage_profit,Product_Name,order_id) as b
on a.order_id=b.order_id)
select * from store_new

/* Same Thing Using normal method without creating any temporary data. Here, This can be only viewed for one time and we can't merge with the current dataset in this process.*/
select  order_id,Product_Name,((profit/((sales-profit))*100)) as percentage_profit
from store
group by order_id,Product_Name,percentage_profit

/* Where can we trim some loses? 
   In Which products?
   We can do this by calculating the average sales and profits, and comparing the values to that average.
   If the sales or profits are below average, then they are not best sellers and 
   can be analyzed deeper to see if its worth selling thema anymore. */

SELECT round(cast(AVG(sales) as numeric),2) AS avg_sales
FROM store;
-- the average sales on any given product is 229.8, so approx. 230.

SELECT round(cast(AVG(Profit)as numeric),2) AS avg_profit
FROM store;
-- the average profit on any given product is 28.6, or approx 29.


-- Average sales per sub-cat
SELECT round(cast(AVG(sales) as numeric),2) AS avg_sales, Sub_Category
FROM store
GROUP BY Sub_Category
ORDER BY avg_sales asc
limit 9;
--The sales of these Sub_category products are below the average sales.

-- Average profit per sub-cat
SELECT round(cast(AVG(Profit)as numeric),2) AS avg_prof,Sub_Category
FROM store
GROUP BY Sub_Category
ORDER BY avg_prof asc
limit 11;
--The profit of these Sub_category products are below the average profit.
-- "Minus sign" Respresnts that those products are in losses.

/* CUSTOMER LEVEL ANALYSIS*/
/* What is the number of unique customer IDs? */
select count(distinct (Customer_id)) as no_of_unique_custd_ID
from store

/* Find those customers who registered during 2014-2016. */
select distinct (Customer_Name), Customer_ID, Order_ID,city, Postal_Code
from store
where Customer_Id is not null;

/* Calculate Total Frequency of each order id by each customer Name in descending order. */
select order_id, customer_name, count(Order_Id) as total_order_id
from store
group by order_id,customer_name
order by total_order_id desc

/* Calculate  cost of each customer name. */
select order_id, customer_id, customer_Name, City, Quantity,sales,(sales-profit) as costs,profit
from store
group by Customer_Name,order_id,customer_id,City,Quantity,Costs,sales,profit;

/* Display No of Customers in each region in descending order. */
select Region, count(*) as No_of_Customers
from store
group by region
order by no_of_customers desc

/* Find Top 10 customers who order frequently. */
SELECT Customer_Name, count(*) as no_of_order
FROM store
GROUP BY Customer_Name
order by  count(*) desc
limit 10

 /* Display the records for customers who live in state California and Have postal code 90032. */
 select * from store
 where States= 'California' and Postal_Code='90032'

/* Find Top 20 Customers who benefitted the store.*/
SELECT Customer_Name, Profit, City, States
FROM store
GROUP BY Customer_Name,Profit,City,States
order by  Profit desc
limit 20

--Which state(s) is the superstore most succesful in? Least?
--Top 10 results:
SELECT round(cast(SUM(sales) as numeric),2) AS state_sales, States
FROM Store
GROUP BY States
ORDER BY state_sales DESC
OFFSET 1 ROWS FETCH NEXT 10 ROWS ONLY;

/* ORDER LEVEL ANALYSIS */
/* number of unique orders */
select count(distinct (Order_ID)) as no_of_unique_orders
from store

/* Find Sum Total Sales of Superstore. */
select round(cast(SUM(sales) as numeric),2) as Total_Sales
from store

/* Calculate the time taken for an order to ship and converting the no. of days in int format. */
select order_id,customer_id,customer_name,city,states, (ship_date-order_date) as delivery_duration
from store
order by delivery_duration desc
limit 20

/* Extract the year  for respective order ID and Customer ID with quantity. */
select order_id,customer_id,quantity,EXTRACT(YEAR from Order_Date) 
from store
group by order_id,customer_id,quantity,EXTRACT(YEAR from Order_Date) 
order by quantity desc


/* What is the Sales impact? */
SELECT EXTRACT(YEAR from Order_Date), Sales, round(cast(((profit/((sales-profit))*100))as numeric),2) as profit_percentage
FROM store
GROUP BY EXTRACT(YEAR from Order_Date), Sales, profit_percentage
order by  profit_percentage 
limit 20

--Breakdown by Top vs Worst Sellers:
-- Find Top 10 Categories (with the addition of best sub-category within the category).:
SELECT  Category, Sub_Category , round(cast(SUM(sales) as numeric),2) AS prod_sales
FROM store
GROUP BY Category,Sub_Category
ORDER BY prod_sales DESC;

--Find Top 10 Sub-Categories. :
SELECT round(cast(SUM(sales) as numeric),2) AS prod_sales,Sub_Category
FROM store
GROUP BY Sub_Category
ORDER BY prod_sales DESC
OFFSET 1 ROWS FETCH NEXT 10 ROWS ONLY;

--Find Worst 10 Categories.:
SELECT round(cast(SUM(sales) as numeric),2) AS prod_sales, Category, Sub_Category
FROM store
GROUP BY Category, Sub_Category
ORDER BY prod_sales;

-- Find Worst 10 Sub-Categories. :
SELECT round(cast(SUM(sales) as numeric),2) AS prod_sales, sub_Category
FROM store
GROUP BY Sub_Category
ORDER BY prod_sales
OFFSET 1 ROWS FETCH NEXT 10 ROWS ONLY;

/* Show the Basic Order information. */
select count(Order_ID) as Purchases,
round(cast(sum(Sales)as numeric),2) as Total_Sales,
round(cast(sum(((profit/((sales-profit))*100)))/ count(*)as numeric),2) as avg_percentage_profit,
min(Order_date) as first_purchase_date,
max(Order_date) as Latest_purchase_date,
count(distinct(Product_Name)) as Products_Purchased,
count(distinct(City)) as Location_count
from store

/* RETURN LEVEL ANALYSIS */
/* Find the number of returned orders. */
select Returned_items, count(Returned_items)as Returned_Items_Count
from store
group by Returned_items
Having Returned_items='Returned'

--Find Top 10 Returned Categories.:
SELECT Returned_items, Count(Returned_items) as no_of_returned ,Category, Sub_Category
FROM store
GROUP BY Returned_items,Category,Sub_Category
Having Returned_items='Returned'
ORDER BY count(Returned_items) DESC
limit 10;

-- Find Top 10  Returned Sub-Categories.:
SELECT Returned_items, Count(Returned_items),Sub_Category
FROM store
GROUP BY Returned_items, Sub_Category
Having Returned_items='Returned'
ORDER BY Count(Returned_items) DESC
OFFSET 1 ROWS FETCH NEXT 10 ROWS ONLY;

--Find Top 10 Customers Returned Frequently.:
SELECT Returned_items, Count(Returned_items) As Returned_Items_Count, Customer_Name, Customer_ID,Customer_duration, States,City
FROM store
GROUP BY Returned_items,Customer_Name, Customer_ID,customer_duration,states,city
Having Returned_items='Returned'
ORDER BY Count(Returned_items) DESC
limit 10;

-- Find Top 20 cities and states having higher return.
SELECT Returned_items, Count(Returned_items)as Returned_Items_Count,States,City
FROM store
GROUP BY Returned_items,states,city
Having Returned_items='Returned'
ORDER BY Count(Returned_items) DESC
limit 20;


--Check whether new customers are returning higher or not.
SELECT Returned_items, Count(Returned_items)as Returned_Items_Count,Customer_duration
FROM store
GROUP BY Returned_items,Customer_duration
Having Returned_items='Returned'
ORDER BY Count(Returned_items) DESC
limit 20;

--Find Top  Reasons for returning.
SELECT Returned_items, Count(Returned_items)as Returned_Items_Count,return_reason
FROM store
GROUP BY Returned_items,return_reason
Having Returned_items='Returned'
ORDER BY Count(Returned_items) DESC
















