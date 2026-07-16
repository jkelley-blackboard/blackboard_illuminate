/* ============================================================================================
   QUERY: Course Grade Metrics (Non-Final Grade Counts + Final-Grade Stats) — v2
   AUTHOR: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   DATE:   2026-02-03
   NOTE:   Snowflake SQL. (c) Blackboard Inc. All rights reserved.
           Provided as-is without support or warranty of any kind.
   ============================================================================================ */

WITH

-- pre select the course list by term --
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
  WHERE cr.row_deleted_time IS NULL  --no deleted courses
    AND tm.name like '2026 Spring%'
),
-- pre select members with student role, not disabled, not deleted, not preview --
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

-- get a count of enabled students --
student_counter AS (
  SELECT
    course_id,
    COUNT(DISTINCT person_course_id) AS student_count
  FROM select_students
  GROUP BY course_id
),

-- a list of grade columns that are not deleted --
select_grade_items AS (
  SELECT
    gb.id,
    gb.course_id,
    gb.final_grade_ind
  FROM CDM_LMS.gradebook AS gb
  WHERE gb.deleted_ind = FALSE
    AND gb.row_deleted_time IS NULL
),

-- count non final grade items and test for final only 0 or 1 --
item_counter AS (
  SELECT
    course_id,
    COUNT_IF(final_grade_ind != TRUE OR final_grade_ind IS NULL) AS non_final_item_count,
    COUNT_IF(final_grade_ind = TRUE) AS final_item_count,
  FROM select_grade_items
  GROUP BY course_id
),

-- get the grade records for select students and select items --
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

-- count grade records that are not final grades --
grade_stats AS (
  SELECT
    course_id,
    COUNT_IF(final_grade_ind != TRUE OR final_grade_ind IS NULL) AS non_final_grade_cnt
  FROM select_grades
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
  COALESCE(sc.student_count, 0) AS student_count,
  COALESCE(ic.non_final_item_count, 0) AS non_final_grade_columns,
  COALESCE(ic.final_item_count, 0) AS final_grade_columns,
  COALESCE(gs.non_final_grade_cnt, 0) AS non_final_grade_cnt

FROM select_courses cr
LEFT JOIN student_counter AS sc ON sc.course_id = cr.id
LEFT JOIN item_counter AS ic ON ic.course_id = cr.id
LEFT JOIN grade_stats AS gs ON gs.course_id = cr.id
LEFT JOIN instructor AS ins ON ins.course_id = cr.id
ORDER BY
  cr.course_number;