-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================

/*
    I used AI to help me access the database for week 2 for homework 1. I hope that is correct.
*/
-- Task 1

SELECT registration_id, first_name, last_name, gear_quantity, fee_amount FROM master_registration_dump WHERE gear_item LIKE '%Jersey%' AND fee_amount != (25.00 * gear_quantity) LIMIT 5;
SELECT COUNT(*) FROM master_registration_dump WHERE gear_item LIKE '%Jersey%' AND fee_amount != (25.00 * gear_quantity);

-- Task 2

SELECT registration_id, first_name, last_name, gear_quantity, assigned_role FROM master_registration_dump WHERE assigned_role NOT IN ('player', 'coach', 'parent', 'volunteer') LIMIT 5;
SELECT COUNT(*) FROM master_registration_dump WHERE assigned_role NOT IN ('player', 'coach', 'parent', 'volunteer');

-- Task 3

SELECT registration_id, first_name, last_name, birthdate, email FROM master_registration_dump WHERE assigned_role = 'player' AND birthdate > '2018-01-01'  AND (parent_email IS NULL OR BTRIM(parent_email) = '') LIMIT 5;
SELECT COUNT(*) FROM master_registration_dump WHERE assigned_role = 'player' AND birthdate > '2018-01-01'  AND (parent_email IS NULL OR BTRIM(parent_email) = '');