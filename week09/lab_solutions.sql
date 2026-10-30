-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================

-- ------------------------------------------------------------------------------
-- Ticket 1: [INCIDENT-8104] SecOps Audit Lags & Baseline Execution Plan
-- ------------------------------------------------------------------------------
-- 1. Safely remove idx_audit_email if it exists (for clean re-runs), then write
--    your baseline EXPLAIN ANALYZE diagnostic on audit_logs for
--    user_email = 'william.martinez72@corp.io' below:
DROP INDEX IF EXISTS idx_audit_email;

EXPLAIN ANALYZE
SELECT *
FROM audit_logs WHERE user_email = 'william.martinez72@corp.io';



-- [DIAGNOSTIC REFLECTION 1]
-- Inspect your EXPLAIN ANALYZE terminal output above:
-- 1. Following the '->' arrow to the deepest leaf node, what physical scan node did PostgreSQL select?
-- 2. Why did each worker process have to inspect and discard over 335,000 rows ('Rows Removed by Filter')
--    just to locate 25 matching records?
-- 3. What was the unindexed total Execution Time in milliseconds?
-- Answer (1-2 sentences):
-- 
-- 1. PostgreSQL selected the parallel seq. scan node.
-- 2. Because it was doing a sequention scan for a single emial.
-- 3. 75.249 ms



-- 2. Verification Query 1: Total count of logs for 'william.martinez72@corp.io'
-- Required Output Column: total_user_logs (Expected: 25)

SELECT COUNT(*) AS total_user_logs
FROM audit_logs
WHERE user_email = 'william.martinez72@corp.io';



-- 3. Verification Query 2: First 5 logs for 'william.martinez72@corp.io'
--    ordered by log_timestamp ASC, log_id ASC
-- Required Output Columns: log_id, action, user_email, ip_address, log_timestamp (Expected: 5 rows)
SELECT log_id, action, user_email, ip_address, log_timestamp
FROM audit_logs
WHERE user_email = 'william.martinez72@corp.io'
ORDER BY log_timestamp ASC, log_id ASC LIMIT 5;


-- ------------------------------------------------------------------------------
-- Ticket 2: [PERF-8105] B-Tree Remediation & The Selectivity Tipping Point
-- ------------------------------------------------------------------------------
-- 1. Safely remove any existing idx_audit_email index, build the B-Tree index
--    idx_audit_email on audit_logs(user_email), and refresh planner statistics on audit_logs:
DROP INDEX IF EXISTS idx_audit_email;

CREATE INDEX idx_audit_email ON audit_logs(user_email);


-- 2. Re-run your EXPLAIN ANALYZE diagnostic for user_email = 'william.martinez72@corp.io'
--    to test post-index performance:
EXPLAIN ANALYZE
SELECT *
FROM audit_logs WHERE user_email = 'william.martinez72@corp.io';



-- [DIAGNOSTIC REFLECTION 2A: High Selectivity]
-- In 1-2 sentences, what two execution nodes replaced the sequential scan after creating
-- idx_audit_email, and by approximately what factor did execution time improve?
-- Answer:

-- Bitmap index scan replaced the sequential scan, the execution time for this was
-- 0.082 ms. so the performance improved to Olog(N).




-- 3. Selectivity Tipping Point Experiment:
--    Build temporary index idx_audit_action on audit_logs(action) and refresh statistics:
DROP INDEX IF EXISTS idx_audit_action;

CREATE INDEX idx_audit_action on audit_logs(action);



-- 4. Run an EXPLAIN ANALYZE diagnostic for action = 'password_reset' (4% of table):
EXPLAIN ANALYZE

SELECT *
FROM audit_logs
WHERE action = 'password_reset';


-- 5. Run an EXPLAIN ANALYZE diagnostic for action = 'login_success' (96% of table):
EXPLAIN ANALYZE

SELECT *
FROM audit_logs
WHERE action = 'login_success';



-- [DIAGNOSTIC REFLECTION 2B: The Selectivity Tipping Point]
-- Compare the plans for password_reset (4%) vs login_success (96%) on idx_audit_action:
-- 1. What scan node did PostgreSQL use for password_reset?
-- 2. What scan node did PostgreSQL use for login_success?
-- 3. Why did the Query Planner abandon the index for login_success even though it exists?
-- Answer (1-2 sentences):
-- 1. It did Index Only Scan
-- 2. It did parallel Index Only Scan
-- 3. since login_success matches 96% of the table there's little fitering to be done
---   through the index so a sequential scan is more cheaper than an index in this case.




-- 6. Clean up temporary index idx_audit_action to avoid Write Penalty overhead:
DROP INDEX IF EXISTS idx_audit_action;



-- ------------------------------------------------------------------------------
-- Ticket 3: [AUDIT-8106] Data Dictionary Audit & Ghost Index Verification
-- ------------------------------------------------------------------------------
-- 1. Verification Query 1: Query pg_indexes for tablename = 'audit_logs'
--    ordered by indexname ASC.
-- Required Output Columns: tablename, indexname, indexdef (Expected: 2 rows)
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename = 'audit_logs'
ORDER BY indexname ASC;



-- [DIAGNOSTIC REFLECTION 3: Ghost Indexes]
-- You only ran CREATE INDEX once in Ticket 2, yet pg_indexes displays TWO indexes for audit_logs.
-- What is the other index, and why did PostgreSQL create it automatically?
-- Answer:
-- The other index is audit_logs_pkey. It was generated automatically since
-- audit_logs_pkey is a primary key since it was defined and had to be enforced.




-- 2. Verification Query 2: Count total indexes on tablename = 'audit_logs'
-- Required Output Column: total_indexes (Expected: 2)
SELECT COUNT(*) AS total_indexes
FROM pg_indexes
WHERE tablename = 'audit_logs';


