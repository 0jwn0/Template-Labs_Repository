-- ==========================================
-- STUDENT NAME: Jennifer Njogu
-- STUDENT ID: 01256232
-- ==========================================

-- ------------------------------------------------------------------------------
-- Ticket 1: The Roster Safety & Age-Eligibility Audit (Defensive SQL)
-- ------------------------------------------------------------------------------
-- Write your defensive audit query for active players on 'U14 Eagles' below.
-- Sort by emergency_email ASC, last_name ASC, first_name ASC, birthdate ASC, and limit to 8 rows.
-- Required Output Columns: first_name, last_name, birthdate, emergency_email, eligibility_status (Expected: 8 rows)
SELECT 
    u.first_name, 
    u.last_name, 
    u.birthdate,
    COALESCE(u.parent_email,'No Email on File') AS emergency_email,
    CASE 
        WHEN u.birthdate < DATE '2000-01-01' THEN 'Invalid Adult Birthdate'
        WHEN u.birthdate >= DATE '2019-01-01' THEN 'Underage Waiver Required'
        ELSE 'Standard Youth Eligible'
    END AS eligibility_status
FROM users u
JOIN registrations r ON u.user_id = r.user_id
WHERE r.assigned_role = 'player'
    AND r.team_name = 'U14 Eagles'
ORDER BY emergency_email ASC, u.first_name ASC , u.last_name ASC, u.birthdate ASC LIMIT 8;
-- ------------------------------------------------------------------------------
-- Ticket 2: The Equipment Manifest (Relational Views)
-- ------------------------------------------------------------------------------
-- 1. Write your idempotent view definition for vw_equipment_manifest below.
-- Required Output Columns: age_group, gear_item, gear_size, total_quantity
DROP VIEW IF EXISTS vw_equipment_manifest CASCADE;
CREATE VIEW vw_equipment_manifest AS
    SELECT 
    t.age_group, 
    g.gear_item, 
    g.gear_size,
    SUM(g.gear_quantity) AS total_quantity
    FROM teams t
    JOIN registrations r ON r.team_name = t.team_name
    JOIN gear_orders g ON g.registration_id = r.registration_id
    GROUP BY
        t.age_group,
        g.gear_item,
        g.gear_size;



-- 2. Write your two verification queries below:
--    * Verification Query 1: Total row count of the view (Expected: 84)
        SELECT COUNT(*) 
        FROM vw_equipment_manifest;
--    * Verification Query 2: First 5 records ordered by age_group, gear_item, gear_size
        SELECT age_group, gear_item, gear_size, total_quantity
        FROM vw_equipment_manifest
        ORDER BY age_group, gear_item, gear_size
        LIMIT 5;




-- ------------------------------------------------------------------------------
-- Ticket 3: The Roster Age Extremes (Window Functions & Two-Stage Scoping)
-- ------------------------------------------------------------------------------
-- Write your two-stage analytical query to find active players in the top 2
-- competition age ranks (youngest to oldest) on each team below.
-- Required Output Columns: team_name, first_name, last_name, birthdate, age_rank (Expected: 14 rows)
--stage 1
WITH ranked_players AS(
    SELECT
        r.team_name,
        u.first_name,
        u.last_name,
        u.birthdate,
        RANK() OVER (
            PARTITION BY r.team_name
            ORDER BY u.birthdate DESC
        ) AS age_rank
    FROM registrations r
    JOIN users u ON r.user_id = u.user_id
    WHERE r.assigned_role = 'player'
)--stage 2
SELECT team_name, first_name, last_name, birthdate, age_rank
FROM ranked_players
WHERE age_rank IN (1, 2)
ORDER BY team_name, age_rank, last_name, first_name;



