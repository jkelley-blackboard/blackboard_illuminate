-- ============================================================
-- Instructor Gradebook Use by Term
--
-- For every active instructor in a term, reports how much they are
-- actually using the gradebook, at the instructor/course grain:
--   - crs_item_cnt        : gradebook items configured in the course
--   - crs_grades_cnt      : grades recorded in the course (any grader)
--   - inst_minutes_grading / inst_grading_interactions:
--       instructor's own Grade Center tool activity. The gradebook
--       is no longer a tracked activity tool in Ultra courses, so
--       tool_source_id = 'instructor_gradebook' only has data for
--       Original courses -- Ultra instructors will show 0 here
--       regardless of how much grading they actually did
--   - inst_grades_modified / inst_last_graded:
--       Ultra-compatible proxy -- grades where THIS instructor is
--       grade.modifier_person_id and grade.modifier_role = 'P'
--       (Learn's raw role code for Instructor). Works for both
--       Original and Ultra since it comes off the grade row itself,
--       not a course_tool_activity log entry. Blank modifier_role
--       rows (bulk import/system) are excluded, so this only counts
--       grades a person actually entered or changed.
--
-- Having gradebook items/grades in a course is not the same as an
-- instructor using the gradebook -- another instructor, a TA, or an
-- import could account for crs_grades_cnt. inst_minutes_grading /
-- inst_grading_interactions and inst_grades_modified / inst_last_graded
-- are the actual usage signals for THIS instructor. If a course has
-- co-instructors, crs_item_cnt and crs_grades_cnt are course totals
-- and will repeat on each of their rows (not split between them).
--
-- To roll this up to one row per instructor for the whole term, wrap
-- this query and GROUP BY person_id, summing the count/minute columns.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2026-08-21
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT '2026 Spring'::VARCHAR AS term_name   -- edit to the target term
),

course_cte AS (
    SELECT
        crs.id AS course_id,
        crs.course_number,
        crs.name AS course_name
    FROM cdm_lms.course crs
    JOIN cdm_lms.term trm ON trm.id = crs.term_id
    CROSS JOIN params
    WHERE trm.name = params.term_name
      AND crs.row_deleted_time IS NULL
      AND crs.enabled_ind = TRUE
),

instructor_cte AS (
    SELECT
        pc.id AS person_course_id,
        pc.course_id,
        per.id AS person_id,
        per.stage['user_id']::TEXT AS instructor_user_id,
        CONCAT(per.first_name, ' ', per.last_name) AS instructor_name,
        per.email
    FROM cdm_lms.person_course pc
    JOIN course_cte cc ON cc.course_id = pc.course_id
    JOIN cdm_lms.person per ON per.id = pc.person_id
    WHERE pc.course_role = 'I'          -- instructors only
      AND pc.active = 1                 -- available + enabled enrollments only
      AND pc.row_deleted_time IS NULL   -- exclude deleted memberships
      AND per.available_ind = TRUE      -- exclude unavailable person records
      AND per.enabled_ind = TRUE        -- exclude disabled person records
),

gradebook_cte AS (
    SELECT course_id, COUNT(1) AS item_count
    FROM cdm_lms.gradebook
    WHERE deleted_ind = FALSE
      AND row_deleted_time IS NULL
    GROUP BY course_id
),

grades_cte AS (
    SELECT gbk.course_id, COUNT(1) AS grades_count
    FROM cdm_lms.grade grd
    JOIN cdm_lms.gradebook gbk ON gbk.id = grd.gradebook_id
    WHERE grd.row_deleted_time IS NULL
      AND gbk.row_deleted_time IS NULL
    GROUP BY gbk.course_id
),

activity_cte AS (
    -- instructor-specific grading activity; original courses only (see header)
    SELECT
        person_course_id,
        SUM(duration_sum) / 60.0 AS minutes_grading,
        SUM(interaction_cnt) AS grading_interactions
    FROM cdm_lms.course_tool_activity
    WHERE tool_source_id = 'instructor_gradebook'
      AND row_deleted_time IS NULL
    GROUP BY person_course_id
),

modified_grades_cte AS (
    -- Ultra-compatible proxy: grades this specific person graded/changed,
    -- keyed by course_id + modifier_person_id (grade has no person_course_id
    -- for the grader -- only for the student being graded)
    SELECT
        gbk.course_id,
        grd.modifier_person_id AS person_id,
        COUNT(1) AS grades_modified,
        MAX(grd.last_graded_time) AS last_graded
    FROM cdm_lms.grade grd
    JOIN cdm_lms.gradebook gbk ON gbk.id = grd.gradebook_id
    WHERE grd.row_deleted_time IS NULL
      AND grd.modifier_role = 'P'         -- Learn role code for Instructor
      AND grd.modifier_person_id IS NOT NULL
    GROUP BY gbk.course_id, grd.modifier_person_id
)

SELECT
    params.term_name AS term,
    cc.course_number,
    cc.course_name,
    ic.person_id,
    ic.instructor_user_id,
    ic.instructor_name AS instructor,
    ic.email,
    COALESCE(gbk.item_count, 0) AS crs_item_cnt,
    COALESCE(gds.grades_count, 0) AS crs_grades_cnt,
    -- inst_minutes_grading / inst_grading_interactions commented out for now:
    -- this tenant's terms are mostly Ultra courses, and the gradebook is no
    -- longer a tracked activity tool in Ultra, so both always read 0 here --
    -- not useful signal until run against an Original-course-heavy term.
    -- ROUND(COALESCE(act.minutes_grading, 0), 1) AS inst_minutes_grading,
    -- COALESCE(act.grading_interactions, 0) AS inst_grading_interactions,
    COALESCE(mg.grades_modified, 0) AS inst_grades_modified,
    mg.last_graded AS inst_last_graded
FROM instructor_cte ic
JOIN course_cte cc ON cc.course_id = ic.course_id
CROSS JOIN params
LEFT JOIN gradebook_cte gbk ON gbk.course_id = ic.course_id
LEFT JOIN grades_cte gds ON gds.course_id = ic.course_id
LEFT JOIN activity_cte act ON act.person_course_id = ic.person_course_id
LEFT JOIN modified_grades_cte mg
    ON mg.course_id = ic.course_id
   AND mg.person_id = ic.person_id
ORDER BY inst_grades_modified DESC, cc.course_number;
