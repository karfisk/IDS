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

---------------------------- Table definitions ----------------------------

-- Entity User generalizes the "Employee" and "Customer" entities. 
-- These entities are the only possible specializations and when creating reservations or orders, there is no difference between them. 
-- Therefore, the generalization/specialization is implemented as a single shared table with a distinguishing atribute "user_position".
CREATE TABLE rest_user (
    user_id NUMBER GENERATED ALWAYS AS IDENTITY START WITH 1 INCREMENT BY 1,
    user_name VARCHAR2(100) NOT NULL, 
    email_adress VARCHAR2(100) NOT NULL UNIQUE,
    telephone_num  VARCHAR2(20) NOT NULL, 
    user_position VARCHAR2(20) NOT NULL, 
    user_adress VARCHAR2(255),
    CONSTRAINT pk_user PRIMARY KEY (user_id),
    CONSTRAINT chk_email_format CHECK (REGEXP_LIKE(email_adress, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')), -- checking format of email adress
    CONSTRAINT chk_telephone_num CHECK (REGEXP_LIKE(telephone_num, '^0[0-9]{2,3} ?[0-9]{3} ?[0-9]{3}$')), -- checking format of tel num
    CONSTRAINT chk_position CHECK (user_position IN ('Employee', 'Customer')), -- only employee and customer are allowed as position
    CONSTRAINT chk_adress CHECK (
        (user_position = 'Customer' AND user_adress IS NULL ) OR 
        (user_position = 'Employee' And user_adress IS NOT NULL)
    )
);

-- Reservation
CREATE TABLE reservation (
    reservation_id NUMBER GENERATED ALWAYS AS IDENTITY,
    reservation_holder VARCHAR2(100) NOT NULL,  -- may differ from the user who created a reservation
    user_id NUMBER NOT NULL,
    CONSTRAINT pk_reservation PRIMARY KEY (reservation_id),
    -- even if user is deleted, we keep record of reservations (employees are able to make reservations on behalf of customers)
    CONSTRAINT fr_user_reserv FOREIGN KEY (user_id) REFERENCES rest_user(user_id)
);

-- Saloon
CREATE TABLE rest_saloon (
    saloon_id NUMBER GENERATED ALWAYS AS IDENTITY,
    saloon_type VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_saloon PRIMARY KEY (saloon_id)
);

-- Table
CREATE TABLE rest_table (
    table_id NUMBER DEFAULT table_seq.NEXTVAL PRIMARY KEY,
    num_of_seats NUMBER NOT NULL,
    saloon_id NUMBER,
    CONSTRAINT fr_saloon_table FOREIGN KEY (saloon_id) REFERENCES rest_saloon(saloon_id), 
    CONSTRAINT chk_num_of_seats CHECK (num_of_seats > 0) -- each table has at least one seat
);

-- Order
CREATE TABLE rest_order (
    order_id NUMBER GENERATED ALWAYS AS IDENTITY,
    order_time TIMESTAMP NOT NULL,
    CONSTRAINT pk_order PRIMARY KEY (order_id)
);

-- Menu_item
CREATE TABLE menu_item (
    menu_item_id NUMBER GENERATED ALWAYS AS IDENTITY,
    menu_item_name VARCHAR2(100) NOT NULL, 
    menu_item_price NUMBER(6,2) NOT NULL,
    CONSTRAINT pk_menu_item PRIMARY KEY (menu_item_id),
    CONSTRAINT chk_item_price CHECK (menu_item_price > 0)
);

-- Ingredient
CREATE TABLE ingredient (
    ingredient_id NUMBER GENERATED ALWAYS AS IDENTITY,
    ingredient_name VARCHAR2(100) NOT NULL,
    ingredient_exper_date DATE NOT NULL, 
    ingredient_amount NUMBER NOT NULL,
    ingredient_unit VARCHAR2(50) NOT NULL,
    CONSTRAINT pk_ingredient PRIMARY KEY (ingredient_id)
);

-- Alergen (changed from composite atribute to a new entity set)
CREATE TABLE alergen (
    alergen_id NUMBER GENERATED ALWAYS AS IDENTITY,
    alergen_name VARCHAR2(100) NOT NULL,
    CONSTRAINT pk_alergen PRIMARY KEY (alergen_id)
);

-- Reservation for a saloon
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

-- Reservation for a table
CREATE TABLE table_reservation (
    event_time TIMESTAMP NOT NULL,
    reservation_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_table_reservation PRIMARY KEY (reservation_id, table_id),
    CONSTRAINT fr_reservation_table FOREIGN KEY (reservation_id) REFERENCES reservation(reservation_id) ON DELETE CASCADE,
    CONSTRAINT fr_table_table FOREIGN KEY (table_id) REFERENCES rest_table(table_id) ON DELETE CASCADE
);

-- User makes an order for a table
CREATE TABLE makes (
    user_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    table_id NUMBER NOT NULL,
    CONSTRAINT pk_makes PRIMARY KEY (user_id, order_id, table_id),
    CONSTRAINT fr_user_makes FOREIGN KEY (user_id) REFERENCES rest_user(user_id), -- we want to keep record of who created orders
    CONSTRAINT fr_order_makes FOREIGN KEY (order_id) REFERENCES rest_order(order_id) ON DELETE CASCADE, -- this information is not important to us
    CONSTRAINT fr_table_makes FOREIGN KEY (table_id) REFERENCES rest_table(table_id) ON DELETE CASCADE  -- this information is not important to us
);

-- Menu_item is a part of an order
CREATE TABLE is_a_part_of (
    is_a_part_of_id NUMBER GENERATED ALWAYS AS IDENTITY,
    quantity NUMBER NOT NULL,
    order_note VARCHAR2(200),
    menu_item_id NUMBER NOT NULL,
    order_id NUMBER NOT NULL,
    CONSTRAINT pk_is_a_part_of PRIMARY KEY (is_a_part_of_id),
    CONSTRAINT fk_menu_item_part_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id), -- to prevent unintentional removal of information about order
    CONSTRAINT fk_order_part_of FOREIGN KEY (order_id) REFERENCES rest_order(order_id) ON DELETE CASCADE,
    CONSTRAINT chk_quantity CHECK (quantity > 0) -- each order has at least one menu_item 
);

-- Menu_item consists of ingredients
CREATE TABLE consists_of (
    menu_item_id NUMBER NOT NULL,
    ingredient_id NUMBER NOT NULL,
    CONSTRAINT pk_consits_of PRIMARY KEY (menu_item_id, ingredient_id),
    CONSTRAINT fr_menu_item_consists_of FOREIGN KEY (menu_item_id) REFERENCES menu_item(menu_item_id) ON DELETE CASCADE,
    CONSTRAINT fr_ingredient_consists_of FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE CASCADE
);

-- Employee uses ingredients (takes them from storage) 
CREATE TABLE uses (
    use_time TIMESTAMP NOT NULL,  
    ingredient_amount NUMBER NOT NULL,
    user_id NUMBER NOT NULL,
    ingredient_id NUMBER NOT NULL,
    CONSTRAINT pk_uses PRIMARY KEY (use_time, user_id, ingredient_id),
    CONSTRAINT fr_user_uses FOREIGN KEY (user_id) REFERENCES rest_user(user_id),
    CONSTRAINT fk_ingredient_uses FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id)
);

-- Ingredient can contain (or be) an alergen
CREATE TABLE contains (
    ingredient_id NUMBER NOT NULL,
    alergen_id NUMBER NOT NULL,
    CONSTRAINT pk_contains PRIMARY KEY (ingredient_id, alergen_id),
    CONSTRAINT fr_ingredient_contains FOREIGN KEY (ingredient_id) REFERENCES ingredient(ingredient_id) ON DELETE CASCADE,
    CONSTRAINT fr_alergen_contains FOREIGN KEY (alergen_id) REFERENCES alergen(alergen_id) ON DELETE CASCADE
);


---------------------------- Filling test data ----------------------------

-- User
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Obi-Wan Kenobi', 'HighGroundEnjoyer@gmail.com', '0954 123 451', 'Employee', 'Tatooine 20, Mos Eisley');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('General Grievous', 'swordCollector@gmail.com', '0957 444 777', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Anakin Ponebychodici', 'ChoosenOne@gmail.com', '0945 422 888', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Sheev Palpatine', 'UNLIMITEDPOWEEEER@gmail.com', '0957 777 777', 'Employee', 'Corusant 69, Galactic City');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Rey Palpatine', 'force_downloaded@instantjedi.pro', '0900 246 431', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Poe Dameron', 'somehowPalpatineReturned@seznam.cz', '0916 731 492', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Jar Jar Binks', 'mooie_mooie_Iloveyou@atlas.cz', '0435 492 681', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Darth Maul', 'KENOBIIII@seznam.cz', '0989 898 989', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Ahsoka Tano', 'im_no_jedi@gmail.com', '0756 755 555', 'Employee', 'Coruscant 620, Underground level');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Jeans Guy', 'inthebackground@gmail.com', '0666 666 666', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Master Yoda', 'there.is.no.try@atlas.cz', '0873 198 263', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Mace Windu', 'take_a_seat@gmail.com', '0326 222 929', 'Employee', 'Coruscant 33, Jedi Temple');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Han Solo', 'i_shot_first@seznam.cz', '0442 838 112', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Admiral Trench', 'i_smell_fear@atlas.cz', '0665 435 982', 'Employee', 'Serenno 55, Serenno City');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Qui-Gon Jinn', 'mindTricks@gmail.com', '0112 648 421', 'Employee', 'Curuscant 24, Jedi Temple');
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Leia Organa', 'rebel_princess@seznam.cz', '0784 346 333', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Luke Skywalker', 'JediLikeMyFather@gmail.com', '0445 642 461', 'Customer', NULL);
INSERT INTO rest_user (user_name, email_adress, telephone_num, user_position, user_adress)
VALUES ('Kylo Ren', 'darthVader_fanclub@seznam.cz', '0882 436 332', 'Customer', NULL);

-- Reservation
INSERT INTO reservation (reservation_holder, user_id)
VALUES ('General Grievous', 1);
INSERT INTO reservation (reservation_holder, user_id)
VALUES ('General Grievous', 2);

-- Saloon
INSERT INTO rest_saloon (saloon_type)
VALUES ('Sand saloon');
INSERT INTO rest_saloon (saloon_type)
VALUES ('Smoking saloon');

-- Table
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (4, 1);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (4, 1);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (3, 2);
INSERT INTO rest_table (num_of_seats, saloon_id)
VALUES (5, NULL);

-- Order
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.04.2025 18:15:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.04.2025 18:16:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('26.03.2024 13:46:25', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('13.04.2025 20:50:25', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('13.04.2025 20:50:43', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.02.2025 17:26:10', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.02.2025 17:26:43', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time)
VALUES (TO_TIMESTAMP('08.02.2025 17:27:08', 'DD.MM.YYYY HH24:MI:SS'));


INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('01.04.2025 12:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('02.04.2025 13:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('03.04.2025 14:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('04.04.2025 15:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('05.04.2025 16:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('06.04.2025 17:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('07.04.2025 18:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('08.04.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('09.04.2025 20:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('10.04.2025 21:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('11.04.2025 22:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('12.04.2025 23:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('13.04.2025 11:00:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('14.04.2025 10:30:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('15.04.2025 13:15:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('16.04.2025 16:45:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('17.04.2025 14:20:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('18.04.2025 12:50:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('19.04.2025 15:10:00', 'DD.MM.YYYY HH24:MI:SS'));
INSERT INTO rest_order (order_time) 
VALUES (TO_TIMESTAMP('20.04.2025 13:40:00', 'DD.MM.YYYY HH24:MI:SS'));



-- Menu_item
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Cerveza Cristal', 665);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Svieckova', 150);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Blue Milk Pancake', 125);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Roasted Nuna Legs with Rootleaf Puree', 175);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Ration Pack', 50);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Iceberg Ice Tea', 25);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Chilly Wine', 60);
INSERT INTO menu_item (menu_item_name, menu_item_price)
VALUES ('Angels Coffee', 45);


INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Naboo Noodles', 110);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Wookiee Wrap', 135);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Bantha Burger', 155);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Hoth Soup', 90);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Alderaan Salad', 120);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Ewok Eggs', 80);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Jawa Juice', 45);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Gungan Gumbo', 130);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Tatooine Tacos', 140);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Yoda Yogurt', 60);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Chewbacca Chili', 145);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Coruscant Curry', 115);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Endor Eclair', 70);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Bespin Bagel', 85);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Dagobah Dumplings', 95);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Sith Sandwich', 100);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Droid Donut', 55);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Clone Cake', 125);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Rebel Ribs', 165);
INSERT INTO menu_item (menu_item_name, menu_item_price) 
VALUES ('Starfighter Stew', 150);


-- Ingredient
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name) 
VALUES (TO_DATE('4.9.2026', 'DD.MM.YYYY'), 0.5, 'l', 'CERVEZA CRISTAL');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name) 
VALUES (TO_DATE('3.9.2025', 'DD.MM.YYYY'), 1, 'kg', 'Horseraddish'); 
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.5.2026', 'DD.MM.YYYY'), 50, 'kg', 'Carrot');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.5.2025', 'DD.MM.YYYY'), 20, 'l', 'Blue milk');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('1.1.2026', 'DD.MM.YYYY'), 50, 'kg', 'Flour');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('5.6.2025', 'DD.MM.YYYY'), 20, 'ks', 'Egg');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('18.5.2025', 'DD.MM.YYYY'), 20, 'kg', 'Nuna legs');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('3.7.2025', 'DD.MM.YYYY'), 15, 'kg', 'Rootleaf mash (Dagobah swamp plant)');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('17.8.2025', 'DD.MM.YYYY'), 50, 'ks', 'Ground fennel pods from Felucia');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('13.9.2026', 'DD.MM.YYYY'), 20, 'kg', 'Drizzle of Mustafarian lava honey');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('29.11.2026', 'DD.MM.YYYY'), 23, 'kg', 'Compressed protein bar (blue milk flavored)');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('29.1.2027', 'DD.MM.YYYY'), 30, 'kg', 'Dehydrated Polystarch portion');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('30.8.2026', 'DD.MM.YYYY'), 35, 'kg', 'Vacuum-sealed Ronto jerky');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('16.11.2026', 'DD.MM.YYYY'), 10, 'kg', 'Hydration capsule (mint)');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('26.12.2028', 'DD.MM.YYYY'), 25, 'kg', 'Ice from Hoth');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('21.6.2027', 'DD.MM.YYYY'), 10, 'l', 'Chilly Wine');
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('28.4.2027', 'DD.MM.YYYY'), 20, 'kg', 'Coffee beans');

-- Alergen
INSERT INTO alergen (alergen_name)
VALUES ('gluten');
INSERT INTO alergen (alergen_name)
VALUES ('sand');
INSERT INTO alergen (alergen_name)
VALUES ('eggs');
INSERT INTO alergen (alergen_name)
VALUES ('milk');

-- Reservation for a saloon
INSERT INTO saloon_reservation (event_name, event_time, event_note, reservation_id, saloon_id)
VALUES ('Welcome party', TO_TIMESTAMP('10.04.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), NULL, 1, 1);

-- Reservation for a table
INSERT INTO table_reservation (event_time, reservation_id, table_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:15:00', 'DD.MM.YYYY HH24:MI:SS'), 2, 4);

-- User makes an order for a table
INSERT INTO makes (user_id, order_id, table_id)
VALUES (2, 1, 4);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (2, 2, 4);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (7, 3, 3);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (2, 4, 3);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (8, 5, 3);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (9, 6, 1);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (3, 7, 3);
INSERT INTO makes (user_id, order_id, table_id)
VALUES (1, 8, 3);

-- Menu_item is a part of an order
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (4, 'CERVEZA CRISTAL!!!', 1, 1);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (4, 'Im quite hungry', 2, 1);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, NULL, 5, 2);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, 'Wesa goen underwater, okeyday?', 3, 3);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (2, 'Wesa goen underwater, okeyday?', 6, 3);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (3, 'Kenobiiii!', 7, 4);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, 'Kenobiiii!', 4, 4);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (4, 'KENOBIIIIII!', 7, 5);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (2, 'KENOBIIIIII!', 1, 5);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, 'Always fun when Skyguy comes by', 3, 6);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, 'Always fun when Skyguy comes by', 8, 6);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, NULL, 4, 7);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, 'Its like being on Hoth again', 6, 7);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, NULL, 2, 8);
INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
VALUES (1, NULL, 8, 8);


BEGIN
  FOR i IN 1..2000 LOOP
    INSERT INTO is_a_part_of (quantity, order_note, menu_item_id, order_id)
    VALUES (
      TRUNC(DBMS_RANDOM.VALUE(1, 5)),
      'Auto-gen note ' || i,
      MOD(i, (SELECT MAX(menu_item_id) FROM menu_item)) + 1,  
      MOD(i, (SELECT MAX(order_id) FROM rest_order)) + 1
    );
  END LOOP;
  COMMIT;
END;
/



-- Menu_item consists of ingredients
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
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (4, 7);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (4, 8);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (4, 9);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (4, 10);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (5, 11);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (5, 12);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (5, 13);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (5, 14);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (6, 15);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (7, 16);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (8, 4);
INSERT INTO consists_of (menu_item_id, ingredient_id)
VALUES (8, 17);

-- Employee uses ingredients
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 1);
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 2);

-- Ingredient can contain (of be) an alergen
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (2, 2);
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (4, 4);
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (5, 1);
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (6, 3);
INSERT INTO contains (ingredient_id, alergen_id)
VALUES (11, 4);

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

---------------------------- Querying the database ----------------------------

-- Which ingriedients are used in menu item 'Ration Pack'?
-- (IN predicate with a subquery)
SELECT ingredient_name
FROM ingredient 
WHERE ingredient_id IN 
    (SELECT ingredient_id FROM consists_of
     WHERE menu_item_id IN
     (SELECT menu_item_id FROM menu_item
     WHERE menu_item_name = 'Ration Pack')); 

-- Which ingredients are in menu item 'Svieckova' and how many of each one?
-- (JOIN of 3 tables)
SELECT ing.ingredient_id, ing.ingredient_name, COUNT(*) AS num_of_ingredients
FROM ingredient ing 
JOIN consists_of c_f ON ing.ingredient_id = c_f.ingredient_id
JOIN menu_item mn_it ON c_f.menu_item_id = mn_it.menu_item_id
WHERE mn_it.menu_item_name = 'Svieckova' 
GROUP BY ing.ingredient_id, ing.ingredient_name;
 
-- Which orders cost more than 200Kc?
-- (GROUP BY and an agregation function)
SELECT ro.order_id, SUM(iap.quantity * m.menu_item_price) as final_sum 
FROM rest_order ro
LEFT JOIN is_a_part_of iap ON ro.order_id = iap.order_id
LEFT JOIN menu_item m ON iap.menu_item_id = m.menu_item_id
GROUP BY ro.order_id
HAVING SUM(iap.quantity * m.menu_item_price) > 200
ORDER BY ro.order_id;
 
-- How many orders has General Grievous made?
-- (GROUP BY and an agregation function)
SELECT user_id, user_name, COUNT(order_id) as num_of_orders
FROM rest_user NATURAL JOIN makes
WHERE rest_user.user_name = 'General Grievous'
GROUP BY user_id, user_name;

-- How many tables are reserved for the 8th of April 2025?
-- (Join of 2 tables)
SELECT rest_table.table_id, COUNT(DISTINCT t_r.table_id) AS num_of_reserv_table
FROM rest_table
JOIN table_reservation t_r ON rest_table.table_id = t_r.table_id
WHERE TRUNC(t_r.event_time) = TO_DATE('08.04.2025', 'DD.MM.YYYY')
GROUP BY rest_table.table_id;

-- Which menu items are alergen free?
-- (Predicate EXISTS)
SELECT DISTINCT mi.menu_item_name, mi.menu_item_price
FROM menu_item mi
WHERE NOT EXISTS (
	SELECT 1
	FROM consists_of co
	JOIN contains c ON co.ingredient_id = c.ingredient_id
	WHERE co.menu_item_id = mi.menu_item_id
);

-- How many times has each menu item been ordered?
-- (Join of 2 tables)
SELECT mi.menu_item_id, mi.menu_item_name, SUM(iap.quantity) AS total_quantity_ordered
FROM is_a_part_of iap
JOIN menu_item mi ON iap.menu_item_id = mi.menu_item_id
GROUP BY mi.menu_item_id, mi.menu_item_name
ORDER BY total_quantity_ordered DESC;



------------------------------------------- Advanced Quaries ---------------------------------------------------

----------------------------------------------- Triggers ------------------------------------------------------

--1. Trigger => reservation control (Only one reservation for saloon or table can be made on specific time)
CREATE OR REPLACE TRIGGER check_for_conflict_in_reservation_table
BEFORE INSERT ON table_reservation
FOR EACH ROW
DECLARE
    num_of_res NUMBER;

BEGIN
    SELECT COUNT(*) INTO num_of_res
    FROM table_reservation 
    WHERE table_id = :NEW.table_id
    AND event_time = :NEW.event_time;
    
    IF num_of_res > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'There is a another reservation in selected time');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER check_for_conflict_in_reservation_saloon
BEFORE INSERT ON saloon_reservation
FOR EACH ROW

DECLARE
    num_of_res NUMBER;

BEGIN 
    SELECT COUNT(*) INTO num_of_res
    FROM saloon_reservation
    WHERE saloon_id = :NEW.saloon_id
    AND event_time = :NEW.event_time;
    IF num_of_res > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'There is a another reservation in selected time');
    END IF;
END;
/

-- Test for 1. Trigger(table)

-- this one will be inserted
INSERT INTO table_reservation (event_time, reservation_id, table_id)
VALUES (TO_TIMESTAMP('12.06.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), 1, 1);

-- this one not (same table id and time)
INSERT INTO table_reservation (event_time, reservation_id, table_id)
VALUES (TO_TIMESTAMP('12.06.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), 2, 1);

-- Test for 1. Trigger(saloon)

-- this one will be inserted
INSERT INTO saloon_reservation (event_name, event_time, event_note, reservation_id, saloon_id)
VALUES ('Welcome party', TO_TIMESTAMP('12.06.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), NULL, 2, 1);

-- this one not(same saloon id and time)
INSERT INTO saloon_reservation (event_name, event_time, event_note, reservation_id, saloon_id)
VALUES ('Welcome party', TO_TIMESTAMP('12.06.2025 19:00:00', 'DD.MM.YYYY HH24:MI:SS'), NULL, 3, 1);


--2. Trigger => check for experation date (user can't use ingredient that exceeded expiration date)
CREATE OR REPLACE TRIGGER check_for_expiration_date
BEFORE INSERT ON uses
FOR EACH ROW

DECLARE
expr_date TIMESTAMP;

BEGIN 
    SELECT ingredient_exper_date INTO expr_date FROM ingredient
    WHERE ingredient_id = :NEW.ingredient_id;

    IF expr_date < :NEW.use_time THEN 
        RAISE_APPLICATION_ERROR(-20002, 'This Ingredient is past its expiration date.');
    END IF;
END;
/

-- Test for 2. Trigger 

-- Created new ingredients 'spoiled milk'
INSERT INTO ingredient (ingredient_exper_date, ingredient_amount, ingredient_unit, ingredient_name)
VALUES (TO_DATE('1.1.2003', 'DD.MM.YYYY'), 666, 'l', 'spoiled milk');

-- inserting it into 'uses' table
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 18);


--3. Trigger => ak zamestnanec prida do tabulky uses ingredienciu sputi sa procedura update_ingredient amount
CREATE OR REPLACE TRIGGER trigger_update_after_insertion_uses
AFTER INSERT ON uses
FOR EACH ROW

BEGIN 
    update_ingredient_amount(:NEW.ingredient_id, :NEW.ingredient_amount);
END;
/

-- Test for 3.Trigger and 2.Procedure
-- There are 20 'Coffee beans' at the beginning, then an emplyee takes 4
-- and this changes the amount in table 'Ingredient'
SELECT * FROM INGREDIENT
WHERE ingredient_name = 'Coffee beans';

-- employee takes 4
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:18:00', 'DD.MM.YYYY HH24:MI:SS'), 4, 1, 17);

SELECT * FROM INGREDIENT
WHERE ingredient_name = 'Coffee beans';

-- employee wants to take amount that is not possible
INSERT INTO uses (use_time, ingredient_amount, user_id, ingredient_id)
VALUES (TO_TIMESTAMP('08.04.2025 18:20:00', 'DD.MM.YYYY HH24:MI:SS'), 21, 1, 17);

----------------------------------------------- Procedures ---------------------------------------------------

--1. Procedure => deletion of expired ingredients
CREATE OR REPLACE PROCEDURE delete_expired_ingredients IS

    CURSOR expr_ing IS
        SELECT * FROM ingredient 
        WHERE ingredient_exper_date < SYSDATE;

    curr_ingredient ingredient%ROWTYPE;
BEGIN 
    OPEN expr_ing;
    LOOP 
        FETCH expr_ing INTO curr_ingredient;
        EXIT WHEN expr_ing%NOTFOUND; 

        BEGIN 
            DELETE FROM ingredient
            WHERE ingredient_id = curr_ingredient.ingredient_id;
        EXCEPTION
            WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Deletion of ingredient with ID: ' || curr_ingredient.ingredient_id || ' was unsuccessful.'); 
        END;
    END LOOP;
    CLOSE expr_ing;

DBMS_OUTPUT.PUT_LINE('Ingredients deleted successfully.');  

EXCEPTION
    WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('An error occurred during the execution of delete_expired_ingredients procedure.');
END;
/

-- Test for 1.Procedure 
SELECT * FROM INGREDIENT;

BEGIN 
    delete_expired_ingredients;
END;
/

SELECT * FROM INGREDIENT;

--2. Procedure => if an ingredient is used, update current amount of that ingredient
--             => atempting to use a bigger amount than is available causes an error
CREATE OR REPLACE PROCEDURE update_ingredient_amount(
    ing_id IN ingredient.ingredient_id%TYPE,
    ing_used_amount IN ingredient.ingredient_amount%TYPE
) IS
    current_amount ingredient.ingredient_amount%TYPE;
BEGIN
    SELECT ingredient_amount INTO current_amount FROM ingredient
    WHERE ingredient_id = ing_id;

    IF ing_used_amount > current_amount THEN
        RAISE_APPLICATION_ERROR(-20003, 'The requested amount of the ingredient is not available.');
    END IF;
    
    UPDATE ingredient
    SET ingredient_amount = current_amount - ing_used_amount
    WHERE ingredient_id = ing_id;

    DBMS_OUTPUT.PUT_LINE('Update successful.');

EXCEPTION
    WHEN OTHERS THEN 
    DBMS_OUTPUT.PUT_LINE('Update unsuccessful.');
    RAISE;

END;
/

------------------------------------- Optimalization with index -----------------------------------------------

-- As an example, we used a SELECT => Find order with menu item that costs more then 500kc 

EXPLAIN PLAN FOR
SELECT ro.order_id, m.menu_item_price
FROM rest_order ro
JOIN is_a_part_of iap ON ro.order_id = iap.order_id
JOIN menu_item m ON iap.menu_item_id = m.menu_item_id
WHERE m.menu_item_price >500;

SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

CREATE INDEX index_menu_item ON menu_item(menu_item_price);

DELETE FROM PLAN_TABLE;
COMMIT;

EXPLAIN PLAN FOR
SELECT ro.order_id, m.menu_item_price
FROM rest_order ro
JOIN is_a_part_of iap ON ro.order_id = iap.order_id
JOIN menu_item m ON iap.menu_item_id = m.menu_item_id
WHERE m.menu_item_price >500;

SELECT * FROM TABLE (DBMS_XPLAN.DISPLAY);

-- There can be another index for optimalization => Menu_item

-- authorization

//GRANT ALL ON igredient TO XKUBOVV00;

BEGIN
    FOR i IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || i.table_name || ' TO XKUBOVV00';
    END LOOP;
END;
/

-- Shows employees and how many orders they made
CREATE MATERIALIZED VIEW XKUBOVV00.alergens_in_menu_items
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT u.user_id, u.user_name, COUNT(*) as num_of_orders
FROM rest_user u
LEFT JOIN makes m ON u.user_id = m.user_id
LEFT JOIN rest_order ord ON m.order_id = ord.order_id
WHERE u.user_position = 'Employee'
GROUP BY u.user_id, u.user_name
HAVING COUNT(ord.order_id) > 0
ORDER BY num_of_orders;

-------------------------------------- SELECT using WITH and CASE ------------------------------------

-- How many orders has each user created and who was active (made orders) this year?
WITH num_of_orders AS (
    SELECT u.user_id, COUNT(*) AS quantity, MAX(ro.order_time) AS last_order
    FROM rest_order ro
    LEFT JOIN makes m ON ro.order_id = m.order_id
    LEFT JOIN rest_user u ON m.user_id = u.user_id
    GROUP BY u.user_id
)
SELECT u.user_name, noo.quantity,
    CASE
        WHEN noo.quantity IS NULL OR noo.last_order < TO_DATE('01.01.2025', 'DD.MM.YYYY') THEN 'Not active'
        ELSE 'Active'
    END AS status
FROM rest_user u
LEFT JOIN num_of_orders noo ON noo.user_id = u.user_id;