-- =============================================================================
-- Classic/Original Courses and Organizations — Activity Volumetrics Report
-- =============================================================================
-- Purpose : Identify Original/Classic courses and orgs still seeing activity
--           to help prioritize Ultra migration outreach.
-- Scope   : DESIGN_MODE = 'C' (Classic), service_level IN ('C','F')
--           Excludes all soft-deleted records.
-- Notes   : Adjust activity_start offset in Params CTE to change lookback.
--           Adjust timezone in CONVERT_TIMEZONE calls to match your institution.
--           Activity tier thresholds (10/50) are a starting point — tune to taste.
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2026-05-15
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- =============================================================================

WITH

-- -----------------------------------------------------------------------------
-- Params
-- -----------------------------------------------------------------------------
-- Single location to control the activity lookback window.
-- Change the DATEADD offset (currently -60) to adjust the date range.
-- All downstream CTEs reference this via CROSS JOIN to avoid hardcoding dates.
-- -----------------------------------------------------------------------------
Params AS (
    SELECT
        DATEADD(day, -60, CURRENT_DATE()) AS activity_start,
        CURRENT_DATE()                    AS activity_end
),

-- -----------------------------------------------------------------------------
-- InstructorRows
-- -----------------------------------------------------------------------------
-- Identifies instructor-role enrollments for each course/org.
-- Includes COURSE_ROLE = 'I' (Instructor) and COURSE_ROLE_SOURCE_CODE IN
-- ('P','G') to capture platform-specific instructor role variants.
-- QUALIFY limits to 10 instructors per course (alphabetical by last name)
-- to prevent LISTAGG from blowing up on heavily-staffed courses.
-- Soft-deleted enrollments and persons are excluded.
-- -----------------------------------------------------------------------------
InstructorRows AS (
    SELECT
        pc.course_id,
        CONCAT(p.first_name, ' ', p.last_name) AS instructor_name,
        p.email                                 AS instructor_email
    FROM CDM_LMS.PERSON_COURSE pc
    JOIN CDM_LMS.PERSON p
        ON p.id = pc.person_id
    WHERE (pc.COURSE_ROLE = 'I' OR pc.COURSE_ROLE_SOURCE_CODE IN ('P', 'G'))
        AND pc.ROW_DELETED_TIME IS NULL
        AND p.ROW_DELETED_TIME IS NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pc.course_id ORDER BY p.last_name, p.first_name) <= 10
),

-- -----------------------------------------------------------------------------
-- AggregatedInstructors
-- -----------------------------------------------------------------------------
-- Collapses InstructorRows into one row per course, concatenating instructor
-- names and emails into semicolon-delimited strings for easy export/outreach.
-- A course with no instructor-role enrollments will return NULL here and
-- appear as NULL in the final output (see orphaned records filter option).
-- -----------------------------------------------------------------------------
AggregatedInstructors AS (
    SELECT
        course_id,
        LISTAGG(instructor_name,  '; ') WITHIN GROUP (ORDER BY instructor_name) AS instructors,
        LISTAGG(instructor_email, '; ') WITHIN GROUP (ORDER BY instructor_name) AS instructor_emails
    FROM InstructorRows
    GROUP BY course_id
),

-- -----------------------------------------------------------------------------
-- ActivityWindow
-- -----------------------------------------------------------------------------
-- Aggregates COURSE_ACTIVITY within the Params date window, joined to
-- PERSON_COURSE to obtain STUDENT_IND for each activity record.
-- Student (STUDENT_IND = 1) and non-student (STUDENT_IND = 0) volumetrics
-- are calculated separately using conditional SUM.
--
-- INTERACTION_CNT : number of discrete interactions in the window
-- DURATION_SUM    : total time-on-task in the window (units: seconds — verify
--                   against your Illuminate Data Dictionary)
--
-- Courses with no activity in the window will have no row here and will
-- appear as NULL/0 in the final output via the LEFT JOIN.
--
-- NOTE: This join assumes COURSE_ACTIVITY has a person_id column. Verify
-- this against your Illuminate Data Dictionary before running.
-- -----------------------------------------------------------------------------
ActivityWindow AS (
    SELECT
        ca.course_id,
        -- Student activity (STUDENT_IND = 1)
        SUM(CASE WHEN pc.STUDENT_IND = 1 THEN ca.INTERACTION_CNT ELSE 0 END) AS student_interaction_cnt,
        SUM(CASE WHEN pc.STUDENT_IND = 1 THEN ca.DURATION_SUM    ELSE 0 END) AS student_duration_sum,
        -- Non-student activity (STUDENT_IND = 0)
        SUM(CASE WHEN pc.STUDENT_IND = 0 THEN ca.INTERACTION_CNT ELSE 0 END) AS non_student_interaction_cnt,
        SUM(CASE WHEN pc.STUDENT_IND = 0 THEN ca.DURATION_SUM    ELSE 0 END) AS non_student_duration_sum,
        -- Most recent access across all users within the window
        MAX(ca.last_accessed_time)                                             AS last_access
    FROM CDM_LMS.COURSE_ACTIVITY ca
    JOIN CDM_LMS.PERSON_COURSE pc
        ON pc.course_id = ca.course_id
        AND pc.person_id = ca.person_id
        AND pc.ROW_DELETED_TIME IS NULL
    CROSS JOIN Params
    WHERE ca.last_accessed_time BETWEEN Params.activity_start AND Params.activity_end
    GROUP BY ca.course_id
)

-- =============================================================================
-- Final Output
-- =============================================================================
-- One row per course/org. Volumetric columns default to 0 (via COALESCE)
-- for courses with no activity in the window so they sort cleanly.
-- activity_tier is driven by student interactions only — non-student activity
-- is surfaced separately for context but does not affect tier assignment.
-- =============================================================================
SELECT
    c.course_number                                                     AS course_id,
    c.name                                                              AS course_or_org_name,
    CASE
        WHEN c.STAGE:service_level::string = 'C' THEN 'Organization'
        WHEN c.STAGE:service_level::string = 'F' THEN 'Course'
        ELSE c.STAGE:service_level::string
    END                                                                 AS record_type,
    t.name                                                              AS term_name,
    CASE
        WHEN c.ENABLED_IND = 0                                          THEN 'Disabled'
        WHEN c.ENABLED_IND = 1 AND c.AVAILABLE_TO_STUDENTS_IND = 0     THEN 'Unavailable'
        WHEN c.ENABLED_IND = 1 AND c.AVAILABLE_TO_STUDENTS_IND = 1     THEN 'Available'
        ELSE 'Unknown'
    END                                                                 AS availability,
    ai.instructors,
    ai.instructor_emails,
    TO_CHAR(
        DATE_TRUNC('MINUTE', CONVERT_TIMEZONE('America/Chicago', c.created_time)::TIMESTAMP_NTZ),
        'MM-DD-YYYY HH12:MI AM'
    )                                                                   AS created_time,
    TO_CHAR(
        DATE_TRUNC('MINUTE', CONVERT_TIMEZONE('America/Chicago', aw.last_access)::TIMESTAMP_NTZ),
        'MM-DD-YYYY HH12:MI AM'
    )                                                                   AS last_activity,

    -- Student volumetrics within window
    COALESCE(aw.student_interaction_cnt, 0)                             AS student_interaction_cnt,
    COALESCE(aw.student_duration_sum,    0)                             AS student_duration_sum,

    -- Non-student volumetrics within window
    COALESCE(aw.non_student_interaction_cnt, 0)                         AS non_student_interaction_cnt,
    COALESCE(aw.non_student_duration_sum,    0)                         AS non_student_duration_sum,

    -- Activity tier: based on student interactions only within the window.
    -- Thresholds (10/50) are a starting point — adjust based on observed data.
    -- 'Staff Only' flags courses where staff are active but no students are.
    CASE
        WHEN aw.course_id IS NULL                    THEN 'No Activity in Window'
        WHEN aw.student_interaction_cnt = 0          THEN 'Staff Only'
        WHEN aw.student_interaction_cnt < 10         THEN 'Low'
        WHEN aw.student_interaction_cnt < 50         THEN 'Moderate'
        ELSE                                              'High'
    END                                                                 AS activity_tier

FROM CDM_LMS.COURSE c
LEFT JOIN ActivityWindow aw
    ON c.id = aw.course_id
LEFT JOIN AggregatedInstructors ai
    ON c.id = ai.course_id
LEFT JOIN CDM_LMS.TERM t
    ON c.term_id = t.id
    AND t.ROW_DELETED_TIME IS NULL                                      -- Exclude soft-deleted terms

WHERE c.ROW_DELETED_TIME IS NULL                                        -- Exclude soft-deleted courses/orgs
    AND c.DESIGN_MODE = 'C'                                             -- Original/Classic view only
    AND c.STAGE:service_level::string IN ('C', 'F')                     -- Organizations and Courses only
    -- AND c.ENABLED_IND = 1                                            -- Uncomment to exclude disabled
    -- AND c.AVAILABLE_TO_STUDENTS_IND = 1                              -- Uncomment to limit to available only
    -- AND aw.course_id IS NOT NULL                                      -- Uncomment to exclude courses with no activity in window
    -- AND ai.instructors IS NOT NULL                                    -- Uncomment to exclude orphaned records

ORDER BY record_type, aw.student_interaction_cnt DESC NULLS LAST;