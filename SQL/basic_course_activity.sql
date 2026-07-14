-- ============================================================
-- Basic User Activity Tracking — Course Access Summary
-- Source : CDM_LMS.COURSE_ACTIVITY
-- Grain  : Multiple activity rows per enrollment (PERSON_COURSE_ID);
--          aggregated here to one row per person, per course.
-- Purpose: Simplest possible "how much time / how many interactions
--          did this person log in this course" query.
-- Notes  : DURATION_SUM is in seconds, so it's divided by 60 below
--          to report minutes.
-- See    : docs/Activity_Tracking_Guide.md
-- Author : jeff.kelley@blackboard.com
-- Provided as-is, without warranty or support.
-- ============================================================

SELECT
    p.stage:user_id::STRING                  AS bb_user_id,
    CONCAT(p.first_name, ' ', p.last_name)   AS full_name,
    c.course_number                           AS bb_course_id,
    c.name                                     AS course_name,

    MIN(ca.first_accessed_time)                AS first_access,
    MAX(ca.last_accessed_time)                 AS last_access,
    ROUND(SUM(ca.duration_sum) / 60, 1)        AS total_minutes,
    SUM(ca.interaction_cnt)                     AS total_interactions

FROM CDM_LMS.COURSE_ACTIVITY ca
JOIN CDM_LMS.PERSON_COURSE pc
    ON pc.id = ca.person_course_id
JOIN CDM_LMS.PERSON p
    ON p.id = pc.person_id
JOIN CDM_LMS.COURSE c
    ON c.id = pc.course_id

WHERE ca.row_deleted_time IS NULL  -- exclude deleted activity records
    AND pc.row_deleted_time IS NULL -- exclude deleted enrollments
    AND p.row_deleted_time IS NULL  -- exclude deleted persons
    AND c.row_deleted_time IS NULL  -- exclude deleted courses

GROUP BY
    bb_user_id,
    full_name,
    bb_course_id,
    course_name

ORDER BY total_minutes DESC;
