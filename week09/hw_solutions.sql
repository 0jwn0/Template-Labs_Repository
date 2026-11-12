-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================

-- ------------------------------------------------------------------------------
-- Task 1: [SUPPORT-7021] Customer Portal Latency & Multi-Table Join Diagnostics
-- ------------------------------------------------------------------------------
-- 1. Safely remove idx_registrations_user_id and idx_gear_registration if they exist
--    (for clean re-runs), then write your baseline EXPLAIN ANALYZE diagnostic joining
--    users, registrations, and gear_orders for email = 'william.martinez72@corp.io' below:

DROP INDEX IF EXISTS idx_registrations_user_id;
DROP INDEX IF EXISTS idx_gear_registration;

EXPLAIN ANALYZE
SELECT u.first_name, u.last_name, g.gear_item, gear_size
FROM users u
JOIN registrations r ON r.user_id = u.user_id
JOIN gear_orders g ON g.registration_id = r.registration_id
WHERE u.email = 'william.martinez72@corp.io';



-- [DIAGNOSTIC REFLECTION 1: Multi-Table Join Bottleneck]
-- Inspect your baseline EXPLAIN ANALYZE join output above:
-- 1. What scan node did PostgreSQL use for users, and why was it able to use an index?
-- 2. What scan node and join algorithm were used for registrations and gear_orders?
-- 3. Why did PostgreSQL perform full-table scans on both child tables even though foreign keys exist?
-- Answer (1-2 sentences):
-- used index scan for users since, PostgreSQL created a b-tree index for the email 'william.martinez72@corp.io'
-- so that it can quickly locate the matching user instead of scanning every row. the join algorithm used for
-- resgistrations and gear_orders is Hash join and the scans used for them was sequential scan. And a full-table
-- scan since it was cheaper with the amount of rows that had to be read given the user constraint.




-- 2. Verification Query: Run the standard join query for 'william.martinez72@corp.io'
--    ordered by gear_item ASC, gear_size ASC.
-- Required Output Columns: first_name, last_name, gear_item, gear_size (Expected: 3 rows)

EXPLAIN ANALYZE
SELECT u.first_name, u.last_name, g.gear_item, gear_size
FROM users u
JOIN registrations r ON r.user_id = u.user_id
JOIN gear_orders g ON g.registration_id = r.registration_id
WHERE u.email = 'william.martinez72@corp.io'
ORDER BY gear_item ASC, gear_size ASC;




-- ------------------------------------------------------------------------------
-- Task 2: [PERF-7022] Foreign Key Remediation & Multi-Table Join Optimization
-- ------------------------------------------------------------------------------
-- 1. Safely remove if existing and build B-Tree index idx_registrations_user_id
--    on registrations(user_id):
DROP INDEX IF EXISTS idx_registrations_user_id;

CREATE INDEX idx_registrations_user_id ON registrations(user_id);



-- 2. Safely remove if existing and build B-Tree index idx_gear_registration
--    on gear_orders(registration_id):
DROP INDEX IF EXISTS idx_gear_registration;

CREATE INDEX idx_gear_registration ON gear_orders(registration_id);



-- 3. Refresh planner statistics on registrations and gear_orders:
ANALYZE registrations;
ANALYZE gear_orders;



-- 4. Re-run your join EXPLAIN ANALYZE diagnostic from Task 1 to test the
-- post-index execution plan across all three tables:
EXPLAIN ANALYZE
SELECT u.first_name, u.last_name, g.gear_item, gear_size
FROM users u
JOIN registrations r ON r.user_id = u.user_id
JOIN gear_orders g ON g.registration_id = r.registration_id
WHERE u.email = 'william.martinez72@corp.io';

-- [DIAGNOSTIC REFLECTION 2: Post-Index Join Execution Analysis]
-- Inspect your post-index EXPLAIN ANALYZE join output above:
-- 1. What join node and scan nodes replaced the Hash Join and Seq Scans after indexing foreign keys?
-- 2. By approximately what factor did total query execution time improve compared to Task 1?
-- 3. Why is a Nested Loop join with index lookups vastly more efficient here than a Hash Join?
-- Answer (1-2 sentences):
-- Nested Loop and index scan, the total query execution time improved 190x more. The nested
-- join with index lookups are vastly more efficient that a hash join here because the email
-- filter returns very few users so postgresql can match user's ID to perform targeted index lookups
-- in registrations and gear_orders avoding full table scans.




-- ------------------------------------------------------------------------------
-- Task 3: [FEAT-7023] Composite B-Tree Optimization & The Phonebook Rule
-- ------------------------------------------------------------------------------
-- 1. Safely remove if existing and build composite B-Tree index idx_users_full_name
--    on users(last_name, first_name), then refresh planner statistics on users:
DROP INDEX IF EXISTS idx_users_full_name;

CREATE INDEX idx_users_full_name ON users(last_name, first_name);

ANALYZE users;


-- 2. Run an EXPLAIN ANALYZE diagnostic on users for last_name = 'Brodie'
--    AND first_name = 'Alex' (projecting user_id, first_name, last_name, email):
EXPLAIN ANALYZE
SELECT user_id, first_name, last_name, email
FROM users
WHERE last_name = 'Brodie'
  AND first_name = 'Alex';


-- 3. (Observational Diagnostic) Test the Phonebook Rule:
--    Run an EXPLAIN ANALYZE diagnostic on users for first_name = 'Alex' alone:
EXPLAIN ANALYZE
SELECT user_id, first_name, last_name, email
FROM users
WHERE first_name = 'Alex';


-- [DIAGNOSTIC REFLECTION 3: The Phonebook Rule in Practice]
-- Compare your plans for (last_name = 'Brodie' AND first_name = 'Alex') vs (first_name = 'Alex' alone):
-- 1. What index and scan node did PostgreSQL use when both names were provided?
-- 2. How did the execution plan change when last_name was omitted?
-- 3. Explain the Phonebook Rule: why can't a composite index on (last_name, first_name) perform
--    a single direct point lookup when the leading column is missing?
-- Answer (1-2 sentences):
-- PostgreSQL used Bitmap Heap Scan and Bitmap Index Scan on index and scan nodes
-- Due to the last name being excluded in the second analyze the number of heap box's
-- was 31 and the shared hit and read buffers where 49 and 20 and there were 15 searches and the 
-- execution time was 0.604. which is all longer than when the analyze had the last name
-- included. the composite index is ordered by last_name first, rows with the first_name = Alex
-- are spread across the index under many last names. without the leading column last_name
-- condition, PostgreSQL can't just point to the exact last name and first name just the range
-- of first names for Alex.


-- 4. Verification Query: Count matching users where last_name = 'Brodie'
--    AND first_name = 'Alex'
-- Required Output Column: matching_users (Expected: 203)
SELECT COUNT(*) matching_users
FROM users
WHERE last_name = 'Brodie'
  AND first_name = 'Alex';




-- ------------------------------------------------------------------------------
-- Task 4: [AUDIT-7024] System Catalog Audit & The Unindexed Foreign Key Dilemma
-- ------------------------------------------------------------------------------
-- 1. Verification Query 1: Query pg_indexes for tablename IN ('users', 'teams', 'registrations', 'gear_orders')
--    ordered by tablename ASC, indexname ASC.
-- Required Output Columns: tablename, indexname (Expected: 8 rows)
SELECT tablename, indexname
FROM pg_indexes
WHERE tablename IN ('users', 'teams', 'registrations', 'gear_orders')
ORDER BY tablename ASC, indexname ASC;


-- [DIAGNOSTIC REFLECTION 4: Schema Index Audit & The Unindexed Foreign Key Dilemma]
-- Inspect your pg_indexes catalog output across the four tables:
-- 1. Architectural Inventory: Across the 8 returned indexes, which 5 are automatic Ghost Indexes
--    (and what constraints created them), and which 3 are manual performance indexes from Tasks 2 & 3?
-- 2. The Unindexed Foreign Key Dilemma: Which foreign key in our schema remains unindexed?
-- 3. Engineering Evaluation: Would you approve adding an index on registrations(team_name)?
--    Explain using the Selectivity Tipping Point (6 teams, ~16.5% selectivity per team) and Write Penalty.
-- Answer (2-3 sentences):
-- automatic index's are the primary key indexes for users, teams, registrations, gear_orders, and the unique index
-- for users_email. the 3 manual performance index's are idx_gear_registation, idx_registation_user_id, and
-- idx_users_full_name. The foriegn key that is unindexed is on for teams. adding an index on registations(team_name)
-- would not work since the 6 teams which would be 16.5% which is more than %5 to 15% of a large table, the optimizer
-- will choose to abandon the index and just do a sequential scan.


-- 2. Verification Query 2: Count total indexes across ('users', 'teams', 'registrations', 'gear_orders')
-- Required Output Column: total_indexes (Expected: 8)
SELECT COUNT(*) AS total_indexes
FROM pg_indexes
WHERE tablename IN ('users', 'teams', 'registrations', 'gear_orders');





