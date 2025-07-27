-- Database Exploration

-- explore all objects in the database
select * from INFORMATION_SCHEMA.TABLES

-- explore all columns in the database
select * from INFORMATION_SCHEMA.COLUMNS
where table_name = 'dim_customers'

-- dimensions exploration
-- identifying the unique values (or categories) in each dimension
-- recognizing how data might be grouped or segmented, which is useful for later analyses

select
	distinct country 
from
	gold.dim_customers

-- explore all categories "the major divisions"
select distinct category, subcategory, product_name from gold.dim_products
order by 1,2,3

-- date exploration
--identify the earliest and latest dates (boundaries)
-- understand the scope of data and the timespan
-- find the data of the first and last order
select
	min(order_date) as first_order_date,
	max(order_date) as last_order_date,
	DATEDIFF(MONTH, min(order_date), max(order_date)) as order_range_months
from gold.fact_sales

-- find the youngest and the oldest customer
select
	min(birthdate) as oldest_birthdate,
	DATEDIFF(YEAR, min(birthdate), getdate()) as oldest_age,
	DATEDIFF(YEAR, max(birthdate), getdate()) as youngest_age,
	max(birthdate) as youngest_birthdate
from
	gold.dim_customers

	-- Measures Exploration
	-- calculate the key metric of the busniness (big numbers)
	-- highest level of aggregation | lowest level of details
	-- Total de vendas (valor monetário)
	select sum(sales_amount) as total_sales from gold.fact_sales
	-- Quantidade total de itens vendidos
	select sum(quantity) as total_quantity from gold.fact_sales
	-- Preço médio de venda
		select avg(price) as avg_price from gold.fact_sales
	-- Número total de pedidos realizados
	select count(order_number) as total_orders from gold.fact_sales
	select count(distinct order_number) as total_orders from gold.fact_sales
	-- Número total de produtos cadastrados
	select count(product_key) as total_products from gold.dim_products
	-- Número total de clientes
	select count(customer_key) as total_customers from gold.dim_customers
	-- Número total de clientes que realizaram ao menos um pedido
	select count(distinct customer_key) as total_customers from gold.fact_sales



	-- generate report that shows all key metrics of the business

	select 'total sales' as measure_name, sum(sales_amount) as measure_value from gold.fact_sales
	union all
	select 'total quantity', sum(quantity) as measure_value from gold.fact_sales
	union all
	select 'average price', avg(price) as avg_price from gold.fact_sales
	union all
	select 'total Nr. Orders', count(distinct order_number) from gold.fact_sales
	union all
	select 'total Nr. Products', count(product_name) from gold.dim_products
	union all 
	select 'total Nr. Customers', count(customer_key) from gold.dim_customers

	-- Magnitude Analysis
	-- Compare the measure values by categories

-- Quantidade total de clientes por país
select
	country,
	count(customer_key) as total_customers
	from
		gold.dim_customers
	group by country
	order by total_customers desc
-- Quantidade total de clientes por gênero
select
	gender,
	count(customer_key) as total_customers
	from
		gold.dim_customers
	group by gender
	order by total_customers desc
-- Quantidade total de produtos por categoria
select
	category,
	count(product_key) as total_customers
	from
		gold.dim_products
	group by category
	order by total_customers desc
-- Qual é o custo médio em cada categoria?
select
	category,
	AVG(cost) as avg_costs
from
	gold.dim_products
group by category
order by avg_costs desc
-- Qual é o faturamento total gerado por cada categoria?
select
	p.category,
	sum(f.sales_amount) total_revenue
from
	gold.fact_sales f
left join gold.dim_products p on p.product_key = f.product_key
group by p.category
order by total_revenue desc
-- Qual é o faturamento total gerado por cada cliente?
select
	c.customer_key,
	c.first_name,
	c.last_name,
	sum(f.sales_amount) total_revenue
from
	gold.fact_sales f
left join gold.dim_customers c on c.customer_key = f.customer_key
group by c.customer_key, 
		 c.first_name,
		 c.last_name
order by total_revenue desc
-- Como os itens vendidos estão distribuídos entre os países?
select
	c.country,
	sum(f.quantity) as total_sold_items
from
	gold.fact_sales f
left join gold.dim_customers c on c.customer_key = f.customer_key
group by c.country
order by total_sold_items desc


-- Ranking Analysis
-- Top N performers | Bottom N Performers
-- Rank countries by total sales
-- Top 5 Products By Quantity
-- Bottom 3 customers by total orders 

-- What 5 products generate the highest revenue ? 
select *
	from (
	select
	p.product_name,
	sum(f.sales_amount) total_revenue,
	ROW_NUMBER() over(order by sum(f.sales_amount) desc) as rank_products
from
	gold.fact_sales f
left join gold.dim_products p on f.product_key = p.product_key
group by p.product_name)t
where rank_products <=5
-- What are the 5 worst-performing products in terms of sales ?
select *
from (
	select
	p.product_name,
	sum(f.sales_amount) total_revenue,
	ROW_NUMBER() over(order by sum(f.sales_amount) asc) as rank_products
from
	gold.fact_sales f
left join gold.dim_products p on f.product_key = p.product_key
group by p.product_name)t
where rank_products <= 5

-- find the top-10 customers who have generated the highest revenue and 3 customers with the fewest orders placed

select top 10
c.customer_key,
c.first_name,
c.last_name,
sum(f.sales_amount) as total_revenue
from	
	gold.fact_sales f
left join gold.dim_customers c on f.customer_key = c.customer_key
group by c.customer_key,
c.first_name,
c.last_name
order by total_revenue desc

-- the 3 customers with the fewest orders placed
select top 3
c.customer_key,
c.first_name,
c.last_name,
count(distinct order_number) as total_orders
from	
	gold.fact_sales f
left join gold.dim_customers c on f.customer_key = c.customer_key
group by c.customer_key,
c.first_name,
c.last_name
order by total_orders asc