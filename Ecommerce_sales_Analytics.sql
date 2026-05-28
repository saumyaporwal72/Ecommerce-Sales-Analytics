Create Database  if not exists Ecommerce_Sales_Analytics;
Show  databases;
use Ecommerce_Sales_analytics;

CREATE TABLE ecommerce_sales (
    ship_mode VARCHAR(50),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code INT,
    region VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(4,2),
    profit DECIMAL(10,2),
    profit_margin DECIMAL(10,2)
);

SHOW VARIABLES LIKE 'secure_file_priv';
SET GLOBAL local_infile = 1;


LOAD DATA INFILE 'Superstore_cleaned.csv'
INTO TABLE ecommerce_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select * from  ecommerce_sales;

-- 1. Total Sales, Profit, and Orders
select count(*) as total_orders,
round(sum(sales),2) as total_sales,
round(sum(profit),2) as total_profit
from ecommerce_sales;

-- 2. Top 10 Revenue-Generating Products (Sub-Categories)
select round(sum(sales),2) as Total_Revenue, Sub_Category
from ecommerce_sales
group by Sub_Category
order by Total_Revenue desc
limit 10;

-- 3. Loss-Making Categories
select round(sum(sales),2) as total_revenue , Category
from ecommerce_sales
group by Category
having total_revenue  < 0;

-- 4. Region-wise Sales Performance
select round(sum(sales),2) as Total_sales
, region
from ecommerce_sales
group by region
order by Total_sales desc;

-- 5. Average Profit Margin by Category
select round(avg(profit_margin),2) as average_profit_margin, Category
from ecommerce_sales
group by Category
order by average_profit_margin desc;

-- 6. Most Profitable States
select round(sum(sales),2) as Total_sales,
round(sum(profit),2) as Total_profit,
state
from ecommerce_sales
group by state
order by Total_profit desc;

-- 7. Top Customer Segment by Sales
select segment, round(sum(sales),2) as total_sales
from ecommerce_sales
group by segment
order by total_sales desc;


-- 8. Products with Highest Discounts
select sub_category , max(discount) as maximum_discount
from ecommerce_sales
group by sub_category
order by maximum_discount desc;

-- 9. Orders with Negative Profit
select city , category , sales, profit
from ecommerce_sales
where  profit <0
order by profit asc;

-- 10.average_sales_per_order
select round(avg(sales),2) as average_sales_per_order
from ecommerce_sales;


-- 11 Sub-Category Performance (with Loss Flag)
select sub_category,
sum(sales) as total_sales,
sum(profit) as total_profit,
case when sum(profit) < 0 then 'loss' else 'profit' end as loss_flag
from ecommerce_sales
group by sub_category
order by total_profit desc;


-- 12. Discount Impact on Profit
select case when discount <0 then '0%- No Discount'
when discount <=0.10 then '1%-10%'
when discount <=0.20 then '11%-20%'
else '21%+' end as discount_band,
round(avg(profit_margin),2) as avg_margin,
count(*) as total_order
from ecommerce_sales
group by discount_band;

-- 13. Category-wise Quantity Sold
select category, sum(quantity) as total_quantity
from ecommerce_sales
group by category
order by total_quantity desc;

-- 14. Top 5 Cities by Revenue
select city, round(sum(sales),2) as total_revenue
from ecommerce_sales
group by city
order by total_revenue;

-- 14. High Discount but Low Profit Orders
select category, sub_category, sales, profit, discount
from ecommerce_sales where discount >0.5and profit <0;

-- 15 -- Window Function: Rank Products within Category
select category, sub_category, sum(profit) as total_profit, rank() over(partition by category  order by sum(profit) desc) as profit_rank
from ecommerce_sales
group by category, sub_category
order by profit_rank ;

-- 16.  Find Top 3 Most Profitable Products in Each Category
with ranked as(
select Category, sub_category, sum(profit) as total_profit, rank() over(partition by Category order by sum(profit) desc) as rnk
from ecommerce_sales
group by category , sub_category)
select * from ranked where rnk<=3;

-- 17.Identify Regions Contributing More Than Average Sales
select region, 
sum(sales) as total_sales
from ecommerce_sales
group by region
having sum(sales) > (select avg(avg_region) from (select sum(sales) as avg_region from ecommerce_sales
group by region) avg_table);

-- 18.Find Running Total of Sales
select category , sales, sum(sales) over(order by sales desc) as Running_total
from  ecommerce_sales;

-- 19.Find Second Highest Sales in Each Region
with ranked as (select region, sales, dense_rank() over(partition by region order by sales desc)as rnk
from ecommerce_sales
)
select * from ranked where rnk =2;

-- 20. Compare Average Sales Against Overall Average
select category, avg(sales)as aver_sales,
case when avg(sales) > (select avg(sales) from ecommerce_sales) then 'Above_Average'
else 'Below_Average' end as performance
from ecommerce_sales
group by category;

-- 21.Detect Outlier Orders Using Z-Score Logic
select sales, round((sales-(select avg(sales) from ecommerce_sales))/ (select stddev(sales) from ecommerce_sales),2) as z_score    
FROM ecommerce_sales;

-- 22.Find top-selling city inside each region.
select region, city , sum(sales) , rank() over(partition by region order by sum(sales) desc) as rnk
from ecommerce_sales
group by region , city;