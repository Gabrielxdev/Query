-- CHANGE OVER TIME - TRENDS

-- Analisar como uma métrica evolui ao longo do tempo
-- Rastrear as tendências e também para identificar a sazonalidade do dados.
-- Agregar uma métrica
-- Total sales by a year 
-- Average cost by month 
-- Analisar a performance ao longo do tempo 
-- Change over months, detailed insight to discover seasonality in your data

select
	year(order_date) as order_year,
	month(order_date) as order_month,
	sum(sales_amount) as total_sales,
	count(distinct customer_key) as total_customers,
	sum(quantity) as total_quantity
from
	gold.fact_sales
where order_date is not null
group by year(order_date), month(order_date)
order by year(order_date), month(order_date)

--  Cumulative Analysis
-- agregar os dados progressivamente ao longo do tempo
-- Entender como o negócio está crescendo ao longo do tempo 
-- analisar total acumulado de vendas ao longo do tempo e média movel de vendas por mês 
select
	order_date,
	total_sales,
	sum(total_sales) over (  order by order_date) as running_total_sales,
	avg(avg_price) over ( order by order_date) as momving_average_price

from
(
select
	datetrunc(month, order_date) as order_date,
	sum(sales_amount) as total_sales,
	AVG(price) as avg_price
from
	gold.fact_sales
where order_date is not null
group by DATETRUNC(month, order_date)) t


-- Performance Analysis 
-- comparar o valor atual com o valor-alvo para comparar o desempenho
-- analyze the yarly performance of products by comparing each product's sales to both its average sales performance and the previous year's sales

with yearly_product_sales as (
select
	year(f.order_date) as order_year,
	p.product_name,
	sum(f.sales_amount) as current_sales
from
	gold.fact_sales f
left join gold.dim_products p 
on f.product_key = p.product_key
where order_date is not null
group by year(f.order_date), p.product_name
)

select
	order_year,
	product_name,
	current_sales,
	AVG(current_sales) over (partition by product_name) avg_sales,
	current_sales - avg(current_sales) over (partition by product_name) as diff_avg,
	case when current_sales - avg(current_sales) over (partition by product_name) > 0 then 'Above avg'
		 when current_sales - avg(current_sales) over (partition by product_name) < 0 then 'below avg'
		 else 'avg'
	end avg_change,
	-- yoy analysis
	LAG(current_sales) over (partition by product_name order by order_year) py_sales,
	current_sales - lag(current_sales) over (partition by product_name order by order_year) as diff_py,
	case when current_sales - lag(current_sales) over (partition by product_name order by order_year) > 0 then 'Increase'
		 when current_sales - lag(current_sales) over (partition by product_name order by order_year) < 0 then 'Decrease'
		 else 'No Change'
	end py_change
from
	yearly_product_sales
order by product_name,order_year

-- Comparar o valor atual com outro valor em nossos conjuntos de dados
-- Quais categorias contribuem mais com as vendas no geral ?

with category_sales as (
select
	category,
	sum(sales_amount) total_sales
from
	gold.fact_sales f
left join gold.dim_products p  on p.product_key = f.product_key
group by category)

select
	category,
	total_sales,
	sum(total_sales) over() overall_sales,
	concat(round((cast(total_sales as float) /sum(total_sales) over())*100, 2), '%') as percentage_of_total
from
	category_sales
order by total_sales DESC

-- segmentações usando o SQL
-- segmentar produtos em faixas de custo e contar quantos produtos se enquadram em cada segmento

with product_segments as (
select
	product_key,
	product_name,
	cost,
	case	
		when cost < 100 then 'Below 100'
		when cost between 100 and 500 then '100-500'
		when cost between 500 and 1000 then '500-1000'
		else 'Above 1000'
		end cost_range
from
	gold.dim_products)

select
	cost_range,
	count(product_key) as total_products
from
	product_segments
group by cost_range

-- Advanced Task
/*Group customers into three segments based on their spending behavior:
	- VIP: Customers with at least 12 months of history and spending more than 5,000 euros.
	-Regular: Customers with as least 12 months of history but spending 5,000 or less.
	-New: Customers with a lifespan less than 12 months and find the total number of customers by each group
 */

 with customer_spending as (
 select
	c.customer_key,
	sum(f.sales_amount) as total_spending,
	min(order_date) as first_order,
	max(order_date) as last_order,
	datediff(month, min(order_date), max(order_date)) as lifespan
from
	gold.fact_sales f
left join gold.dim_customers c on f.customer_key = c.customer_key
group by c.customer_key
)

select
	customer_segment,
	count(customer_key) as total_customers
from
 (
	select
		customer_key,
	case 
		when lifespan >= 12 and total_spending > 5000 then 'VIP'
		when lifespan >= 12 and total_spending <= 5000 then 'Regular'
		else 'New'
		end customer_segment
from
	customer_spending) t
group by customer_segment
order by count(customer_key) desc


-- Build Customer Report
/*Customer Report

Purpose:

* This report summarizes key metrics and customer behaviors.

Highlights:

1. Collects critical customer information including names, ages, and transaction history.
2. Categorizes customers into segments such as VIP, Regular, New, and by age groups.
3. Aggregates important customer metrics, including:

   * Total number of orders
   * Total sales amount
   * Total quantity of items purchased
   * Total distinct products purchased
   * Customer lifespan (measured in months)
4. Provides insightful KPIs:

   * Recency (time elapsed since last purchase, in months)
   * Average value per order
   * Average monthly spending
*/

create view gold.report_customer as
with base_query as (
-- Base query: retrieves core columns from tables
select
	f.order_number,
	f.product_key,
	f.order_date,
	f.sales_amount,
	f.quantity,
	c.customer_key,
	c.customer_number,
	CONCAT(c.first_name, ' ', c.last_name) as customer_name,
	DATEDIFF(year, c.birthdate, GETDATE()) age
from
	gold.fact_sales f
left join gold.dim_customers c
on c.customer_key = f.customer_key
where order_date is not null
),
customer_aggregation as (
-- customer aggregation: summarizes key metrics at the customer level
select
	customer_key,
	customer_number,
	customer_name,
	age,
	count(distinct order_number) as total_orders,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	count(distinct product_key) as total_products,
	max(order_date) as last_order_date,
	DATEDIFF(month, min(order_date), max(order_date)) as lifespan
from
	base_query
group by 
	    customer_key,
		customer_number,
		customer_name,
		age)

select
	customer_key,
	customer_number,
	customer_name,
	age, 
	case 
		when age < 20 then  'Under 20'
		when age between 20 and 29 then '20-29'
		when age between 30 and 39 then '30-39'
		when age between 40 and 49 then '40-49'
		else '50 or Above'
		end age_group,
	case 
		when lifespan >= 12 and total_sales > 5000 then 'VIP'
		when lifespan >= 12 and total_sales <= 5000 then 'Regular'
		else 'New'
		end customer_segment,
	total_orders,
	total_sales,
	total_quantity,
	total_products,
	last_order_date,
	lifespan,
	--Compuate average order value (AVO)
	case when total_sales = 0 then 0
	else total_sales /total_orders
	end as avg_order_value,
	-- Compuate average monthly spend
	case when lifespan = 0 then total_sales
		else total_sales / lifespan
	end as avg_monthly_spend
from
	customer_aggregation


select * from gold.report_customer

/*Product Report

Purpose:

* This report consolidates key metrics and behaviors related to products.

Highlights:

1. Collects essential information, including product name, category, subcategory, and cost.
2. Segments products based on revenue to classify them as High-Performers, Mid-Range, or Low-Performers.
3. Summarizes key metrics at the product level:

   * Total number of orders
   * Total sales revenue
   * Total quantity sold
   * Number of unique customers
   * Product lifespan (in months)
4. Calculates critical KPIs:

   * Recency (months since last sale)
   * Average Order Revenue (AOR)
   * Average Monthly Revenue
*/

-- 1. base query: retrieves core columns from fact_sales and dim_products
create view gold.report_products as
with base_query_two as (
select
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category,
	p.subcategory,
	p.cost
from
	gold.fact_sales f
left join gold.dim_products p on f.product_key = p.product_key
where order_date is not null -- only consider valid sales dates
),
-- 2. Product aggregations: summarizes key metrics at the product level 
product_aggregations as (
select
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	datediff(month, min(order_date), max(order_date)) as lifespan, 
	max(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as total_customers,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	round(avg(cast(sales_amount as float) / nullif(quantity, 0)),1) as avg_selling_price
from
	base_query_two
group by 
	product_key,
	product_name,
	category,
	subcategory,
	cost
)

-- 3) Final query: Combines all product results into one output
select
	product_key,
	product_name,
	category,
	subcategory,
	cost,
	last_sale_date,
	DATEDIFF(month, last_sale_date, GETDATE()) as recency_in_months,
	case
		when total_sales > 5000 then 'High-Performer'
		when total_sales > 1000 then 'Mid-Range'
		else 'Low-Perfomrer'
	end as product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	-- Average Order Revenue 
	case	
		when total_orders = 0 then 0
		else total_sales / total_orders
	end as avg_order_revenue,
	-- Average Monthly Revenue
	case	
		when lifespan = 0 then total_sales
		else total_sales / lifespan
	end as avg_monthly_revenue
from
	product_aggregations

select
	*
from
	gold.report_products


	select
		*
	from
		gold.report_customer 


	select
		*
	from
		gold.report_customer