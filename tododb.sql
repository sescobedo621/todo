-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Schema tododb
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `tododb` ;

-- -----------------------------------------------------
-- Schema tododb
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `tododb` DEFAULT CHARACTER SET utf8 ;
SHOW WARNINGS;
USE `tododb` ;

-- -----------------------------------------------------
-- Table `user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `user` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `user` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `username` (16) NOT NULL,
  `password` (32) NOT NULL,
  `create_time`  NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `username_UNIQUE` (`username` ASC));

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `todo`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `todo` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `todo` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `list` VARCHAR(45) NULL DEFAULT NULL,
  `notes` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB
AUTO_INCREMENT = 9
DEFAULT CHARACTER SET = utf8;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `user_has_todo`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `user_has_todo` ;

SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `user_has_todo` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `todo_id` INT(11) NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_user_has_todo_todo1_idx` (`todo_id` ASC),
  INDEX `fk_user_has_todo_user1_idx` (`user_id` ASC),
  CONSTRAINT `fk_user_has_todo_user1`
    FOREIGN KEY (`user_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_user_has_todo_todo1`
    FOREIGN KEY (`todo_id`)
    REFERENCES `tododb`.`todo` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION);

SHOW WARNINGS;
USE `tododb` ;
USE `sakila` ;

-- -----------------------------------------------------
-- Placeholder table for view `customer_list`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `customer_list` (`ID` INT, `name` INT, `address` INT, `zip code` INT, `phone` INT, `city` INT, `country` INT, `notes` INT, `SID` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `film_list`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `film_list` (`FID` INT, `title` INT, `description` INT, `category` INT, `price` INT, `length` INT, `rating` INT, `actors` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `nicer_but_slower_film_list`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `nicer_but_slower_film_list` (`FID` INT, `title` INT, `description` INT, `category` INT, `price` INT, `length` INT, `rating` INT, `actors` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `staff_list`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `staff_list` (`ID` INT, `name` INT, `address` INT, `zip code` INT, `phone` INT, `city` INT, `country` INT, `SID` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `sales_by_store`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sales_by_store` (`store` INT, `manager` INT, `total_sales` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `sales_by_film_category`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `sales_by_film_category` (`category` INT, `total_sales` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- Placeholder table for view `actor_info`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `actor_info` (`actor_id` INT, `first_name` INT, `last_name` INT, `film_info` INT);
SHOW WARNINGS;

-- -----------------------------------------------------
-- procedure rewards_report
-- -----------------------------------------------------

USE `sakila`;
DROP procedure IF EXISTS `rewards_report`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE PROCEDURE `rewards_report` (
    IN min_monthly_purchases TINYINT UNSIGNED
    , IN min_dollar_amount_purchased DECIMAL(10,2) UNSIGNED
    , OUT count_rewardees INT
)
LANGUAGE SQL
NOT DETERMINISTIC 
READS SQL DATA
SQL SECURITY DEFINER
COMMENT 'Provides a customizable report on best customers'
proc: BEGIN
    
    DECLARE last_month_start DATE;
    DECLARE last_month_end DATE;

    /* Some sanity checks... */
    IF min_monthly_purchases = 0 THEN
        SELECT 'Minimum monthly purchases parameter must be > 0';
        LEAVE proc;
    END IF;
    IF min_dollar_amount_purchased = 0.00 THEN
        SELECT 'Minimum monthly dollar amount purchased parameter must be > $0.00';
        LEAVE proc;
    END IF;

    /* Determine start and end time periods */
    SET last_month_start = DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH);
    SET last_month_start = STR_TO_DATE(CONCAT(YEAR(last_month_start),'-',MONTH(last_month_start),'-01'),'%Y-%m-%d');
    SET last_month_end = LAST_DAY(last_month_start);

    /* 
        Create a temporary storage area for 
        Customer IDs.  
    */
    CREATE TEMPORARY TABLE tmpCustomer (customer_id SMALLINT UNSIGNED NOT NULL PRIMARY KEY);

    /* 
        Find all customers meeting the 
        monthly purchase requirements
    */
    INSERT INTO tmpCustomer (customer_id)
    SELECT p.customer_id 
    FROM payment AS p
    WHERE DATE(p.payment_date) BETWEEN last_month_start AND last_month_end
    GROUP BY customer_id
    HAVING SUM(p.amount) > min_dollar_amount_purchased
    AND COUNT(customer_id) > min_monthly_purchases;

    /* Populate OUT parameter with count of found customers */
    SELECT COUNT(*) FROM tmpCustomer INTO count_rewardees;

    /* 
        Output ALL customer information of matching rewardees.
        Customize output as needed.
    */
    SELECT c.* 
    FROM tmpCustomer AS t   
    INNER JOIN customer AS c ON t.customer_id = c.customer_id;

    /* Clean up */
    DROP TABLE tmpCustomer;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- function get_customer_balance
-- -----------------------------------------------------

USE `sakila`;
DROP function IF EXISTS `get_customer_balance`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE FUNCTION `get_customer_balance`(p_customer_id INT, p_effective_date DATETIME) RETURNS DECIMAL(5,2)
    DETERMINISTIC
    READS SQL DATA
BEGIN

       #OK, WE NEED TO CALCULATE THE CURRENT BALANCE GIVEN A CUSTOMER_ID AND A DATE
       #THAT WE WANT THE BALANCE TO BE EFFECTIVE FOR. THE BALANCE IS:
       #   1) RENTAL FEES FOR ALL PREVIOUS RENTALS
       #   2) ONE DOLLAR FOR EVERY DAY THE PREVIOUS RENTALS ARE OVERDUE
       #   3) IF A FILM IS MORE THAN RENTAL_DURATION * 2 OVERDUE, CHARGE THE REPLACEMENT_COST
       #   4) SUBTRACT ALL PAYMENTS MADE BEFORE THE DATE SPECIFIED

  DECLARE v_rentfees DECIMAL(5,2); #FEES PAID TO RENT THE VIDEOS INITIALLY
  DECLARE v_overfees INTEGER;      #LATE FEES FOR PRIOR RENTALS
  DECLARE v_payments DECIMAL(5,2); #SUM OF PAYMENTS MADE PREVIOUSLY

  SELECT IFNULL(SUM(film.rental_rate),0) INTO v_rentfees
    FROM film, inventory, rental
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;

  SELECT IFNULL(SUM(IF((TO_DAYS(rental.return_date) - TO_DAYS(rental.rental_date)) > film.rental_duration,
        ((TO_DAYS(rental.return_date) - TO_DAYS(rental.rental_date)) - film.rental_duration),0)),0) INTO v_overfees
    FROM rental, inventory, film
    WHERE film.film_id = inventory.film_id
      AND inventory.inventory_id = rental.inventory_id
      AND rental.rental_date <= p_effective_date
      AND rental.customer_id = p_customer_id;


  SELECT IFNULL(SUM(payment.amount),0) INTO v_payments
    FROM payment

    WHERE payment.payment_date <= p_effective_date
    AND payment.customer_id = p_customer_id;

  RETURN v_rentfees + v_overfees - v_payments;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- procedure film_in_stock
-- -----------------------------------------------------

USE `sakila`;
DROP procedure IF EXISTS `film_in_stock`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE PROCEDURE `film_in_stock`(IN p_film_id INT, IN p_store_id INT, OUT p_film_count INT)
READS SQL DATA
BEGIN
     SELECT inventory_id
     FROM inventory
     WHERE film_id = p_film_id
     AND store_id = p_store_id
     AND inventory_in_stock(inventory_id);

     SELECT FOUND_ROWS() INTO p_film_count;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- procedure film_not_in_stock
-- -----------------------------------------------------

USE `sakila`;
DROP procedure IF EXISTS `film_not_in_stock`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE PROCEDURE `film_not_in_stock`(IN p_film_id INT, IN p_store_id INT, OUT p_film_count INT)
READS SQL DATA
BEGIN
     SELECT inventory_id
     FROM inventory
     WHERE film_id = p_film_id
     AND store_id = p_store_id
     AND NOT inventory_in_stock(inventory_id);

     SELECT FOUND_ROWS() INTO p_film_count;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- function inventory_held_by_customer
-- -----------------------------------------------------

USE `sakila`;
DROP function IF EXISTS `inventory_held_by_customer`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE FUNCTION `inventory_held_by_customer`(p_inventory_id INT) RETURNS INT
READS SQL DATA
BEGIN
  DECLARE v_customer_id INT;
  DECLARE EXIT HANDLER FOR NOT FOUND RETURN NULL;

  SELECT customer_id INTO v_customer_id
  FROM rental
  WHERE return_date IS NULL
  AND inventory_id = p_inventory_id;

  RETURN v_customer_id;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- function inventory_in_stock
-- -----------------------------------------------------

USE `sakila`;
DROP function IF EXISTS `inventory_in_stock`;
SHOW WARNINGS;

DELIMITER $$
USE `sakila`$$


CREATE FUNCTION `inventory_in_stock`(p_inventory_id INT) RETURNS BOOLEAN
READS SQL DATA
BEGIN
    DECLARE v_rentals INT;
    DECLARE v_out     INT;

    #AN ITEM IS IN-STOCK IF THERE ARE EITHER NO ROWS IN THE rental TABLE
    #FOR THE ITEM OR ALL ROWS HAVE return_date POPULATED

    SELECT COUNT(*) INTO v_rentals
    FROM rental
    WHERE inventory_id = p_inventory_id;

    IF v_rentals = 0 THEN
      RETURN TRUE;
    END IF;

    SELECT COUNT(rental_id) INTO v_out
    FROM inventory LEFT JOIN rental USING(inventory_id)
    WHERE inventory.inventory_id = p_inventory_id
    AND rental.return_date IS NULL;

    IF v_out > 0 THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END$$

DELIMITER ;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `customer_list`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `customer_list` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `customer_list`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `customer_list`
--

CREATE  OR REPLACE VIEW customer_list 
AS 
SELECT cu.customer_id AS ID, CONCAT(cu.first_name, _utf8' ', cu.last_name) AS name, a.address AS address, a.postal_code AS `zip code`,
	a.phone AS phone, city.city AS city, country.country AS country, IF(cu.active, _utf8'active',_utf8'') AS notes, cu.store_id AS SID 
FROM customer AS cu JOIN address AS a ON cu.address_id = a.address_id JOIN city ON a.city_id = city.city_id 
	JOIN country ON city.country_id = country.country_id;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `film_list`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `film_list` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `film_list`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `film_list`
--

CREATE  OR REPLACE VIEW film_list 
AS 
SELECT film.film_id AS FID, film.title AS title, film.description AS description, category.name AS category, film.rental_rate AS price,
	film.length AS length, film.rating AS rating, GROUP_CONCAT(CONCAT(actor.first_name, _utf8' ', actor.last_name) SEPARATOR ', ') AS actors 
FROM category LEFT JOIN film_category ON category.category_id = film_category.category_id LEFT JOIN film ON film_category.film_id = film.film_id
        JOIN film_actor ON film.film_id = film_actor.film_id 
	JOIN actor ON film_actor.actor_id = actor.actor_id 
GROUP BY film.film_id, category.name;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `nicer_but_slower_film_list`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `nicer_but_slower_film_list` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `nicer_but_slower_film_list`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `nicer_but_slower_film_list`
--

CREATE  OR REPLACE VIEW nicer_but_slower_film_list 
AS 
SELECT film.film_id AS FID, film.title AS title, film.description AS description, category.name AS category, film.rental_rate AS price, 
	film.length AS length, film.rating AS rating, GROUP_CONCAT(CONCAT(CONCAT(UCASE(SUBSTR(actor.first_name,1,1)),
	LCASE(SUBSTR(actor.first_name,2,LENGTH(actor.first_name))),_utf8' ',CONCAT(UCASE(SUBSTR(actor.last_name,1,1)),
	LCASE(SUBSTR(actor.last_name,2,LENGTH(actor.last_name)))))) SEPARATOR ', ') AS actors 
FROM category LEFT JOIN film_category ON category.category_id = film_category.category_id LEFT JOIN film ON film_category.film_id = film.film_id
        JOIN film_actor ON film.film_id = film_actor.film_id
	JOIN actor ON film_actor.actor_id = actor.actor_id 
GROUP BY film.film_id, category.name;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `staff_list`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `staff_list` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `staff_list`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `staff_list`
--

CREATE  OR REPLACE VIEW staff_list 
AS 
SELECT s.staff_id AS ID, CONCAT(s.first_name, _utf8' ', s.last_name) AS name, a.address AS address, a.postal_code AS `zip code`, a.phone AS phone,
	city.city AS city, country.country AS country, s.store_id AS SID 
FROM staff AS s JOIN address AS a ON s.address_id = a.address_id JOIN city ON a.city_id = city.city_id 
	JOIN country ON city.country_id = country.country_id;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `sales_by_store`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `sales_by_store` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `sales_by_store`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `sales_by_store`
--

CREATE  OR REPLACE VIEW sales_by_store
AS 
SELECT 
CONCAT(c.city, _utf8',', cy.country) AS store
, CONCAT(m.first_name, _utf8' ', m.last_name) AS manager
, SUM(p.amount) AS total_sales
FROM payment AS p
INNER JOIN rental AS r ON p.rental_id = r.rental_id
INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN store AS s ON i.store_id = s.store_id
INNER JOIN address AS a ON s.address_id = a.address_id
INNER JOIN city AS c ON a.city_id = c.city_id
INNER JOIN country AS cy ON c.country_id = cy.country_id
INNER JOIN staff AS m ON s.manager_staff_id = m.staff_id
GROUP BY s.store_id
ORDER BY cy.country, c.city;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `sales_by_film_category`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `sales_by_film_category` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `sales_by_film_category`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `sales_by_film_category`
--
-- Note that total sales will add up to >100% because
-- some titles belong to more than 1 category
--

CREATE  OR REPLACE VIEW sales_by_film_category
AS 
SELECT 
c.name AS category
, SUM(p.amount) AS total_sales
FROM payment AS p
INNER JOIN rental AS r ON p.rental_id = r.rental_id
INNER JOIN inventory AS i ON r.inventory_id = i.inventory_id
INNER JOIN film AS f ON i.film_id = f.film_id
INNER JOIN film_category AS fc ON f.film_id = fc.film_id
INNER JOIN category AS c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY total_sales DESC;
SHOW WARNINGS;

-- -----------------------------------------------------
-- View `actor_info`
-- -----------------------------------------------------
DROP VIEW IF EXISTS `actor_info` ;
SHOW WARNINGS;
DROP TABLE IF EXISTS `actor_info`;
SHOW WARNINGS;
USE `sakila`;
--
-- View structure for view `actor_info`
--

CREATE  OR REPLACE DEFINER=CURRENT_USER SQL SECURITY INVOKER VIEW actor_info 
AS
SELECT      
a.actor_id,
a.first_name,
a.last_name,
GROUP_CONCAT(DISTINCT CONCAT(c.name, ': ',
		(SELECT GROUP_CONCAT(f.title ORDER BY f.title SEPARATOR ', ')
                    FROM film f
                    INNER JOIN film_category fc
                      ON f.film_id = fc.film_id
                    INNER JOIN film_actor fa
                      ON f.film_id = fa.film_id
                    WHERE fc.category_id = c.category_id
                    AND fa.actor_id = a.actor_id
                 )
             )
             ORDER BY c.name SEPARATOR '; ')
AS film_info
FROM actor a
LEFT JOIN film_actor fa
  ON a.actor_id = fa.actor_id
LEFT JOIN film_category fc
  ON fa.film_id = fc.film_id
LEFT JOIN category c
  ON fc.category_id = c.category_id
GROUP BY a.actor_id, a.first_name, a.last_name;
SHOW WARNINGS;
USE `sakila`;

DELIMITER $$

USE `sakila`$$
DROP TRIGGER IF EXISTS `ins_film` $$
SHOW WARNINGS$$
USE `sakila`$$

CREATE TRIGGER `ins_film` AFTER INSERT ON `film` FOR EACH ROW BEGIN
    INSERT INTO film_text (film_id, title, description)
        VALUES (new.film_id, new.title, new.description);
  END$$

SHOW WARNINGS$$

USE `sakila`$$
DROP TRIGGER IF EXISTS `upd_film` $$
SHOW WARNINGS$$
USE `sakila`$$

CREATE TRIGGER `upd_film` AFTER UPDATE ON `film` FOR EACH ROW BEGIN
    IF (old.title != new.title) or (old.description != new.description)
    THEN
        UPDATE film_text
            SET title=new.title,
                description=new.description,
                film_id=new.film_id
        WHERE film_id=old.film_id;
    END IF;
  END$$

SHOW WARNINGS$$

USE `sakila`$$
DROP TRIGGER IF EXISTS `del_film` $$
SHOW WARNINGS$$
USE `sakila`$$

CREATE TRIGGER `del_film` AFTER DELETE ON `film` FOR EACH ROW BEGIN
    DELETE FROM film_text WHERE film_id = old.film_id;
  END$$

SHOW WARNINGS$$

DELIMITER ;

-- -----------------------------------------------------
-- Data for table `user`
-- -----------------------------------------------------
START TRANSACTION;
USE `sakila`;
INSERT INTO `user` (`id`, `username`, `password`, `create_time`) VALUES (1, shelby, pineapple123, NULL);

COMMIT;


-- -----------------------------------------------------
-- Data for table `user_has_todo`
-- -----------------------------------------------------
START TRANSACTION;
USE `sakila`;
INSERT INTO `user_has_todo` (`id`, `user_id`, `todo_id`) VALUES (1, 1, 1);
INSERT INTO `user_has_todo` (`id`, `user_id`, `todo_id`) VALUES (2, 1, 2);

COMMIT;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
