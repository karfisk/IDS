/*BEGIN
  FOR t IN (SELECT table_name FROM user_tables) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
  END LOOP;
END;
/*/

DROP TABLE rest_user CASCADE CONSTRAINTS;

CREATE TABLE rest_user (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    user_name VARCHAR2(100) NOT NULL,
    email_address VARCHAR2(100) NOT NULL UNIQUE,
    telephone_num  VARCHAR2(20) NOT NULL,
    user_position VARCHAR2(20) NOT NULL,
    user_address VARCHAR2(255),
    CONSTRAINT pk_user PRIMARY KEY (user_id),
    CONSTRAINT chk_position CHECK (user_position IN ('Employee', 'Customer')),
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
    CONSTRAINT fr_user_reserv FOREIGN KEY (user_id) REFERENCES rest_user(user_id)
);

CREATE TABLE rest_saloon (
    saloon_id NUMBER GENERATED ALWAYS AS IDENTITY,
    saloon_type VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_saloon PRIMARY KEY (saloon_id)
);

CREATE TABLE rest_table (
    table_id NUMBER GENERATED ALWAYS AS IDENTITY,
    num_of_seats NUMBER NOT NULL,
    saloon_id NUMBER,
    CONSTRAINT pk_table PRIMARY KEY (table_id),
    CONSTRAINT fr_saloon_table FOREIGN KEY (saloon_id) REFERENCES rest_saloon(saloon_id)
);

CREATE TABLE rest_order (
    order_id NUMBER GENERATED ALWAYS AS IDENTITY,
    order_time VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_order PRIMARY KEY (order_id)
);

CREATE TABLE menu_item (
    menu_item_id NUMBER GENERATED ALWAYS AS IDENTITY,
    menu_item_name VARCHAR2(100) NOT NULL,
    menu_item_price NUMBER NOT NULL,
    CONSTRAINT pk_menu_item PRIMARY KEY (menu_item_id)
);

-- mozno pridat meno ingrediencie
CREATE TABLE ingredient (
    ingredient_id NUMBER GENERATED ALWAYS AS IDENTITY,
    ingredient_exper_date VARCHAR2(50) NOT NULL,
    ingredient_amount NUMBER NOT NULL,
    ingredient_unit VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_ingredient PRIMARY KEY (ingredient_id)
);

CREATE TABLE alergen (
    alergen_id NUMBER GENERATED ALWAYS AS IDENTITY,
    alergen_name VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_alergen PRIMARY KEY (alergen_id)
);


CREATE TABLE saloon_reservation (
    event_name VARCHAR2(100) NOT NULL,
    event_time VARCHAR2(20) NOT NULL,
    event_note VARCHAR2(200),
    reservation_id NUMBER NOT NULL,
    saloon_id NUMBER NOT NULL,
    CONSTRAINT pk_saloon_reservation PRIMARY KEY (reservation_id, saloon_id),
    CONSTRAINT fk_reservation_saloon FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
    CONSTRAINT fk_saloon_id FOREIGN KEY (saloon_id) REFERENCES rest_saloon(saloon_id)
);

CREATE TABLE table_reservation (
    event_time VARCHAR2(20) NOT NULL,
    reservation_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_table_reservation PRIMARY KEY (reservation_id, table_id),
    CONSTRAINT fr_reservation_table FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id),
    CONSTRAINT fr_table_table FOREIGN KEY (table_id) REFERENCES rest_table(table_id)
);

CREATE TABLE makes (
    user_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_makes PRIMARY KEY (user_id, order_id, table_id),
    CONSTRAINT fr_user_makes FOREIGN KEY (user_id) REFERENCES rest_user(user_id),
    CONSTRAINT fr_order_makes FOREIGN KEY (order_id) REFERENCES rest_order(order_id),
    CONSTRAINT fr_table_makes FOREIGN KEY (table_id) REFERENCES rest_table(table_id)
);

CREATE TABLE is_a_part_of (
    quantity NUMBER NOT NULL,
    order_note VARCHAR2(200),
    menu_item_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    CONSTRAINT pk_is_a_part_of PRIMARY KEY (menu_item_id, order_id),
    CONSTRAINT fk_menu_item_part_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id),
    CONSTRAINT fk_order_part_of FOREIGN KEY (order_id) REFERENCES rest_order(order_id)
);

-- problem co ak mam drink? bude cola zlozena z coly?
CREATE TABLE consists_of (
    menu_item_id NUMBER NOT NULL,
    ingredient_id NUMBER NOT NULL,
    CONSTRAINT pk_consits_of PRIMARY KEY (menu_item_id, ingredient_id),
    CONSTRAINT fr_menu_item_consists_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id),
    CONSTRAINT fr_ingredient_consists_of FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id)
);

CREATE TABLE uses (
    use_time VARCHAR2(20) NOT NULL, -- toto sa este spytat verci 
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
    CONSTRAINT fr_ingredient_contains FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id),
    CONSTRAINT fr_alergen_contains FOREIGN KEY (alergen_id) REFERENCES alergen(alergen_id)
);

--TIME TO FILL TABLES WITH TEST VALUES

TRUNCATE TABLE rest_user;

INSERT ALL 
    INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
    VALUES ('Obi-Wan Kenobi', 'HighGroundEnjoyer@gmail.com', '0954 123 451', 'Employee', 'Tatooine 20, Brno')
    INTO rest_user (user_name, email_address, telephone_num, user_position, user_address)
    VALUES ('General Grievous', 'swordCollector@gmail.com', '0957 444 777', 'Customer', NULL)
SELECT * FROM dual;

INSERT ALL 
    INTO reservation (reservation_holder, user_id) -- doplnat automaticky reserv holder?
    VALUES ('General Grievous', 1)
    INTO reservation (reservation_holder, user_id)
    VALUES ('General Grievous', 1)
SELECT * FROM dual;

INSERT ALL
    INTO rest_saloon (saloon_type)
    VALUES ('Sand saloon')
    INTO rest_saloon (saloon_type)
    VALUES ('Smoking saloon')
SELECT * FROM dual;

INSERT ALL
    INTO rest_table (num_of_seats, saloon_id)
    VALUES (4, 1)
    INTO rest_table (num_of_seats, saloon_id)
    VALUES (4, 1)
    INTO rest_table (num_of_seats, saloon_id)
    VALUES (3, 2)
    INTO rest_table (num_of_seats, saloon_id)
    VALUES (5, NULL)
SELECT * FROM dual;

INSERT ALL
    INTO rest_order (order_time)
    VALUES ('18:15, 8.4.2025')
    INTO rest_order (order_time)
    VALUES ('18:16, 8.4.2025')
SELECT * FROM dual;

INSERT ALL
    INTO menu_item (menu_item_name, menu_item_price)
    VALUES ('Cerveza Cristal', 500)
    INTO menu_item (menu_item_name, menu_item_price)
    VALUES ('Svieckova', 150)
SELECT * FROM dual;

INSERT ALL
    INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit) 
    VALUES ('4.9.2026', 0.5, 'l')
    INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit) 
    VALUES ('3.9.2025', 1, 'kg')
    INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit)
    VALUES ('5.5.2026', 50, 'kg')
SELECT * FROM dual;

INSERT ALL
    INTO alergen (alergen_name)
    VALUES ('lepok')
    INTO alergen (alergen_name)
    VALUES ('piesok')
SELECT * FROM dual;

INSERT ALL
    INTO saloon_reservation (event_name, event_time, event_note, reservation_id, saloon_id)
    VALUES ('Uvitacia party', '19:00, 10.4.2025', NULL, 1, 1)
SELECT * FROM dual;

INSERT ALL 
    INTO table_reservation (event_time, reservation_id, table_id)
    VALUES ('18:15, 8.4.2025', 2, 4)
SELECT * FROM dual;

INSERT ALL
    INTO makes (user_id,order_id, table_id)
    VALUES (2, 1, 4)
    INTO makes (user_id,order_id, table_id)
    VALUES (2, 2, 4)
SELECT * FROM dual;

INSERT ALL
    INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
    VALUES (4, 'CERVEZA CRISTAL!!!', 1, 1)
    INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
    VALUES (4, NULL, 2, 1)
SELECT * FROM dual;

INSERT ALL
    INTO consists_of (menu_item_id, ingredient_id)
    VALUES (1, 1)
    INTO consists_of (menu_item_id, ingredient_id)
    VALUES (2, 2)
    INTO consists_of (menu_item_id, ingredient_id)
    VALUES (2, 3)
SELECT * FROM dual;

INSERT ALL
    INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
    VALUES ('18:18 8.4.2025', '4', 1, 1)
    INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
    VALUES ('18:18 8.4.2025', '4', 1, 2)
SELECT * FROM dual;

INSERT ALL
    INTO contains (ingredient_id, alergen_id)
    VALUES (2, 2)
SELECT * FROM dual;
