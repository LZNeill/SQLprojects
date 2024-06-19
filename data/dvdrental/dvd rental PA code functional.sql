
/*B.  Provide original code for function(s) in text format that perform the 
transformation(s) you identified in part A4. */

CREATE OR REPLACE FUNCTION add_rate(title VARCHAR(100), rental_rate numeric)
	RETURNS VARCHAR(110)
	LANGUAGE plpgsql
AS $$
BEGIN
RETURN concat(title, ', Rental rate: ',CAST(rental_rate as VARCHAR(10))); 
END; $$;

/*C.  Provide original SQL code in a text format that creates the 
detailed and summary tables to hold your report table sections. */
DROP TABLE if exists detailed_rental;
CREATE TABLE detailed_rental (
	title VARCHAR(115),
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

/* D.  Provide an original SQL query in a text format that will extract the raw data 
needed for the detailed section of your report from the source database. */
INSERT INTO detailed_rental
	SELECT  b.title, b.rental_rate, b.replacement_cost, c.rental_id
	FROM inventory a
	INNER JOIN film b on a.film_id=b.film_id
	INNER JOIN rental c on a.inventory_id=c.inventory_id
	GROUP BY title, rental_rate, replacement_cost, rental_id
	ORDER BY title;
	
INSERT INTO summary_profit
	SELECT add_rate(d.title, d.rental_rate), 
	(d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
	FROM detailed_rental d
	GROUP BY  title, rental_rate, replacement_cost
	ORDER BY net_profit desc;

SELECT * FROM detailed_rental;
SELECT * FROM summary_profit;

/* To test if the math was correct in summary profit and that the table passes a sanity check, 
I searched for the instances of one film, Apache Divine, which was found 31 times at a rental 
rate of 4.99 (31 * 4.99 = 154.69) and subtracted the replacement rate to see net profit which is 
137.70 and matches the value in summary table. */

SELECT * FROM detailed_rental WHERE title='Apache Divine';

/* E.  Provide original SQL code in a text format that creates a trigger on the 
detailed table of the report that will continually update the summary table 
as data is added to the detailed table. */

CREATE OR REPLACE FUNCTION trigger_function()
	RETURNS TRIGGER
	LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM summary_profit;
INSERT INTO summary_profit
	SELECT add_rate(d.title, d.rental_rate), 
	(d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
	FROM detailed_rental d
	GROUP BY  title, rental_rate, replacement_cost
	ORDER BY net_profit desc;
RETURN NEW;
END; $$;


CREATE OR REPLACE TRIGGER new_detailed_entry
AFTER INSERT
ON detailed_rental
FOR EACH STATEMENT
EXECUTE PROCEDURE trigger_function();


-- TEST TRIGGER
SELECT * FROM summary_profit;
SELECT COUNT(*) FROM summary_profit;
SELECT COUNT(*) FROM detailed_rental;

INSERT INTO detailed_rental VALUES ('Aaaah RUN', 199.99, 4.99);

SELECT * FROM summary_profit;
SELECT COUNT(*) FROM summary_profit;
SELECT COUNT(*) FROM detailed_rental;


/* F.  Provide an original stored procedure in a text format that can be used to refresh 
the data in both the detailed table and summary table. The procedure should clear the 
contents of the detailed table and summary table and perform the raw data extraction 
from part D. */

CREATE OR REPLACE PROCEDURE table_update()
LANGUAGE plpgsql
AS $$
BEGIN
DELETE FROM detailed_rental;
INSERT INTO detailed_rental
	SELECT  b.title, b.rental_rate, b.replacement_cost, c.rental_id
	FROM inventory a
	INNER JOIN film b on a.film_id=b.film_id
	INNER JOIN rental c on a.inventory_id=c.inventory_id
	GROUP BY title, rental_rate, replacement_cost, rental_id
	ORDER BY title;

DELETE FROM summary_profit;	
INSERT INTO summary_profit
	SELECT add_rate(d.title, d.rental_rate), 
	(d.rental_rate * (COUNT(d.rental_id)) - d.replacement_cost) as net_profit
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

--pgAgent could be installed to use with PostgreSQL to schedule this refresh to run automatically.  