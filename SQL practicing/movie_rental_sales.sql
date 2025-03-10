-- ex1: create index for first & last name
select first_name, last_name from actor;
CREATE INDEX idx_lastname_firstname ON actor (last_name, first_name);
EXPLAIN SELECT * FROM actor WHERE last_name = 'Allen' AND first_name = 'Cuba';
EXPLAIN SELECT * FROM actor WHERE last_name = 'Allen';
EXPLAIN SELECT * FROM actor ORDER BY last_name, first_name;

-- ex2: search rental date in feb 2006 and optimize
explain SELECT rental_id, rental_date, inventory_id, customer_id
FROM rental
WHERE rental_date BETWEEN '2006-02-01' AND '2006-02-28';
-- optimize
CREATE INDEX idx_rental_date ON rental (rental_date);
EXPLAIN SELECT rental_id, rental_date, inventory_id, customer_id
FROM rental
WHERE rental_date BETWEEN '2006-02-01' AND '2006-02-28';

-- ex3: full text search
CREATE FULLTEXT INDEX idx_description ON film (description);
SELECT title, description
FROM film
WHERE MATCH(description) AGAINST('drama' IN BOOLEAN MODE)
  AND NOT MATCH(description) AGAINST('teacher' IN BOOLEAN MODE);
SELECT title, description
FROM film
WHERE MATCH(description) AGAINST('"Emotional Drama"' IN BOOLEAN MODE);

-- ex4: partioning customer
CREATE TABLE customer_partitioned (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    -- Add other columns here, except the foreign keys
    -- assuming the original foreign key columns are 'address_id' and 'store_id'
    create_date date,
    last_update timestamp,
	address_id INT,
    store_id INT
)
PARTITION BY HASH(customer_id) PARTITIONS 5;
INSERT INTO customer_partitioned (customer_id, first_name, last_name, email, address_id, store_id)
SELECT customer_id, first_name, last_name, email, address_id, store_id
FROM customer;
SELECT TABLE_NAME, PARTITION_NAME, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, PARTITION_EXPRESSION, TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'customer_partitioned';

-- ex5: partitioning rental
drop table rental_partitioned;
CREATE TABLE rental_partitioned (
    rental_id INT,
    rental_date DATETIME,
    inventory_id INT,
    customer_id INT,
    return_date DATETIME,
    staff_id INT,
    last_update TIMESTAMP,
    PRIMARY KEY (rental_id, rental_date)  -- Include rental_date to comply with partitioning rules
)
PARTITION BY RANGE (YEAR(rental_date)) (
    PARTITION p2005 VALUES LESS THAN (2006),
    PARTITION p2006 VALUES LESS THAN (2007),
    PARTITION p2007 VALUES LESS THAN (2008),
    PARTITION p_max VALUES LESS THAN MAXVALUE
);
INSERT INTO rental_partitioned (rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update
FROM rental;
SELECT TABLE_NAME, PARTITION_NAME, PARTITION_ORDINAL_POSITION, PARTITION_METHOD, PARTITION_EXPRESSION, TABLE_ROWS
FROM INFORMATION_SCHEMA.PARTITIONS
WHERE TABLE_NAME = 'rental_partitioned';

CREATE INDEX idx_rental_date ON rental_partitioned(rental_date);
SHOW INDEXES FROM rental_partitioned;
explain SELECT rental_id, rental_date, inventory_id, customer_id
FROM rental_partitioned
WHERE rental_date BETWEEN '2006-01-01' AND '2006-12-31';

-- add new partition
ALTER TABLE rental_partitioned REORGANIZE PARTITION p_max INTO (
    PARTITION p2008 VALUES LESS THAN (2009),
    PARTITION p_max VALUES LESS THAN MAXVALUE
);
INSERT INTO rental_partitioned (rental_id, rental_date, customer_id, inventory_id, return_date)
VALUES (1002, '2008-07-21 14:30:00', 2, 101, '2008-07-21 16:30:00');