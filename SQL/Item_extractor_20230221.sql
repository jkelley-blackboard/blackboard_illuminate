-- ============================================================
-- Grade Item Extract
--
-- For every enrollment in select courses, provides grade performance
-- and date for a single item selected by name. If the item doesn't
-- exist for a course or the user has no attempt/grade, returns a
-- null row for that enrollment (LEFT JOIN to the grade subquery --
-- switch to an inner JOIN there if you only want enrollments that
-- actually have a grade for the item).
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2023-02-21
-- Updated : 2026-08-21 -- moved the item name / course pattern / term
--           name into a params CTE at the top; replaced
--           pcr.course_role_desc = 'Student' with the CDM-normalized
--           pcr.course_role = 'S' used elsewhere in this repo; added
--           pcr.row_deleted_time and pcr.active (this file previously
--           checked only pcr.enabled_ind, missing both the deletion
--           check and the availability half of "active"); added
--           crs.row_deleted_time; and corrected a comment that
--           claimed grd.row_deleted_time filtered out deleted
--           courses/users/enrollments -- it only filters deleted
--           grade rows, nothing else.
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        'Points'::VARCHAR                  AS item_name,         -- the gradebook item name, matched across courses
        '%FINANCE_MASTER_RANDALL%'::VARCHAR AS course_number_pattern,
        '2026 Spring'::VARCHAR             AS term_name
    -- demo values above return real rows against the Illuminate demo tenant
    -- (verified 2026-08-21); swap in your own item/course/term to reuse.
)

SELECT
  term.name AS term,
  crs.stage['batch_uid']::string AS external_course_key,
  crs.course_number AS course_id,
  per.stage['batch_uid']::string AS external_person_key,
  per.stage['user_id']::string AS user_id,
  grades.item_name,
  grades.percent,
  grades.attempts,
  grades.last_attempt

FROM CDM_LMS.person_course pcr
   CROSS JOIN params
   JOIN CDM_LMS.person per ON per.id = pcr.person_id
   JOIN CDM_LMS.course crs ON crs.id = pcr.course_id
   LEFT JOIN CDM_LMS.term term ON term.id = crs.term_id
   LEFT JOIN (                     --change to regular JOIN to filter out nulls
     SELECT                        --subquery to get grade data
       grd.person_course_id,
       gbk.name AS item_name,
       ROUND(grd.normalized_score,3) AS percent,
       grd.attempted_cnt AS attempts,
       grd.last_attempted_time AS last_attempt
     FROM CDM_LMS.grade grd
       JOIN CDM_LMS.gradebook gbk ON gbk.id = grd.gradebook_id
       CROSS JOIN params
     WHERE gbk.name = params.item_name
       AND NOT gbk.deleted_ind
       AND grd.row_deleted_time IS NULL           --excludes deleted grade rows only
     ) grades on grades.person_course_id = pcr.id

WHERE pcr.active = 1                          --available + enabled enrollments only (supersedes the old enabled_ind-only check)
  AND pcr.row_deleted_time IS NULL            --exclude deleted enrollments
  AND crs.row_deleted_time IS NULL            --exclude deleted courses
  AND per.stage['user_id']::string NOT LIKE '%_previewuser'
  AND pcr.course_role = 'S'
  AND crs.course_number like params.course_number_pattern
  AND term.name = params.term_name

ORDER BY crs.course_number DESC
