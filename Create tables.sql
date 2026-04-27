create table olist_customers_dataset (
customer_id varchar (255),
customer_unique_id varchar (255),
customer_zip_code_prefix varchar(255),
customer_city varchar (255),
customer_state varchar (255)
);

create table olist_geolocation_dataset (
geolocation_zip_code_prefix varchar (255),
geolocation_lat float,
geolocation_lng float, 
geolocation_city varchar (255),
geolocation_state varchar (255)
);


create table olist_order_items_dataset (
order_id varchar (255),
order_item_id varchar (255),
product_id varchar (255),
seller_id varchar (255),
shipping_limit_date DATETIME,
price float,
freight_value float
 );
 
 
 create table olist_order_payments_dataset (
order_id varchar (255),
payment_sequential varchar (255),
payment_type varchar (255),
payment_installments varchar (255),
payment_value float
 );


create table olist_order_reviews_dataset (
review_id varchar (255),
order_id varchar (255),
review_score varchar (300),
review_comment_title varchar (300),
review_creation_date DATETIME,
review_answer_timestamp DATETIME
 );
 
 
create table olist_orders_dataset (
order_id varchar (255),
customer_id varchar(255),
order_status varchar (255),
order_purchase_timestamp DATETIME,
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date DATETIME,
order_estimated_delivery_date DATETIME
 );
 
 
create table olist_products_dataset (
product_id varchar (255),
product_category_name varchar(255),
product_name_lenght int,
product_description_lenght int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int
 );
 
 
create table olist_sellers_dataset (
seller_id varchar (255),
seller_zip_code_prefix int,
seller_city varchar (255),
seller_state varchar (255)
 );
 
 create table product_category_name_translation (
product_category_name varchar (255),
product_category_name_english varchar (255)
 );