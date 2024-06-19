-- Created a function to concatenate the movie rating to the movie title
CREATE OR REPLACE FUNCTION add_rating(title VARCHAR(100), rating VARCHAR(4))
	RETURNS VARCHAR(110)
	LANGUAGE plpgsql
AS $$
BEGIN
RETURN concat(title, ', Film Rating: ', rating); 
END; $$;

-- Created detailed_rental and summary_profit tables. The summary_profit table calculates net profit. 
DROP TABLE if exists detailed_rental;
CREATE TABLE detailed_rental (
	title VARCHAR(115),
	rating VARCHAR(5),
	rental_rate NUMERIC,
	replacement_cost NUMERIC,
	rental_id SERIAL 
);
SELECT * FROM detailed_rental;

DROP TABLE if exists summary_profit;
CREATE TABLE summary_profit(
	title VARCHAR(115),
	net_profit NUMERIC
);

SELECT * FROM summary_profit;

-- Extracted the data to insert into the tables
INSERT INTO detailed_rental
	SELECT  b.title, b.rating, b.rental_rate, b.replacement_cost, c.rental_id
	FROM inventory a
	INNER JOIN film b on a.film_id=b.film_id
	INNER JOIN rental c on a.inventory_id=c.inventory_id
	GROUP BY title, rating, rental_rate, replacement_cost, rental_id
	ORDER BY title;
	
INSERT INTO summary_profit
	SELECT add_rating(d.title, d.rating), 
	(d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
	FROM detailed_rental d
	GROUP BY  title, rating, rental_rate, replacement_cost
	ORDER BY net_profit desc;

SELECT * FROM detailed_rental;
SELECT * FROM summary_profit;

-- Created a trigger to refresh the summary table when data is inserted to the detailed table 
CREATE OR REPLACE FUNCTION trigger_function()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM summary_profit;
INSERT INTO summary_profit
	SELECT add_rating(d.title, d.rating), 
	(d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
	FROM detailed_rental d
	GROUP BY  title, rating, rental_rate, replacement_cost
	ORDER BY net_profit desc;
RETURN NEW;
END; $$;


CREATE OR REPLACE TRIGGER new_detailed_entry
AFTER INSERT
ON detailed_rental
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_function();


-- Testing the trigger
SELECT * FROM summary_profit;
SELECT COUNT(*) FROM summary_profit;
SELECT COUNT(*) FROM detailed_rental;

INSERT INTO detailed_rental VALUES ('Aaaah RUN', 'R', 199.99, '4.99');

SELECT * FROM summary_profit;
SELECT COUNT(*) FROM summary_profit;
SELECT COUNT(*) FROM detailed_rental;

-- Created a stored procedure that can be used to refresh the data in both created tables. 
-- The procedure clears the contents of the detailed table and summary table and performs the raw data extraction.
CREATE OR REPLACE PROCEDURE table_update()
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM detailed_rental;
INSERT INTO detailed_rental
	SELECT  b.title, b.rating, b.rental_rate, b.replacement_cost, c.rental_id
	FROM inventory a
	INNER JOIN film b on a.film_id=b.film_id
	INNER JOIN rental c on a.inventory_id=c.inventory_id
	GROUP BY title, rating, rental_rate, replacement_cost, rental_id
	ORDER BY title;

DELETE FROM summary_profit;	
INSERT INTO summary_profit
	SELECT add_rate(d.title, d.rental_rate), (d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
	FROM detailed_rental d
	GROUP BY  title, rental_rate, replacement_cost
	ORDER BY net_profit desc;
END; $$;

-- CALL PROCEDURE
CALL table_update();
-- TEST PROCEDURE
SELECT * FROM summary_profit;

SELECT COUNT(*) FROM summary_profit;
SELECT COUNT(*) FROM detailed_rental;

