-- ============================================================
-- Single User Weekly Course Activity
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2025-11-18
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH weekly_activity AS (
    SELECT
        PERSON_COURSE_ID,
        DATE_TRUNC('WEEK', first_accessed_time) AS week_start,
        ROUND(SUM(duration_sum)/60,0) AS total_duration_minutes,
        SUM(interaction_cnt) AS total_interactions,
        MIN(first_accessed_time) AS first_access,
        MAX(last_accessed_time) AS last_access
    FROM cdm_lms.course_activity
    WHERE first_accessed_time >= DATE_TRUNC('WEEK', CURRENT_DATE)  --this week
    GROUP BY
        person_course_id,
        DATE_TRUNC('WEEK', first_accessed_time)
)

SELECT 
  per.stage:user_id::text as bb_user_id,
  crs.course_number as bb_course_id,
  wa.*
FROM weekly_activity wa
  JOIN person_course pc on pc.id = wa.person_course_id
  JOIN person per on per.id = pc.person_id
  JOIN course crs on crs.id = pc.course_id
WHERE bb_user_id ilike '%jkelley%'
ORDER BY
    person_id,
    course_id,
    week_start;