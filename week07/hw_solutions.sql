-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================

-- ------------------------------------------------------------------------------
-- Task 1: The Failed Deletion (Referential Integrity)
-- ------------------------------------------------------------------------------
-- 1. In a 2–3 sentence SQL comment, explain which Foreign Key constraint blocked
--    the deletion, what rule is in effect, and why this prevents orphaned records:
-- 2. Include your commented-out DELETE statement immediately below your explanation:

--DELETE FROM users
--WHERE email = 'alex.oakley65@outlook.com';
-- was caught by foreign key constraint 'fk_users'
--The no action rule Referential Integrity rule is applied
--since the fk_users links registration user email to user email
--the deletion was blocked since we can't delete Alex while still
--refering to him since they would point to a user that no longer existed.


-- ------------------------------------------------------------------------------
-- Task 2: The Safe Migration (Cascading Updates)
-- ------------------------------------------------------------------------------
-- 1. Write the UPDATE statement to change Alex Oakley's email in the users table:
-- 2. Write the SELECT query against registrations to prove the cascade worked:
-- 3. In a SQL comment, explain how registrations received the update automatically:

UPDATE users
SET email = 'deleted_user@example.com'
WHERE email = 'alex.oakley65@outlook.com';

SELECT user_email
FROM registrations
WHERE user_email ='deleted_user@example.com';

--The child records of registration recieved the new email update for Alex because
--the user_email functional key is linked to the users email Primary key. the clause
--that we did in the lab for week 7 that allowed us to do this was ALTER TABLE for the registrations
--table that we set up the links for the keys.

-- ------------------------------------------------------------------------------
-- Task 3: The Disaster Drill (ACID Transactions)
-- ------------------------------------------------------------------------------
-- Write your complete ACID transaction block below:
-- (BEGIN, UPDATE, SELECT ... ORDER BY registration_id LIMIT 5, ROLLBACK, SELECT ... ORDER BY registration_id LIMIT 5):

BEGIN;
UPDATE registrations SET fee_amount = 0.00;
SELECT registration_id, fee_amount
FROM registrations
ORDER BY registration_id LIMIT 5;
ROLLBACK;
SELECT registration_id, fee_amount
FROM registrations
ORDER BY registration_id LIMIT 5;
COMMIT;

-- ------------------------------------------------------------------------------
-- Task 4: The Great Migration (Moving to Surrogate Keys - Boss Level)
-- ------------------------------------------------------------------------------
-- 1. Write your single, atomic transaction block (BEGIN ... COMMIT) executing
--    all migration phases (schema expansion, data backfill, constraint swapping, cleanup):
-- 2. Immediately after COMMIT, write your verification query against information_schema.columns:

BEGIN;
ALTER TABLE users
    ADD COLUMN user_id SERIAL;
ALTER TABLE registrations
    ADD COLUMN user_id INT;

UPDATE registrations r
SET user_id = u.user_id
FROM users u
WHERE r.user_email = u.email;

ALTER TABLE registrations
    DROP CONSTRAINT fk_user;
ALTER TABLE users
    DROP CONSTRAINT users_pkey;
ALTER TABLE users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
ALTER TABLE users
    ADD CONSTRAINT users_email_unique  UNIQUE (email);
ALTER TABLE registrations
    ADD CONSTRAINT fk_user_id
    FOREIGN KEY (user_id)
    REFERENCES users (user_id)
    ON DELETE CASCADE;
ALTER TABLE registrations
    DROP COLUMN user_email;
COMMIT;

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_schema = current_schema()
    AND table_name IN ('users', 'Registrations')
    AND column_name IN ('user_id', 'email', 'user_email')
ORDER BY table_name DESC, column_name ASC;