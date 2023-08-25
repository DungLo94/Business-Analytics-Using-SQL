use mavenfuzzyfactory2;
-- 1. Sự tăng trưởng về mặt số lượng trong website
Select
	year(website_sessions.created_at) as yr,
	quarter(website_sessions.created_at) as qtr,
	count(website_sessions.website_session_id) as sessions,
	count(orders.order_id) as orders
from website_sessions
left join orders
on website_sessions.website_session_id=orders.website_session_id
group by 1,2 ;
-- 2. Hiệu quả hoạt động của công ty
Select
	year(website_sessions.created_at) as yr,
	quarter(website_sessions.created_at) as qtr,
	count(orders.order_id)/count(website_sessions.website_session_id) as session_to_order_conv_rate,
	sum(orders.price_usd)/count(orders.order_id) as revenue_per_order,
	sum(orders.price_usd)/count(website_sessions.website_session_id) as revenue_per_session
from website_sessions
left join orders
on website_sessions.website_session_id=orders.website_session_id
group by 1,2 ;
-- 3. Sự phát triển của các đối tượng khác nhau 
Create temporary table orders_development
select 
	year(website_sessions.created_at) as yr,
	quarter(website_sessions.created_at) as qtr,
	count(case when website_sessions.utm_source='gsearch' and website_sessions.utm_campaign ='nonbrand' then orders.order_id else null end) as gsearch_nonbrand_orders,
	count(case when website_sessions.utm_source='bsearch' and website_sessions.utm_campaign ='nonbrand' then orders.order_id else null end) as bsearch_nonbrand_orders,
	count(case when website_sessions.utm_campaign ='brand' then orders.order_id else null end) as brand_search_orders,
	count(case when website_sessions.utm_source is null and website_sessions.http_referer is not null then orders.order_id else null end) as organic_type_in_orders,
	count(case when website_sessions.utm_source is null and website_sessions.http_referer is null then orders.order_id else null end) as direct_type_in_orders
from website_sessions
inner join orders
on website_sessions.website_session_id=orders.website_session_id
group by 1,2 ;
-- 4. Tỷ lệ chuyển đổi phiên thành đơn đặt hàng
Create temporary table sessions_development
select 
	year(created_at) as yr,
	quarter(created_at) as qtr,
	count(case when utm_source='gsearch' and utm_campaign ='nonbrand' then website_session_id else null end) as gsearch_nonbrand_sessions,
	count(case when utm_source='bsearch' and utm_campaign ='nonbrand' then website_session_id else null end) as bsearch_nonbrand_sessions,
	count(case when utm_campaign ='brand' then website_session_id else null end) as brand_search_sessions,
	count(case when utm_source is null and http_referer is not null then website_session_id else null end) as organic_type_in_sessions,
	count(case when utm_source is null and http_referer is null then website_session_id else null end) as direct_type_in_sessions
from website_sessions
group by 1,2 ;
Select
	sessions_development.yr,
	sessions_development.qtr,
	orders_development.gsearch_nonbrand_orders/sessions_development.gsearch_nonbrand_sessions as gsearch_nonbrand_conv_rt,
	orders_development.bsearch_nonbrand_orders/sessions_development.bsearch_nonbrand_sessions as bsearch_nonbrand_conv_rt,
	orders_development.brand_search_orders/sessions_development.brand_search_sessions as brand_search_conv_rt,
	orders_development.organic_type_in_orders/sessions_development.organic_type_in_sessions as organic_search_conv_rt,
	orders_development.direct_type_in_orders/sessions_development.direct_type_in_sessions as direct_type_in_conv_rt
from sessions_development
inner join orders_development
on sessions_development.yr=orders_development.yr and sessions_development.qtr=orders_development.qtr ;
-- 5. Doanh thu và lợi nhuận theo sản phẩm, tổng doanh thu, tổng lợi nhuận của tất cả sản phẩm
select 
year(created_at) as yr,
month(created_at) as mo,
sum(case when product_id =1 then price_usd else null end) as mrfuzzy_rev,
sum(case when product_id =1 then price_usd - cogs_usd else null end) as mrfuzzy_marg,
sum(case when product_id =2 then price_usd else null end) as lovebear_rev,
sum(case when product_id =2 then price_usd - cogs_usd else null end) as lovebear_marg,
sum(case when product_id =3 then price_usd else null end) as birthdaybear_rev,
sum(case when product_id =3 then price_usd - cogs_usd else null end) as birthdaybear_marg,
sum(case when product_id =4 then price_usd else null end) as minibear_rev,
sum(case when product_id =4 then price_usd - cogs_usd else null end) as minibear_marg,
sum(price_usd) as total_revenue,
sum(price_usd - cogs_usd) as total_margin
from order_items
group by 1,2 ;
-- 6. Tác động của sản phẩm mới
Create temporary table product_page
select
website_session_id,
website_pageview_id,
created_at as time_accsess
from website_pageviews
where pageview_url = '/products';
Create temporary table comparing_pv
Select
product_page.time_accsess,
product_page.website_session_id,
product_page.website_pageview_id,
max(website_pageviews.website_pageview_id) as max_pv
from product_page
inner join website_pageviews
on product_page.website_session_id=website_pageviews.website_session_id
group by 1,2,3;
Create temporary table quantity_click_order
Select
year(comparing_pv.time_accsess) as yr,
month(comparing_pv.time_accsess) as mo,
count(comparing_pv.website_session_id) as click_to_next,
count(orders.order_id) as orders
from comparing_pv
left join orders
on comparing_pv.website_session_id=orders.website_session_id
where comparing_pv.max_pv > comparing_pv.website_pageview_id
group by 1,2;
select
quantity_product.yr,
quantity_product.mo,
quantity_product.sessions as sessions_to_product_page,
quantity_click_order.click_to_next,
quantity_click_order.click_to_next/quantity_product.sessions as clickthrough_rt,
quantity_click_order.orders,
quantity_click_order.orders/quantity_product.sessions as products_to_order_rt
from
	(select
	year(created_at) as yr,
	month(created_at) as mo,
	count(website_session_id) as sessions
	from website_pageviews
	where pageview_url = '/products'
	group by 1,2) as quantity_product
inner join quantity_click_order
on quantity_click_order.yr = quantity_product.yr
and quantity_click_order.mo= quantity_product.mo ;
-- 7.Mức độ hiệu quả của các cặp sản phẩm được bán kèm
select 
orders.primary_product_id,
count(orders.order_id) as total_orders,
count(case when order_items.product_id =1 then order_items.order_id else null end) as _xsold_p1,
count(case when order_items.product_id =2 then order_items.order_id else null end) as _xsold_p2,
count(case when order_items.product_id =3 then order_items.order_id else null end) as _xsold_p3,
count(case when order_items.product_id =4 then order_items.order_id else null end) as _xsold_p4,
count(case when order_items.product_id =1 then order_items.order_id else null end)/count(orders.order_id) as p1_xsell_rt,
count(case when order_items.product_id =2 then order_items.order_id else null end)/count(orders.order_id) as p2_xsell_rt,
count(case when order_items.product_id =3 then order_items.order_id else null end)/count(orders.order_id) as p3_xsell_rt,
count(case when order_items.product_id =4 then order_items.order_id else null end)/count(orders.order_id) as p4_xsell_rt
from orders
left join order_items
on orders.order_id = order_items.order_id
and order_items.is_primary_item = 0
where orders.created_at > '2014-12-05'
group by 1
order by 1 asc ;



