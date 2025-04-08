DROP TABLE rest_user CASCADE CONSTRAINTS;
DROP TABLE reservation CASCADE CONSTRAINTS;
DROP TABLE rest_saloon CASCADE CONSTRAINTS;
DROP TABLE rest_table CASCADE CONSTRAINTS;
DROP TABLE rest_order CASCADE CONSTRAINTS;
DROP TABLE menu_item CASCADE CONSTRAINTS;
DROP TABLE ingredient CASCADE CONSTRAINTS;
DROP TABLE alergen CASCADE CONSTRAINTS;
DROP TABLE saloon_reservation CASCADE CONSTRAINTS;
DROP TABLE table_reservation CASCADE CONSTRAINTS;
DROP TABLE makes CASCADE CONSTRAINTS;
DROP TABLE is_a_part_of CASCADE CONSTRAINTS;
DROP TABLE consists_of CASCADE CONSTRAINTS;
DROP TABLE uses CASCADE CONSTRAINTS;
DROP TABLE contains CASCADE CONSTRAINTS;
DROP SEQUENCE table_seq;


CREATE SEQUENCE table_seq
START WITH 1
INCREMENT BY 1
MAXVALUE 50
NOCACHE
NOCYCLE; 

-- Entity User generalizes the "Employee" and "Customer" entities. 
-- These entities are the only possible specializations and when creating reservations or orders, there is no difference between them. 
-- Therefore, the generalization/specialization is implemented as a single shared table with a distinguishing atribute "user_position".
CREATE TABLE rest_user (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    user_name VARCHAR2(100) NOT NULL, 
    email_address VARCHAR2(100) NOT NULL UNIQUE,
    telephone_num  VARCHAR2(20) NOT NULL, 
    user_position VARCHAR2(20) NOT NULL, 
    user_address VARCHAR2(255),
    CONSTRAINT pk_user PRIMARY KEY (user_id),
    CONSTRAINT chk_email_format CHECK (REGEXP_LIKE(email_address, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')), -- CHECKING FORMAT OF EMAIL ADDRESS
    CONSTRAINT chk_telephone_num CHECK (REGEXP_LIKE(telephone_num, '^0[0-9]{2,3} ?[0-9]{3} ?[0-9]{3}$')), -- CHECKING FORMAT OF TEL NUM
    CONSTRAINT chk_position CHECK (user_position IN ('Employee', 'Customer')), -- ONLY EMPLOYEE AND CUSTOMER ALLOWED AS POSITION
    CONSTRAINT chk_address CHECK (
        (user_position = 'Customer' AND user_address IS NULL ) OR 
        (user_position = 'Employee' And user_address IS NOT NULL)
    )
);

CREATE TABLE reservation (
    reservation_id NUMBER GENERATED ALWAYS AS IDENTITY,
    reservation_holder VARCHAR2(100) NOT NULL,
    user_id NUMBER NOT NULL,
    CONSTRAINT pk_reservation PRIMARY KEY (reservation_id),
    CONSTRAINT fr_user_reserv FOREIGN KEY (user_id) REFERENCES rest_user(user_id) -- EVEN IF USER IS DELETED WE KEEP RECORD OF RESERVATION (EMPLOYEE CAN MAKE RESERVATION IN THE NAME OF CUSTOMER)
);

CREATE TABLE rest_saloon (
    saloon_id NUMBER GENERATED ALWAYS AS IDENTITY,
    saloon_type VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_saloon PRIMARY KEY (saloon_id)
);

CREATE TABLE rest_table (
    table_id NUMBER DEFAULT table_seq.NEXTVAL PRIMARY KEY,
    num_of_seats NUMBER NOT NULL,
    saloon_id NUMBER,
    CONSTRAINT fr_saloon_table FOREIGN KEY (saloon_id) REFERENCES rest_saloon(saloon_id), 
    CONSTRAINT chk_num_of_seats CHECK (num_of_seats > 0) -- TABLE HAS AT LEAST ONE CHAIR
);

CREATE TABLE rest_order (
    order_id NUMBER GENERATED ALWAYS AS IDENTITY,
    order_time TIMESTAMP NOT NULL,
    CONSTRAINT pk_order PRIMARY KEY (order_id)
);

CREATE TABLE menu_item (
    menu_item_id NUMBER GENERATED ALWAYS AS IDENTITY,
    menu_item_name VARCHAR2(100) NOT NULL, 
    menu_item_price NUMBER(6,2) NOT NULL,
    CONSTRAINT pk_menu_item PRIMARY KEY (menu_item_id),
    CONSTRAINT chk_item_price CHECK (menu_item_price > 0)
);

CREATE TABLE ingredient (
    ingredient_id NUMBER GENERATED ALWAYS AS IDENTITY,
    ingredient_name VARCHAR2(100) NOT NULL,
    ingredient_exper_date DATE NOT NULL, 
    ingredient_amount NUMBER NOT NULL,
    ingredient_unit VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_ingredient PRIMARY KEY (ingredient_id)
);

-- CHANGE FROM COMPOSIT ATRIBUTED TO NEW ENTITY  
CREATE TABLE alergen (
    alergen_id NUMBER GENERATED ALWAYS AS IDENTITY,
    alergen_name VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_alergen PRIMARY KEY (alergen_id)
);


CREATE TABLE saloon_reservation (
    event_name VARCHAR2(100) NOT NULL,
    event_time TIMESTAMP NOT NULL,
    event_note VARCHAR2(200),
    reservation_id NUMBER NOT NULL,
    saloon_id NUMBER NOT NULL,
    CONSTRAINT pk_saloon_reservation PRIMARY KEY (reservation_id, saloon_id),
    CONSTRAINT fk_reservation_saloon FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id) ON DELETE CASCADE, 
    CONSTRAINT fk_saloon_id FOREIGN KEY (saloon_id) REFERENCES rest_saloon(saloon_id) ON DELETE CASCADE
);

CREATE TABLE table_reservation (
    event_time TIMESTAMP NOT NULL,
    reservation_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_table_reservation PRIMARY KEY (reservation_id, table_id),
    CONSTRAINT fr_reservation_table FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id) ON DELETE CASCADE,
    CONSTRAINT fr_table_table FOREIGN KEY (table_id) REFERENCES rest_table(table_id) ON DELETE CASCADE
);

CREATE TABLE makes (
    user_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_makes PRIMARY KEY (user_id, order_id, table_id),
    CONSTRAINT fr_user_makes FOREIGN KEY (user_id) REFERENCES rest_user(user_id), -- WE WANT TO KEEP RECORDS ON WHO CREATED ORDERS
    CONSTRAINT fr_order_makes FOREIGN KEY (order_id) REFERENCES rest_order(order_id) ON DELETE CASCADE, -- THIS INFORMATION IS NOT IMPORTANT TO US
    CONSTRAINT fr_table_makes FOREIGN KEY (table_id) REFERENCES rest_table(table_id) ON DELETE CASCADE  -- THIS INFORMATION IS NOT IMPORTANT TO US
);

CREATE TABLE is_a_part_of (
    quantity NUMBER NOT NULL,
    order_note VARCHAR2(200),
    menu_item_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    CONSTRAINT pk_is_a_part_of PRIMARY KEY (menu_item_id, order_id),
    CONSTRAINT fk_menu_item_part_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id), -- TO PREVENT UNINTATIONAL REMOVAL OF INFORMATION ABOUT ORDER
    CONSTRAINT fk_order_part_of FOREIGN KEY (order_id) REFERENCES rest_order(order_id) ON DELETE CASCADE,
    CONSTRAINT chk_quantity CHECK (quantity > 0) -- ORDER MUST CONTAIN AT LEAST ONE ITEM 
);

CREATE TABLE consists_of (
    menu_item_id NUMBER NOT NULL,
    ingredient_id NUMBER NOT NULL,
    CONSTRAINT pk_consits_of PRIMARY KEY (menu_item_id, ingredient_id),
    CONSTRAINT fr_menu_item_consists_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id) ON DELETE CASCADE,
    CONSTRAINT fr_ingredient_consists_of FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE CASCADE
);

CREATE TABLE uses (
    use_time TIMESTAMP NOT NULL,  
    ingredient_amount NUMBER NOT NULL,
    user_id NUMBER NOT NULL,
    ingredient_id NUMBER NOT NULL,
    CONSTRAINT pk_uses PRIMARY KEY (use_time, user_id, ingredient_id),
    CONSTRAINT fr_user_uses FOREIGN KEY (user_id) REFERENCES rest_user(user_id),
    CONSTRAINT fk_ingredient_uses FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id)
);

CREATE TABLE contains (
    ingredient_id NUMBER NOT NULL,
    alergen_id NUMBER NOT NULL,
    CONSTRAINT pk_contains PRIMARY KEY (ingredient_id, alergen_id),
    CONSTRAINT fr_ingredient_contains FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE CASCADE,
    CONSTRAINT fr_alergen_contains FOREIGN KEY (alergen_id) REFERENCES alergen(alergen_id) ON DELETE CASCADE
);

--TIME TO FILL TABLES WITH TEST VALUES

-- USER
INSERT INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
VALUES ('Obi-Wan Kenobi', 'HighGroundEnjoyer@gmail.com', '0954 123 451', 'Employee', 'Tatooine 20, Mos Eisley');
INSERT INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
VALUES ('General Grievous', 'swordCollector@gmail.com', '0957 444 777', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
VALUES ('Anakin Ponebychodici', 'ChoosenOne@gmail.com', '0945 422 888', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
VALUES ('SHEEV PALPATIN', 'UNLIMITEDPOWEEEER@gmail.com', '0957 777 777', 'Employee', 'Corusant 69, GALACTIC CITY');

-- RESERVATION
INSERT INTO reservation (reservation_holder, user_id) -- doplnat automaticky reserv holder?
VALUES ('General Grievous', 1);
INSERT INTO reservation (reservation_holder, user_id)
VALUES ('General Grievous', 2);

-- SALOON
INSERT INTO rest_saloon (saloon_type)
VALUES ('Sand saloon');
INSERT INTO rest_saloon (saloon_type)
VALUES ('Smoking saloon');

-- TABLE
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (4, 1);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (4, 1);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (3, 2);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (5, NULL);

-- ORDER
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.04.2025 18:15:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.04.2025 18:16:00', 'DD.MM.YYYY HH24:MI:SS'));


-- MENU ITEM
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Cerveza Cristal', 500);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Svieckova', 150);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Palacinky z modreho mlieka', 125);

-- INGREDIENT
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name) 
VALUES (TO_DATE('4.9.2026', 'DD.MM.YYYY'), 0.5, 'l', 'CERVEZA CRISTAL');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name) 
VALUES (TO_DATE('3.9.2025', 'DD.MM.YYYY'), 1, 'kg', 'Chren'); 
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.5.2026', 'DD.MM.YYYY'), 50, 'kg', 'Mrkva');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.5.2025', 'DD.MM.YYYY'), 20, 'l', 'Modre mlieko');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('1.1.2026', 'DD.MM.YYYY'), 50, 'kg', 'Muka');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.6.2025', 'DD.MM.YYYY'), 20, 'kusov', 'Vajicko');

-- ALERGEN
INSERT INTO alergen (alergen_name)
VALUES ('lepok');
INSERT INTO alergen (alergen_name)
VALUES ('piesok');

-- SALOON RESERVATION
INSERT INTO saloon_reservation (event_name, event_time, event_note, reservation_id, saloon_id)
VALUES ('Uvitacia party', TO_TIMESTAMP('10.04.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), NULL, 1, 1);

-- TABLE RESERVATION
INSERT INTO table_reservation (event_time, reservation_id, table_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:15:00', 'DD.MM.YYYY HH24:MI:SS'), 2, 4);

-- MAKES
INSERT INTO makes (user_id,order_id, table_id)
VALUES (2, 1, 4);
INSERT INTO makes (user_id,order_id, table_id)
VALUES (2, 2, 4);

--IS A PART OF
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (4, 'CERVEZA CRISTAL!!!', 1, 1);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (4, 'I`m quite hungry', 2, 1);

-- CONSITS OF
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (1, 1);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (2, 2);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (2, 3);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (3, 4);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (3, 5);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (3, 6);

-- USES
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 1);
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 2);

-- CONTAINS
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (2, 2);
COMMIT;

SELECT * FROM rest_user;
SELECT * FROM RESERVATION;
SELECT * FROM REST_SALOON;
SELECT * FROM REST_TABLE;
SELECT * FROM REST_ORDER;
SELECT * FROM MENU_ITEM;
SELECT * FROM INGREDIENT;
SELECT * FROM ALERGEN;
SELECT * FROM SALOON_RESERVATION;
SELECT * FROM TABLE_RESERVATION;
SELECT * FROM MAKES;
SELECT * FROM IS_A_PART_OF;
SELECT * FROM CONSISTS_OF;
SELECT * FROM USES;
SELECT * FROM CONTAINS;


-- TODO - pridat dotazy na tabulky pomocou SELECT:
--
-- Mozne selecty? => kolko obiednavok/reservacii vytvoril user,
--                => kolko z obiednavok bolo vytvorenych zakaznikom a kolko zamestnancom, 
--                => kolko menu_items obsahuje alergen/ingerdienciu, 
--                => kolko ingrediencii obsahuju menu_item,
--                => kolko rezervacii je vytvorenych pre salonik a kolko pre stoly, 
--                => nieco s casom (napr kolko obiednavok bolo vytvorenych v tom a v tom case, pocet ingrediencii zobrany napriklad za mesiac,...),
--                => kolko sa predalo z roznych menu_items a ake menu_item sa predal najviac
--
-- Dalej skontroluj ci tieto SELECT splnaju poziadavky !!!!
-- A samozrejme implementuj.

-- What ingriedients are used in menu item (for example 'svieckova')?
-- This request is done using IN 
SELECT ingredient_name
FROM ingredient 
WHERE ingredient_id IN 
    (SELECT ingredient_id FROM consists_of
     WHERE menu_item_id IN
     (SELECT menu_item_id FROM menu_item
     WHERE menu_item_name = 'svieckova')); 

-- HOW MUCH INGREDIENTS IS IN MENU ITEM (LETS USE 'SVIECKOVA' ONCE AGAIN)?

SELECT ingredient_id, ingredient_name, COUNT(*) AS num_of_ingredients
FROM ingredient ing 
JOIN consists_of c_f ON ing.ingredient_id = c_f.ingredient_id
JOIN menu_item mn_it ON c_f.menu_item_id = mn_it.menu_item_id
WHERE mn_it.menu_item_name = 'svieckova' 
GROUP BY ingredient_id, ingredient_name;

-- SHOW ONLY ORDERS THAT COST MORE THAN 100KC 

SELECT order_id, SUM(is_a_part_of.quantity * menu_item.menu_item_price) as final_sum 
FROM rest_order rst_ord
JOIN is_a_part_of ON rst_ord.order_id = is_a_part_of.order_id
JOIN menu_item ON is_a_part_of.menu_item_id = menu_item.menu_item_id
GROUP BY order_id
HAVING SUM(is_a_part_of.quantity * menu_item.menu_item_price) > 100;
 
-- HOW MANY ORDERS HAS OBIWAN KENOBI MADE

SELECT user_id, user_name, COUNT(order_id) as num_of_orders
FROM rest_user NATURAL JOIN makes
WHERE rest_user.user_name = 'Obi-Wan Kenobi'
GROUP BY user_id, user_name

-- HOW MANY TABLES ARE RESERVED FOR 8 OF APRIL 2025?

SELECT table_id, COUNT(DISTINCT table_id) AS num_of_reserv_table
FROM rest_table
JOIN table_reservation t_r ON rest_table.table_id = t_r.table_id
WHERE TRUNC(t_r.event_time) = TO_DATE('08.04.2025', 'DD.MM.YYYY')
GROUP BY table_id
