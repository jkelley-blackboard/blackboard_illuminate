-- ============================================================
-- Student summary report
-- Revised from https://github.com/blackboard/BBDN-BlackboardData-Queries/tree/master/student-course-summary
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2025-10-16
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH course_activity_summary AS (
    -- Summarize course-level activity per student
    SELECT
        person_course_id,
        COUNT(DISTINCT id) AS course_access_count,       -- Total distinct access events
        SUM(duration_sum) / 60 AS course_access_minutes,  -- Total time in minutes
        SUM(interaction_cnt) AS course_interactions,      -- Clicks / interactions
        MIN(first_accessed_time) AS first_course_access,  -- First time course accessed
        MAX(last_accessed_time) AS last_course_access     -- Most recent access
    FROM CDM_LMS.COURSE_ACTIVITY
    WHERE ROW_DELETED_TIME IS NULL
    GROUP BY person_course_id
),
submission_summary AS (
    -- Count submissions per student per course
    SELECT
        person_course_id,
        COUNT(DISTINCT id) AS submission_count,           -- Number of submissions
        MAX(submitted_time) AS last_submission            -- Most recent submission date
    FROM CDM_LMS.SUBMISSION
    WHERE ROW_DELETED_TIME IS NULL
    GROUP BY person_course_id
),
grade_summary AS (
    -- Pull final grade if available
    SELECT
        lg.person_course_id,
        lgb.name AS total_grade_column,
        lg.normalized_score AS total_grade                -- Final normalized grade (0–1)
    FROM CDM_LMS.GRADE lg
    INNER JOIN CDM_LMS.GRADEBOOK lgb
        ON lg.gradebook_id = lgb.id
    WHERE lgb.final_grade_ind = 1
      AND lg.row_deleted_time IS NULL
)

SELECT
    -- ===== COURSE CONTEXT =====
    lt.name AS term,                                     -- Official academic term name
    lc.course_number AS course_id,                       -- Full course code
    lc.name AS course_name,                              -- Course title
    lc.stage:batch_uid::string AS external_course_id,    -- External SIS course ID from JSON
    lc.start_date,                                       -- Course start date
    lc.end_date,                                         -- Course end date

    -- ===== STUDENT CONTEXT =====
    lp.stage:user_id::string AS student_user_id,         -- LMS login/username
    lp.stage:student_id::string AS student_id,           -- Institutional student ID
    lp.stage:batch_uid::string AS student_external_id,   -- External SIS ID
    CONCAT(lp.first_name, ' ', lp.last_name) AS student_name, -- Full student name
    lp.email AS student_email,                           -- Contact email

    -- ===== ACTIVITY METRICS =====
    COALESCE(lca.course_access_count, 0) AS course_access_count,
    COALESCE(lca.course_access_minutes, 0) AS course_access_minutes,
    COALESCE(lca.course_interactions, 0) AS course_interactions,
    lca.first_course_access,
    lca.last_course_access,
    COALESCE(ls.submission_count, 0) AS submission_count,
    ls.last_submission,
    
    gr.total_grade_column AS total_grade_column,
    ROUND(COALESCE(gr.total_grade, 0),3) AS total_grade

FROM CDM_LMS.PERSON lp
INNER JOIN CDM_LMS.PERSON_COURSE lpc
    ON lpc.person_id = lp.id
    AND lpc.course_role = 'S'                            -- Limit to students
INNER JOIN CDM_LMS.COURSE lc
    ON lc.id = lpc.course_id
INNER JOIN CDM_LMS.TERM lt
    ON lt.id = lc.term_id
LEFT JOIN course_activity_summary lca
    ON lca.person_course_id = lpc.id
LEFT JOIN submission_summary ls
    ON ls.person_course_id = lpc.id
LEFT JOIN grade_summary gr
    ON gr.person_course_id = lpc.id

WHERE
    lpc.row_deleted_time IS NULL
    AND lp.row_deleted_time IS NULL
    AND lc.row_deleted_time IS NULL
    AND lpc.enabled_ind
    AND lp.enabled_ind
    AND lc.enabled_ind

    -- ===== ACTIVITY LEVEL CRITERIA =====
    --AND COALESCE(lca.course_access_count, 0) = 0
    --AND COALESCE(ls.submission_count, 0) = 0
    --AND (gr.total_grade IS NULL OR gr.total_grade = 0)

    -- ===== COURSE / TERM FILTERS =====
    AND LOWER(lt.name) = LOWER('2025 Fall')              -- Filter to specific term
    -- AND LOWER(lc.course_number) LIKE LOWER('%test%')   -- Optional: filter by course pattern

ORDER BY
    lc.start_date,
    lc.course_number,
    student_name;