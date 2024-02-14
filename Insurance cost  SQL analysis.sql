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

/* checking null values of insurance data */
/* Using Nested Query */
SELECT * FROM insurance
WHERE (select column_name
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='insurance')= NULL;

--Find the average age of individuals in the dataset.
SELECT round(avg(age),2) as Average_age FROM insurance;

--Calculate the total charges billed by health insurance.
SELECT sum(charges) as total_bill FROM insurance; 

--Count the number of smokers in the dataset.
SELECT count(smoker) as total_smoker FROM insurance
WHERE smoker='yes';

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
select sex,count(sex) from insurance
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