-- ============================================================
-- Basic course instructor Activity Summary
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2025-12-04
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH course_activity_summary AS (
    -- summarize course-level activity per membership
    SELECT
        person_course_id,
        COUNT(DISTINCT id) AS course_access_count,        -- total distinct access events
        SUM(duration_sum) / 60 AS course_access_minutes,  -- total time in minutes
        SUM(interaction_cnt) AS course_interactions,      -- clicks/interactions
        MIN(first_accessed_time) AS first_course_access,  -- first time course accessed
        MAX(last_accessed_time) AS last_course_access     -- most recent access
    FROM cdm_lms.course_activity
    WHERE row_deleted_time IS NULL
    GROUP BY person_course_id
)

SELECT
    -- ===== course context =====
    trm.name AS term,
    cor.course_number AS course_id,
    cor.name AS course_name,
    cor.stage:batch_uid::STRING AS external_course_id,
    cor.start_date,
    cor.end_date,

    -- ===== user context =====
    per.stage:user_id::STRING AS bb_user_id,
    per.stage:student_id::STRING AS bb_student_id,
    per.stage:batch_uid::STRING AS bb_external_id,
    CONCAT(per.first_name, ' ', per.last_name) AS full_name,
    per.email AS email,

    -- ===== activity metrics =====
    COALESCE(ca.course_access_count, 0) AS course_access_count,
    COALESCE(ca.course_access_minutes, 0) AS course_access_minutes,
    COALESCE(ca.course_interactions, 0) AS course_interactions,
    ca.first_course_access,
    ca.last_course_access

FROM cdm_lms.person_course pc
LEFT JOIN course_activity_summary ca ON pc.id = ca.person_course_id
JOIN cdm_lms.person per ON per.id = pc.person_id
JOIN cdm_lms.course cor ON cor.id = pc.course_id
JOIN cdm_lms.term trm ON trm.id = cor.term_id

WHERE pc.row_deleted_time IS NULL  -- exclude deleted memberships
  AND pc.course_role = 'I'      -- instructors only
  AND cor.row_deleted_time IS NULL -- exclude deleted courses
  AND trm.name like '2025%'
