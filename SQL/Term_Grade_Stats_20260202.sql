/* ============================================================================================
   QUERY: Course Grade Metrics (Non-Final Grade Counts + Final-Grade Stats)
   AUTHOR: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   DATE:   2026-02-02
   NOTE:   Snowflake SQL. (c) Blackboard Inc. All rights reserved.
           Provided as-is without support or warranty of any kind.

   PURPOSE:
     - Per-course metrics for a given term:
       * Student count (enrolled, enabled, non-preview)
       * Count of non-final gradebook items
       * Count of non-final grades recorded (non-NULL scores)
       * Final-grade stats: max, min, avg, IQR
     - Instructor selection:
       * If one instructor → return that one
       * If multiple and a primary exists → return primary
       * If multiple and no primary → return first by email (deterministic)
   ============================================================================================ */

WITH
select_courses AS (
  SELECT
    cr.id,
    cr.course_number,
    cr.name AS courseName,
    tm.name AS termName,
    tm.source_id,
    cr.available_to_students_ind
  FROM CDM_LMS.course AS cr
  LEFT JOIN CDM_LMS.term AS tm ON tm.id = cr.term_id
  WHERE cr.row_deleted_time IS NULL
    AND tm.name = '2025 Fall'
),
select_students AS (
  SELECT
    pc.id AS person_course_id,
    pc.course_id,
    pc.person_id
  FROM CDM_LMS.person_course AS pc
  JOIN CDM_LMS.person AS pr ON pr.id = pc.person_id
  JOIN select_courses AS crs ON pc.course_id = crs.id
  WHERE pc.course_role = 'S'
    AND pc.enabled_ind = TRUE
    AND pc.row_deleted_time IS NULL
    AND pr.stage:data_src_batchuid::string <> 'BB_STUDENT_PREVIEW'
),
select_grade_items AS (
  SELECT
    gb.id,
    gb.course_id,
    gb.final_grade_ind
  FROM CDM_LMS.gradebook AS gb
  JOIN select_courses AS cr ON cr.id = gb.course_id
  WHERE gb.deleted_ind = FALSE
    AND gb.row_deleted_time IS NULL
),
select_grades AS (
  SELECT
    gi.course_id,
    gi.final_grade_ind,
    gi.id AS gradebook_id,
    gr.person_course_id,
    gr.normalized_score,
    gr.id AS grade_id
  FROM CDM_LMS.grade AS gr
  JOIN select_grade_items AS gi ON gi.id = gr.gradebook_id
  JOIN select_students AS st ON st.person_course_id = gr.person_course_id
  WHERE gr.row_deleted_time IS NULL
    AND gr.normalized_score IS NOT NULL
),
students_per_course AS (
  SELECT
    course_id,
    COUNT(DISTINCT person_course_id) AS student_count
  FROM select_students
  GROUP BY course_id
),
non_final_items_per_course AS (
  SELECT
    course_id,
    COUNT(DISTINCT id) AS non_final_items_count
  FROM select_grade_items
  WHERE final_grade_ind = FALSE
  GROUP BY course_id
),
instructor AS (
  SELECT
    pc.course_id,
    per.email,
    per.last_name,
    per.first_name,
    pc.primary_instructor_ind,
    COUNT(*) OVER (PARTITION BY pc.course_id) AS instructor_count
  FROM CDM_LMS.person_course pc
  JOIN CDM_LMS.person per ON per.id = pc.person_id
  WHERE pc.course_role_source_desc = 'Instructor'
    AND pc.row_deleted_time IS NULL
    AND pc.enabled_ind = TRUE
    AND pc.available_ind = TRUE
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY pc.course_id
    ORDER BY
      CASE WHEN pc.primary_instructor_ind = TRUE THEN 1 ELSE 0 END DESC,
      per.email ASC
  ) = 1
)
SELECT 
  cr.termName,
  cr.course_number AS courseId,
  cr.courseName,
  cr.available_to_students_ind,
  ins.first_name || ' ' || ins.last_name AS primary_instructor,
  ins.email AS email,
  COALESCE(ins.instructor_count, 0) AS instructor_count,
  COALESCE(spc.student_count, 0) AS student_count,
  COALESCE(nfi.non_final_items_count, 0) AS non_final_grade_columns,
  COUNT_IF(fg.final_grade_ind = FALSE) AS non_final_grades_count,
  ROUND(MAX(IFF(fg.final_grade_ind, fg.normalized_score, NULL)), 2) AS final_maximum,
  ROUND(MIN(IFF(fg.final_grade_ind, fg.normalized_score, NULL)), 2) AS final_minimum,
  ROUND(AVG(IFF(fg.final_grade_ind, fg.normalized_score, NULL)), 2) AS final_average,
  ROUND(
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY IFF(fg.final_grade_ind, fg.normalized_score, NULL))
    - PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY IFF(fg.final_grade_ind, fg.normalized_score, NULL))
  , 2) AS final_distribution
FROM select_courses AS cr
LEFT JOIN students_per_course AS spc ON spc.course_id = cr.id
LEFT JOIN non_final_items_per_course AS nfi ON nfi.course_id = cr.id
LEFT JOIN select_grades AS fg ON fg.course_id = cr.id
LEFT JOIN instructor AS ins ON ins.course_id = cr.id
GROUP BY
  cr.termName, cr.course_number, cr.courseName, cr.available_to_students_ind, 
  spc.student_count, nfi.non_final_items_count,
  ins.first_name, ins.last_name, ins.email, ins.instructor_count
ORDER BY
  cr.course_number;