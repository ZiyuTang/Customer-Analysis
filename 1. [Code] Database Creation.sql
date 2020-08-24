# Create database and tables

DROP   DATABASE IF EXISTS db_consumer_panel;
 CREATE DATABASE db_consumer_panel;
 USE    db_consumer_panel;
 
 CREATE TABLE Households(
hh_id                                                           BIGINT unsigned   NOT NULL,
hh_race                                                       INT unsigned NOT NULL,
hh_is_latinx                                                 INT unsigned NOT NULL,
hh_zip_code                                               INT unsigned NOT NULL,
#CHECK                                                      (hh_zip_code BETWEEN 10000 AND 99999),    
hh_state                                                     CHAR(2) NOT NULL,         
hh_income                                                  INT unsigned NOT NULL,
hh_size                                                       INT  unsigned NOT NULL,
hh_residence_type                                     INT  NOT NULL,                                            
PRIMARY KEY                                           (hh_id)                                                                             
);


CREATE TABLE Products(
brand_at_prod_id                                       VARCHAR(100) ,
department_at_prod_id                              VARCHAR(100) ,
prod_id                                                       VARCHAR(100) NOT NULL,
group_at_prod_id                                       VARCHAR(100),
module_at_prod_id                                    VARCHAR(100),
amount_at_prod_id                                    FLOAT,
units_at_prod_id                                        CHAR(10),   
PRIMARY KEY                                           (prod_id)
);


CREATE TABLE Trips(
hh_id                                                          BIGINT unsigned   NOT NULL,
TC_date                                                     DATETIME      NOT NULL,
TC_retailer_code                                       INT unsigned  NOT NULL,
TC_retailer_code_store_code                   INT unsigned  NOT NULL,
TC_retailer_code_store_zip3                    INT unsigned,
#CHECK                                                     (TC_retailer_code_store_zip3    BETWEEN 100 AND 999),      
TC_total_spent                                          FLOAT  NOT NULL,
TC_id                                                         BIGINT unsigned, 
PRIMARY KEY                                         (TC_id)
);


CREATE TABLE  Purchases(
TC_id                                                         BIGINT unsigned , 
quantity_at_TC_prod_id                            INT unsigned  NOT NULL,
total_price_paid_at_TC_prod_id               FLOAT  NOT NULL,
coupon_value_at_TC_prod_id                  FLOAT  NOT NULL,
deal_flag_at_TC_prod_id                          INT unsigned,    
prod_id                                                      VARCHAR(100) NOT NULL
);



ALTER TABLE    Trips                   ADD CONSTRAINT FK_hh_id                         FOREIGN KEY (hh_id)                  REFERENCES    Households(hh_id);
ALTER TABLE    Purchases          ADD CONSTRAINT FK_TC_id                        FOREIGN KEY (TC_id)                 REFERENCES    Trips(TC_id);
ALTER TABLE    Purchases          ADD CONSTRAINT FK_prod_id                      FOREIGN KEY (prod_id)              REFERENCES    Products(prod_id);



SELECT * FROM Households;
SELECT COUNT(*) FROM Households;
SELECT COUNT(distinct hh_id)  FROM Households;

SELECT * FROM Products;
SELECT count(*) FROM Products;
SELECT COUNT(distinct prod_id)  FROM Products;

SELECT * FROM Trips;

SELECT COUNT(*) FROM Trips;
SELECT COUNT(distinct TC_id)  FROM Trips;

SELECT * FROM Purchases;
SELECT COUNT(*) FROM Purchases;

 USE    db_consumer_panel;

# a.1. How many store shopping trips are recorded in your database?
# 7596145
SELECT COUNT(*) FROM Trips;
SELECT COUNT(TC_id) FROM Trips;

# a.2. How many households appear in your database?
# 39577
SELECT COUNT(DISTINCT hh_id) FROM Households;

# a.3. How many stores of different retailers appear in our data base?
# 26406
SELECT SUM(num_ret_store) FROM (SELECT TC_retailer_code, COUNT(DISTINCT TC_retailer_code_store_code) AS num_ret_store 
FROM Trips WHERE TC_retailer_code_store_code != "0"
GROUP BY TC_retailer_code) AS A;

# a.4. How many different products are recorded?
# 4231283
SELECT COUNT(DISTINCT prod_id)  FROM Products;

# a.4.i. How many products per category and products per module
# products per category: 118 rows returned
SELECT group_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_cat FROM Products WHERE group_at_prod_id IS NOT NULL GROUP BY group_at_prod_id; 

# products per module: 1224 rows returned
SELECT module_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_mod FROM Products WHERE module_at_prod_id IS NOT NULL GROUP BY module_at_prod_id;

#a.4.ii. Plot the distribution of products and modules per department
SELECT department_at_prod_id, COUNT(DISTINCT prod_id) AS num_pro_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

SELECT department_at_prod_id, COUNT(DISTINCT module_at_prod_id) AS num_mod_dep
FROM Products WHERE department_at_prod_id IS NOT NULL
GROUP BY department_at_prod_id;

# a.5.i. Total transactions and transactions realized under some kind of promotion.
# total transactions from table Trips: 7596145
# total transactions from table Purchases: 5651255
# transactions realized under some kind of promotion: 874873
SELECT COUNT(DISTINCT(TC_id))  FROM Trips;
SELECT COUNT(DISTINCT(TC_id)) FROM Purchases;
SELECT COUNT(DISTINCT(TC_id)) FROM Purchases WHERE coupon_value_at_TC_prod_id != "0";

 
 # b.1. How many households do not shop at least once on a 3 month periods.
 # 48
 
CREATE  TABLE hh_month
	SELECT DISTINCT(date_format(TC_date,'%Y-%m-%d')) AS date, hh_id  FROM Trips order by  hh_id;
SELECT * FROM hh_month;

ALTER TABLE hh_month
ADD COLUMN start_time DATETIME;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    start_time = '2003-12-27 00:00:00';

ALTER TABLE hh_month
ADD COLUMN end_time DATETIME;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    end_time = '2004-12-26 00:00:00';

WITH t1 AS
(SELECT DISTINCT  hh_id, (date_format(DATE,'%Y-%m-%d')) AS hh_date
FROM(
	SELECT hh_id,date FROM hh_month
	UNION ALL
	SELECT DISTINCT hh_id, start_time FROM hh_month
	UNION ALL
	SELECT DISTINCT hh_id, end_time FROM hh_month) AS t
    ORDER BY hh_id),
t2 AS
(SELECT *, ROW_NUMBER() OVER (ORDER BY hh_id) AS ID FROM t1),
t3 AS
(SELECT hh_id, hh_date, ID, 1 + ID AS ID_2 FROM  t2 ORDER BY hh_id)
SELECT DISTINCT (t3.hh_id), t3.hh_date, t2.hh_date, datediff(t2.hh_date,t3.hh_date) AS TIME_WINDOW_SIZE FROM t3 
LEFT JOIN  t2
ON t2.ID= t3.ID_2
WHERE datediff(t2.hh_date,t3.hh_date)>90;

# b.2 Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average) on single retailer? 

# households shop at least once a month
# 35962

SELECT DISTINCT(hh_id), purchase_times FROM
(SELECT hh_id, COUNT(DISTINCT (MONTH(TC_date))) AS purchase_times
FROM Trips
GROUP BY hh_id
ORDER BY hh_id) AS t
WHERE purchase_times=12;

# single retailer
# 124

CREATE TABLE single_loyalty
SELECT hh_ID,TC_retailer_code
FROM
(SELECT hh_ID,TC_retailer_code, COUNT(purchase_month) AS count_month
FROM 
(SELECT hh_id,TC_retailer_code,purchase_month
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, MONTH(TC_date) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C
WHERE spend_monthly_retailer>0.8*spend_monthly_average) AS D
GROUP BY hh_id,TC_retailer_code) AS E
WHERE count_month=12;
SELECT * FROM  single_loyalty;

#b.2.i. Are their demographics remarkably different? Are these people richer? Poorer?

# details of single loyalty
SELECT Households.* FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id;

# distribution between race
SELECT hh_race AS race,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY hh_race;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_is_latinx;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_size;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM
(SELECT Households.*  FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY  hh_residence_type;


#b.2.ii. What is the retailer that has more loyalists?
SELECT TC_retailer_code,COUNT(hh_id)  AS number
FROM single_loyalty
GROUP BY TC_retailer_code
ORDER BY COUNT(hh_id) DESC;        

#b.2.iii. Where do they live? Plot the distribution by state.

SELECT hh_state AS State, COUNT(*) AS number
FROM
(SELECT hh_state FROM
single_loyalty
LEFT JOIN
Households
ON single_loyalty.hh_id=Households.hh_id) AS T
GROUP BY hh_state;

#b.2.  Among the households who shop at least once a month, which % of them concentrate at least 80% of their grocery expenditure (on average)  among 2 retailers?
# 316

CREATE TABLE Loyalism_TOP_2
SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id,purchase_month ORDER BY spend_monthly_retailer DESC) AS ID
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, MONTH(TC_date) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,MONTH(TC_date) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C;
SELECT * FROM Loyalism_TOP_2;


CREATE TABLE Loyalism_TOP_2_new
SELECT * FROM Loyalism_TOP_2 WHERE ID=1 OR ID=2;
SELECT * FROM Loyalism_TOP_2_new;

WITH t2 AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id) AS rank_1
FROM Loyalism_TOP_2_new),
t3 AS
(SELECT hh_id, TC_retailer_code,spend_monthly_retailer,  rank_1-1 AS rank_2 FROM t2)
SELECT t3.hh_id,t2.purchase_month,t2.TC_retailer_code AS retailer_1, t3.TC_retailer_code AS retailer_2, t2.spend_monthly_retailer AS retailerz_spend_1,t3.spend_monthly_retailer AS retailerz_spend_2,t2.spend_monthly_average
FROM
t2
LEFT JOIN
t3
ON  t2.rank_1= t3.rank_2 AND t2.hh_id= t3.hh_id;


CREATE TABLE  Loyalism_TOP_2_CONCAT
WITH t2 AS
(SELECT *,
ROW_NUMBER() OVER (PARTITION BY hh_id) AS rank_1
FROM Loyalism_TOP_2_new),
t3 AS
(SELECT hh_id, TC_retailer_code,spend_monthly_retailer,  rank_1-1 AS rank_2 FROM t2)
SELECT t3.hh_id,t2.purchase_month,t2.TC_retailer_code AS retailer_1, t3.TC_retailer_code AS retailer_2, t2.spend_monthly_retailer AS retailerz_spend_1,t3.spend_monthly_retailer AS retailerz_spend_2,t2.spend_monthly_average
FROM
t2
LEFT JOIN
t3
ON  t2.rank_1= t3.rank_2 AND t2.hh_id= t3.hh_id;
SELECT * FROM  Loyalism_TOP_2_CONCAT;


CREATE TABLE  Loyalism_TOP_2_ODD
SELECT * FROM
(SELECT *, ROW_NUMBER() OVER() AS rowNumber 
FROM Loyalism_TOP_2_CONCAT) tb1
WHERE tb1.rowNumber % 2 = 1;
SELECT * FROM  Loyalism_TOP_2_ODD;

CREATE TABLE  Loyalism_TOP_2_main
SELECT * FROM Loyalism_TOP_2_ODD WHERE retailerz_spend_1+retailerz_spend_2>0.8*spend_monthly_average;
SELECT * FROM  Loyalism_TOP_2_main;

CREATE TABLE  Loyalism_TOP_2_household
SELECT *
FROM
((SELECT hh_id, purchase_month,retailer_1 AS retailer,retailerz_spend_1 AS retailer_spend,spend_monthly_average
FROM Loyalism_TOP_2_main) 
UNION
(SELECT hh_id, purchase_month,retailer_2 AS retailer,retailerz_spend_2 AS retailer_spend,spend_monthly_average
FROM Loyalism_TOP_2_main)) AS A
ORDER BY  hh_id, purchase_month;
SELECT * FROM  Loyalism_TOP_2_household;

# list of household meet the requirement of Loyalism of 2 retailers.
# 316

CREATE TABLE  Loyalism_TOP_2_household_list
SELECT DISTINCT(A.hh_id)
FROM
(SELECT hh_id
FROM
(SELECT hh_id,COUNT(DISTINCT(purchase_month)) AS count_month
FROM Loyalism_TOP_2_household
GROUP BY hh_id) AS T_1
WHERE count_month=12) AS A
LEFT JOIN
(SELECT hh_id
FROM(
SELECT hh_id,COUNT(DISTINCT(retailer)) AS count_retailer
FROM Loyalism_TOP_2_household
GROUP BY hh_id) AS T_2
WHERE count_retailer=2) AS B
ON A.hh_id=B.hh_id;
SELECT * FROM  Loyalism_TOP_2_household_list;

CREATE TABLE  Loyalism_single_household_list
SELECT hh_ID
FROM
(SELECT hh_ID,TC_retailer_code, COUNT(purchase_month) AS count_month
FROM 
(SELECT hh_id,TC_retailer_code,purchase_month
FROM
(SELECT A.*,B.spend_monthly_average
FROM 
(SELECT hh_id,TC_retailer_code, (MONTH(TC_date)) AS purchase_month,SUM(TC_total_spent) AS spend_monthly_retailer
FROM Trips
GROUP BY hh_id,TC_retailer_code,purchase_month
ORDER BY hh_id,purchase_month) AS A
LEFT JOIN
(SELECT hh_id,(MONTH(TC_date)) AS purchase_month, SUM(TC_total_spent) AS  spend_monthly_average
FROM Trips
GROUP BY hh_id,purchase_month
ORDER BY hh_id,purchase_month) AS B
ON A.hh_id=B.hh_id AND A.purchase_month=B.purchase_month) AS C
WHERE spend_monthly_retailer>0.8*spend_monthly_average) AS D
GROUP BY hh_id,TC_retailer_code) AS E
WHERE count_month=12;
SELECT * FROM  Loyalism_single_household_list;

# final list
CREATE TABLE Loyalism_TOP_2_household_list_final
SELECT DISTINCT(hh_id)
FROM
( SELECT * FROM Loyalism_single_household_list
UNION
SELECT * FROM Loyalism_TOP_2_household_list) AS A;
SELECT * FROM Loyalism_TOP_2_household_list_final;

#detailed information
SELECT Loyalism_TOP_2_household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id;

# detailed information about Top 2 loyalism
SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id;

#b.2.i. Are their demographics remarkably different? Are these people richer? Poorer?

# distribution between race
SELECT hh_race AS race,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_race
ORDER BY  number DESC;

# distribution between is_latinx
SELECT hh_is_latinx AS Latinx,COUNT(hh_id)  AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_is_latinx
ORDER BY number;

# distribution between size
SELECT hh_size AS Size,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_size
ORDER BY number DESC;

# distribution between income
SELECT hh_income AS Income,COUNT(hh_id) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_income
ORDER BY number DESC;

# No two family house ‐ condo residents are loyal consumers
# One family house ‐ condo residents just have 1
SELECT hh_residence_type AS Residence,COUNT(hh_id) 
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY  hh_residence_type;

#b.2.ii. What is the retailer that has more loyalists?
SELECT retailer,COUNT(DISTINCT(hh_id))  AS number
FROM
(SELECT Loyalism_TOP_2_household.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Loyalism_TOP_2_household
ON Loyalism_TOP_2_household.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY retailer
ORDER BY number DESC;

#b.2.iii. Where do they live? Plot the distribution by state.
SELECT hh_state AS State, COUNT(*) AS number
FROM
(SELECT Households.*
FROM 
Loyalism_TOP_2_household_list_final
LEFT JOIN
Households
ON Households.hh_id=Loyalism_TOP_2_household_list_final.hh_id) AS T
GROUP BY hh_state;

#b.3. Plot with the distribution:
#b.3.i. Average number of items purchased on a given month.
select month, avg(quantity)
	from(select  hh_id, month(TC_date) as month, sum(quantity_at_TC_prod_id) as quantity
		from Trips
			right join Purchases
				using(TC_id)
		group by hh_id, month
		order by hh_id) as t8_1
group by month
order by month;

#b.3.ii. Average number of shopping trips per month.
select month, round(avg(trips_amount),2) as avg_trips_amount
from (select hh_id, month(TC_date) as month, count(TC_id) as trips_amount
from Trips
group by hh_id, month
order by hh_id) as t8_2
group by month
order by month;

#b.3.iii. Average number of days between 2 consecutive shopping trips.
DROP TABLE IF EXISTS hh_month;
CREATE  TABLE hh_month
 SELECT date(TC_date) AS date, hh_id  FROM Trips order by  hh_id, date;

ALTER TABLE hh_month
ADD COLUMN start_time DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    start_time = '2003-12-27';

ALTER TABLE hh_month
ADD COLUMN end_time DATE;
SET SQL_SAFE_UPDATES = 0;
UPDATE hh_month
SET    end_time = '2004-12-26';

drop table if exists hh_month_plus;
create table hh_month_plus
	(select hh_id, date from hh_month)
	union
	(select distinct hh_id, start_time from hh_month)
	union
	(select distinct hh_id, end_time from hh_month)
	order by hh_id, date;

with t1 as
(select hh_id, date, row_number() over (order by hh_id, date) as index_original from hh_month_plus),
t2 as
(select hh_id, date, index_original + 1 as index_alt from hh_month_plus_1),
 t3 as
 (select t1.hh_id, t1.date as date_bf, t2.date as date_aft
      from t1
      inner join t2
       on index_original = index_alt
       and t1.hh_id = t2.hh_id
      order by t1.hh_id)
select hh_id, avg(datediff(date_bf,date_aft)) as avg_time_interval
 from t3
group by hh_id
order by hh_id;


#c.3.i. What are the product categories that have proven to be more “Private labelled”
SELECT department_at_prod_id, COUNT(brand_at_prod_id) AS num_priv_prod 
FROM (SELECT * FROM Products WHERE brand_at_prod_id = 'CTL BR') AS A 
WHERE department_at_prod_id IS NOT NULL 
GROUP BY department_at_prod_id
ORDER BY num_priv_prod DESC;

#c.3.ii. Is the expenditure share in Private Labeled products constant across months?
create table c_3_2
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, quantity_at_TC_prod_id as quantity from Purchases),
t2 as
(select brand_at_prod_id as brand, prod_id from Products where brand_at_prod_id = "CTL BR" ),
t3 as
(select TC_id, month(TC_date) as month from Trips),

t4 as 
(select month, quantity, prod_id 
	from t1
     inner join t3
     using(TC_id)),
     
-- CTL BR's total monthly quantity
t5 as 
(select month , sum(quantity) as quantity_BR
	from t4
	 inner join t2
     using(prod_id)
 group by month),
     
-- all products' total quantity
t6 as
(select month, sum(quantity) as quantity_total
	from t4
 group by month),
 t7 as 
 (select t5.month as month, quantity_BR, quantity_total
	from t5
    inner join t6
    using(month))

-- calculate ratio
select  month, quantity_BR/quantity_total as quantity_share
	from t7 
order by month;

select * from c_3_2;

select hh_id, TC_id, month(TC_date) as month , TC_total_spent from Trips;



#c.3.iii. Cluster households in three income groups, Low, Medium and High. Report the average monthly expenditure on grocery. Study the % of private label share in their monthly expenditures. Use visuals to represent the intuition you are suggesting.
create table c_3_31
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, total_price_paid_at_TC_prod_id as total_price_prod from Purchases),
t2 as
(select brand_at_prod_id as brand, prod_id from Products where brand_at_prod_id = "CTL BR" ),
t3 as
(select hh_id, TC_id, month(TC_date) as month , TC_total_spent from Trips),

-- cluster hh in 3 groups
t8 as
(select hh_id, hh_income, 1*(hh_income<=10)+2*(hh_income>10 and hh_income<=20)+3*(hh_income>20) as income_group
	from households),

t9 as
(select income_group, month, TC_id, TC_total_spent
	from t3
		inner join t8
        using(hh_id)),
        
-- monthly total expenditure
t10 as 
(select income_group, month, sum(TC_total_spent) as monthly_spent
	from t9
    group by income_group, month
    order by income_group, month),

-- only CTL BR
t11 as
(select TC_id, total_price_prod 
	from t1
    inner join t2
    using(prod_id)),
t12 as
(select income_group, month, sum(total_price_prod) as priv_spent
	from t11
		inner join t9
		using(TC_id)
 group by income_group, month
 order by income_group, month)
 select t12.income_group, t12.month, priv_spent/monthly_spent as prive_share
	from t12
		inner join t10
        on t12.income_group = t10.income_group
        and t12.month = t10.month
order by income_group, month;

select * from c_3_31;

drop table if exists c_3_32;
create table c_3_32
with 
-- basic processes with tables
t1 as
(select TC_id, prod_id, total_price_paid_at_TC_prod_id as price_prod from Purchases),
t2 as
(select prod_id from Products 
	where department_at_prod_id like '%GROCERY%'),
t3 as
(select hh_id, TC_id, month(TC_date) as month from Trips),

-- cluster hh in 3 groups
t8 as
(select hh_id, 1*(hh_income<=10)+2*(hh_income>10 and hh_income<=20)+3*(hh_income>20) as income_group from households),

t9 as
(select hh_id, income_group, month, TC_id
	from t3
		inner join t8
        using(hh_id)),

-- only groceries
t11 as
(select TC_id, price_prod 
	from t1
    inner join t2
    using(prod_id)),

-- distinct hh_id, and then income_group can stands for hh_id
t12 as
(select month, hh_id, income_group, sum(price_prod) as sum_price_prod
	from t11
		inner join t9
		using(TC_id)
 group by month,hh_id
 order by month,hh_id)
 
-- monthly spent on grocery products of each group
select month, income_group, avg(sum_price_prod) as groc_spent
	from t12
 group by month,income_group
 order by month,income_group;

 -- average monthly groceries purchased of each group
/*
select income_group,avg(groc_spent) as avg_groc_spent
	from t13
group by income_group
order by income_group;
*/

select * from c_3_32;





