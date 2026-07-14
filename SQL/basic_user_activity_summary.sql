-- ============================================================
-- Basic User Activity Tracking — Course Roster with Login + Course Activity
-- Sources: CDM_LMS.PERSON_COURSE, CDM_LMS.SESSION_ACTIVITY,
--          CDM_LMS.COURSE_ACTIVITY
-- Purpose: One row per enrolled user in a single course, showing
--          system-wide last login alongside course-specific time
--          and interaction totals.
-- Notes  : This is a minimal starting point. For a version with
--          submissions, grades, and parameterized filters, see
--          MultiCourseUserParticipation_20260424.sql and
--          student_course_summary.sql in this directory.
-- See    : docs/Activity_Tracking_Guide.md
-- Author : jeff.kelley@blackboard.com
-- Provided as-is, without warranty or support.
-- ============================================================

WITH course_activity_summary AS (
    -- Aggregate raw activity rows to one row per enrollment
    SELECT
        person_course_id,
        MAX(last_accessed_time)          AS last_course_access,
        ROUND(SUM(duration_sum) / 60, 1) AS total_minutes,
        SUM(interaction_cnt)             AS total_interactions
    FROM CDM_LMS.COURSE_ACTIVITY
    WHERE row_deleted_time IS NULL
    GROUP BY person_course_id
),

last_login AS (
    -- System-wide last login, independent of course
    SELECT
        person_id,
        MAX(last_accessed_time) AS last_login_time
    FROM CDM_LMS.SESSION_ACTIVITY
    WHERE row_deleted_time IS NULL
    GROUP BY person_id
)

SELECT
    c.course_number                          AS bb_course_id,
    c.name                                     AS course_name,
    p.stage:user_id::STRING                   AS bb_user_id,
    CONCAT(p.first_name, ' ', p.last_name)    AS full_name,
    pc.course_role,

    ll.last_login_time,
    cas.last_course_access,
    COALESCE(cas.total_minutes, 0)             AS total_minutes,
    COALESCE(cas.total_interactions, 0)        AS total_interactions

FROM CDM_LMS.PERSON_COURSE pc
JOIN CDM_LMS.PERSON p
    ON p.id = pc.person_id
JOIN CDM_LMS.COURSE c
    ON c.id = pc.course_id
LEFT JOIN course_activity_summary cas
    -- LEFT JOIN so enrollments with zero course activity still appear
    ON cas.person_course_id = pc.id
LEFT JOIN last_login ll
    -- LEFT JOIN so users who've never logged in still appear
    ON ll.person_id = pc.person_id

WHERE pc.row_deleted_time IS NULL  -- exclude deleted enrollments
    AND p.row_deleted_time IS NULL  -- exclude deleted persons
    AND c.row_deleted_time IS NULL  -- exclude deleted courses
    AND c.course_number = 'REPLACE_WITH_COURSE_ID'  -- scope to one course

ORDER BY pc.course_role, full_name;
