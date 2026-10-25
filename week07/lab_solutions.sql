-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================
DROP TABLE IF EXISTS gear_orders CASCADE;
DROP TABLE IF EXISTS registrations CASCADE;
DROP TABLE IF EXISTS teams CASCADE;
DROP TABLE IF EXISTS users CASCADE;
-- ==============================================================================
-- TICKET 2: THE CORE ENTITIES (DDL & MIGRATION)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Part 2A: The People (users Table DDL)
-- ------------------------------------------------------------------------------
-- Write your idempotent DROP and CREATE TABLE statements for users below:
    CREATE TABLE users (
    email VARCHAR NOT NULL PRIMARY KEY,
    first_name VARCHAR NOT NULL,
    last_name VARCHAR NOT NULL,
    phone VARCHAR,
    birthdate DATE,
    parent_email VARCHAR
    );

-- ------------------------------------------------------------------------------
-- Part 2B: The Teams (teams Table DDL)
-- ------------------------------------------------------------------------------
-- Write your idempotent DROP and CREATE TABLE statements for teams below:
CREATE TABLE teams (
    team_name VARCHAR NOT NULL PRIMARY KEY,
    age_group VARCHAR NOT NULL,
    CHECK (age_group IN ('U10','U12','U14'))
);

-- ------------------------------------------------------------------------------
-- Part 2C: The Migration Pipeline (INSERT ... SELECT DISTINCT)
-- ------------------------------------------------------------------------------
-- Wrap both of your INSERT statements inside a transaction block (BEGIN / COMMIT):
BEGIN;
INSERT INTO users (email, first_name, last_name, phone, birthdate, parent_email)
SELECT DISTINCT email, first_name, last_name, phone, birthdate, parent_email
FROM master_registration_dump;

INSERT INTO teams (team_name, age_group)
SELECT DISTINCT team_name, age_group
FROM master_registration_dump;
COMMIT;

-- ------------------------------------------------------------------------------
-- Part 2D: Logic Verification
-- ------------------------------------------------------------------------------
-- Write your two SELECT COUNT(*) queries below to verify row counts:
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM teams;


-- ==============================================================================
-- TICKET 3: CHILD ENTITIES & THE DIRTY DATA TRAP
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- Step 1: Pre-Load Child Tables (Provided Starter Block)
-- Execute this block to populate the unconstrained child tables in your database:
-- ------------------------------------------------------------------------------


CREATE TABLE registrations (
    registration_id SERIAL PRIMARY KEY,
    user_email VARCHAR(255),
    team_name VARCHAR(100),
    assigned_role VARCHAR(50),
    fee_amount NUMERIC(10,2)
);

INSERT INTO registrations (user_email, team_name, assigned_role, fee_amount)
SELECT DISTINCT email, team_name, assigned_role, fee_amount
FROM master_registration_dump;

CREATE TABLE gear_orders (
    order_id SERIAL PRIMARY KEY,
    registration_id INT,
    gear_item VARCHAR(100),
    gear_size VARCHAR(20),
    gear_quantity INT
);

INSERT INTO gear_orders (registration_id, gear_item, gear_size, gear_quantity)
SELECT r.registration_id, m.gear_item, m.gear_size, m.gear_quantity
FROM master_registration_dump m
JOIN registrations r 
  ON m.email = r.user_email 
 AND m.team_name = r.team_name 
 AND m.assigned_role = r.assigned_role
WHERE m.gear_item IS NOT NULL;

-- Corrupted Legacy Data: A rogue script seeded negative fees!
UPDATE registrations SET fee_amount = -50.00 WHERE registration_id IN (101, 204, 305);


-- ------------------------------------------------------------------------------
-- Part 3A: Forging the Links (Foreign Keys via ALTER TABLE)
-- ------------------------------------------------------------------------------
-- Write your 3 ALTER TABLE statements to add fk_user, fk_team, and fk_registration:
ALTER TABLE registrations
    ADD CONSTRAINT fk_user
    FOREIGN KEY (user_email)
    REFERENCES users (email)
    ON UPDATE CASCADE;
ALTER TABLE registrations
    ADD CONSTRAINT fk_teams
    FOREIGN KEY (team_name)
    REFERENCES teams (team_name)
    ON DELETE RESTRICT;
ALTER TABLE gear_orders
    ADD CONSTRAINT fk_registration
    FOREIGN KEY (registration_id)
    REFERENCES registrations (registration_id)
    ON DELETE CASCADE;

-- ------------------------------------------------------------------------------
-- Part 3B: Preventing Duplicate Registrations (Composite UNIQUE)
-- ------------------------------------------------------------------------------
-- Write your ALTER TABLE statement to add unique_registration:
ALTER TABLE registrations
    ADD CONSTRAINT unique_registration
    UNIQUE (user_email, assigned_role, team_name);

-- ------------------------------------------------------------------------------
-- Part 3C: The Dirty Data Trap (Cleanse & CHECK)
-- ------------------------------------------------------------------------------
-- 1. Write the UPDATE statement to cleanse negative fee amounts to 0.00:
BEGIN;

UPDATE registrations
SET fee_amount = 0.00
WHERE fee_amount < 0.00;

COMMIT;
--refuses because it checks existing rows when adding
--constraints.

-- 2. Write the ALTER TABLE statement to apply the check_fee constraint:
ALTER TABLE registrations
    ADD CONSTRAINT check_fee
    CHECK (fee_amount >= 0.00);

-- ------------------------------------------------------------------------------
-- Part 3D: Final Verification
-- ------------------------------------------------------------------------------
-- Write a SELECT query to prove zero negative fees remain in registrations:

SELECT COUNT(*) AS negative_fee_count
FROM registrations
WHERE fee_amount < 0.00;

