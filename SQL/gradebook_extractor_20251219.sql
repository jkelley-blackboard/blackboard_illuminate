-- ============================================================
-- Gradebook Extractor
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2025-12-19
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH course_cte AS (  -- you can expand this CTE to be term based selection of courses
    SELECT
        crs.id AS course_id,
        crs.stage['batch_uid']::TEXT AS external_course_key,
        crs.course_number AS bb_courseid
    FROM cdm_lms.course AS crs
    WHERE crs.stage['batch_uid']::TEXT like 'ADV_101_%'
      AND crs.row_deleted_time IS NULL
),
gradebook_cte AS (
    SELECT
        gbk.id AS gradebook_id,
        gbk.course_id,
        gbk.name,
        gbk.gradebook_type,
        gbk.final_grade_ind,
        gbk.possible_score,
        gbk.due_time
    FROM cdm_lms.gradebook AS gbk
    JOIN course_cte AS c
      ON gbk.course_id = c.course_id
    WHERE gbk.deleted_ind = 'N'
      AND gbk.row_deleted_time IS NULL
    -- Uncomment to include only final grade items:
      AND gbk.final_grade_ind = true
),
roster_cte AS (
    SELECT
        pcr.id AS person_course_id,
        pcr.course_id,
        per.id AS person_id,
        per.stage['batch_uid']::TEXT AS external_person_key,
        CONCAT_WS(', ', per.last_name, per.first_name) as student_name
    FROM cdm_lms.person_course AS pcr
    JOIN cdm_lms.person AS per
      ON per.id = pcr.person_id
    JOIN course_cte AS c
      ON pcr.course_id = c.course_id
    WHERE pcr.row_deleted_time IS NULL
      AND pcr.enabled_ind = true     --only enabled
      AND pcr.course_role = 'S'  --only students
),
grades_cte AS (
    SELECT
        grd.id AS grade_id,
        grd.gradebook_id,
        grd.person_course_id,
        grd.score,
        grd.possible_score,
        grd.name,
        ROUND(grd.normalized_score, 3) AS percentage
    FROM cdm_lms.grade AS grd
    WHERE grd.row_deleted_time IS NULL
)
SELECT
    c.external_course_key,
    r.external_person_key,
    r.student_name,
    gk.name AS item_name,
    REGEXP_REPLACE(gk.gradebook_type, '\\.name$', '') AS category,
    gk.final_grade_ind,
    gk.due_time AS due_date,
    gk.possible_score as possible_score_item,
    gr.possible_score as possible_score_user,
    gr.name AS grade,
    gr.score,
    gr.percentage
FROM gradebook_cte AS gk
JOIN course_cte AS c ON gk.course_id = c.course_id
JOIN roster_cte AS r ON r.course_id = c.course_id
LEFT JOIN grades_cte AS gr ON gr.gradebook_id = gk.gradebook_id
 AND gr.person_course_id = r.person_course_id
ORDER BY c.external_course_key,r.external_person_key, gk.name;