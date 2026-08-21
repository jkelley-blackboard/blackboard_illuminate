-- ============================================================
-- Grade Center Use  [DEPRECATED]
--
-- DEPRECATED: inst_minutes_grading / inst_grading_interactions come from
-- CDM_LMS.COURSE_TOOL_ACTIVITY (tool_source_id = 'instructor_gradebook'),
-- which is no longer a tracked activity tool in Ultra courses. For any
-- course list that includes Ultra courses, those two columns will read 0
-- for every instructor regardless of how much grading they actually did
-- -- not a lack of activity, a lack of tracking. Original-course-only
-- course lists are still fine here.
--
-- For a course population that may include Ultra courses, use
-- SQL/instructor_gradebook_use_by_term.sql instead, which adds
-- an Ultra-compatible proxy (inst_grades_modified / inst_last_graded,
-- built off CDM_LMS.GRADE.MODIFIER_PERSON_ID) alongside the same
-- Original-course activity metrics used here.
--
-- For a group of courses (matched by course_number pattern), provides
-- instructors, time spent grading, student count, gradebook item count,
-- and grades recorded.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2023-03-17
-- Updated : 2026-08-21 -- qualified all table references with the
--           cdm_lms. schema (previously relied on the session's current
--           schema being set to CDM_LMS, which isn't self-contained like
--           the rest of this repo); added the pc.active / person
--           availability+enabled filters standard elsewhere in this repo
--           (see unique_instructors_by_term.sql); moved the
--           course_number pattern into a params CTE; and marked this
--           file DEPRECATED per the Ultra caveat above (first noted in
--           the 2025 comment below, now with a documented cause and a
--           working alternative).
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT '%%'::VARCHAR AS course_number_pattern   -- edit to target a course_number LIKE pattern
),

student_cte AS (
    SELECT
        course_id,
        COUNT(1) AS student_count
    FROM cdm_lms.person_course
    WHERE row_deleted_time IS NULL --no deleted enrollments
      AND course_role = 'S'        --student role only
      AND enabled_ind              --no disabled enrollments
    GROUP BY course_id
),

gradebook_cte AS (
    SELECT
        course_id,
        COUNT(1) AS item_count
    FROM cdm_lms.gradebook
    WHERE deleted_ind = FALSE
      AND row_deleted_time IS NULL
    GROUP BY course_id
),

grades_cte AS (
    SELECT
        gbk.course_id,
        COUNT(1) AS grades_count
    FROM cdm_lms.grade grd
    LEFT JOIN cdm_lms.gradebook gbk ON gbk.id = grd.gradebook_id
    WHERE grd.row_deleted_time IS NULL
      AND gbk.row_deleted_time IS NULL
    GROUP BY gbk.course_id
),

activity_cte AS (
    -- instructor grading activity; Original courses only (see DEPRECATED note above)
    SELECT
        person_course_id,
        SUM(duration_sum) / 60.0 AS time_spent,
        SUM(interaction_cnt) AS interaction_cnt
    FROM cdm_lms.course_tool_activity
    WHERE tool_source_id = 'instructor_gradebook'
    GROUP BY person_course_id
)

SELECT
    crs.course_number AS course_id,
    per.stage['user_id']::TEXT AS instructor_id,
    ROUND(COALESCE(act.time_spent, 0), 1) AS inst_minutes_grading,        -- Original courses only, see DEPRECATED note
    COALESCE(act.interaction_cnt, 0) AS inst_grading_interactions,        -- Original courses only, see DEPRECATED note
    COALESCE(std.student_count, 0) AS crs_student_cnt,
    COALESCE(gbk.item_count, 0) AS crs_item_cnt,
    COALESCE(gds.grades_count, 0) AS crs_grades_cnt

FROM cdm_lms.course crs
CROSS JOIN params
LEFT JOIN cdm_lms.person_course pc ON pc.course_id = crs.id
LEFT JOIN cdm_lms.person per ON per.id = pc.person_id
LEFT JOIN student_cte std ON std.course_id = crs.id
LEFT JOIN gradebook_cte gbk ON gbk.course_id = crs.id
LEFT JOIN grades_cte gds ON gds.course_id = crs.id
LEFT JOIN activity_cte act ON act.person_course_id = pc.id

WHERE pc.course_role = 'I'                             -- only course instructors
  AND pc.active = 1                                     -- available + enabled enrollments only
  AND pc.row_deleted_time IS NULL                        -- no deleted course members
  AND per.available_ind = TRUE                           -- exclude unavailable person records
  AND per.enabled_ind = TRUE                             -- exclude disabled person records
  AND crs.course_number LIKE params.course_number_pattern -- course_id filter
  AND crs.row_deleted_time IS NULL                       -- no deleted courses

ORDER BY crs.course_number ASC;
