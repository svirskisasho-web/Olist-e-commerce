SHOW VARIABLES LIKE "secure_file_priv";




-- 1. Customers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_customers_dataset.csv' 
INTO TABLE olist_customers_dataset 
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS;



-- 2. Geolocation
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 3. Order Items
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 4. Order Payments
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;


ALTER TABLE olist_order_reviews_dataset 
ADD COLUMN review_comment_message TEXT AFTER review_comment_title;

-- between step for reviews 

CREATE TABLE olist_reviews_staging (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

-- 1. Empty the staging table first to start fresh
TRUNCATE TABLE olist_reviews_staging;

-- 2. Use this high-precision load command
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE olist_reviews_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
-- This tells MySQL to only end a row when it sees a Windows-style line break, 
-- ignoring the simple 'Enters' inside the text.
LINES TERMINATED BY '\r\n' 
IGNORE 10 ROWS;



-- 5. Order Reviews
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews_dataset
CHARACTER SET latin1             
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
ESCAPED BY ''                    
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message, @v_creation_date, @v_answer_timestamp)
SET 
    -- We just check if the date is empty. If not, MySQL will 
    -- automatically accept '2018-01-18 00:00:00' as a valid date.
    review_creation_date = NULLIF(@v_creation_date, ''),
    review_answer_timestamp = NULLIF(@v_answer_timestamp, '');
    
    
-- 6. Orders
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(order_id, customer_id, order_status, @v_purchase, @v_approved, @v_carrier, @v_customer, @v_estimated)
SET 
    order_purchase_timestamp = NULLIF(@v_purchase, ''),
    order_approved_at = NULLIF(@v_approved, ''),
    order_delivered_carrier_date = NULLIF(@v_carrier, ''),
    order_delivered_customer_date = NULLIF(@v_customer, ''),
    order_estimated_delivery_date = NULLIF(@v_estimated, '');
    
-- 7. Products
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(product_id, product_category_name, @v_name_len, @v_desc_len, @v_photos, @v_weight, @v_length, @v_height, @v_width)
SET 
    product_name_lenght = NULLIF(@v_name_len, ''),
    product_description_lenght = NULLIF(@v_desc_len, ''),
    product_photos_qty = NULLIF(@v_photos, ''),
    product_weight_g = NULLIF(@v_weight, ''),
    product_length_cm = NULLIF(@v_length, ''),
    product_height_cm = NULLIF(@v_height, ''),
    product_width_cm = NULLIF(@v_width, '');

-- 8. Sellers
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- 9. Category Translation
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;