-- ============================================================
-- Unique Instructors for a Specific Term
--
-- Returns one row per unique person who holds an active instructor
-- membership (COURSE_ROLE = 'I', ACTIVE = 1) in an enabled course
-- belonging to the specified term, and whose person record is both
-- available and enabled. Neither PERSON nor COURSE has a derived
-- ACTIVE column (unlike PERSON_COURSE), so their AVAILABLE_IND/
-- ENABLED_IND flags are checked explicitly; course availability is
-- ignored deliberately since it doesn't affect instructor access.
-- Excludes soft-deleted memberships (a deleted person or course
-- implies a deleted membership, so no separate PERSON/COURSE.
-- ROW_DELETED_TIME check is needed). An instructor teaching multiple
-- courses in the term is returned once.
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2026-08-21
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT '2026 Spring'::VARCHAR AS term_name   -- edit to the target term
)

SELECT DISTINCT
    per.stage:student_id::STRING AS student_id,
    per.stage:user_id::STRING    AS user_id,
    per.stage:batch_uid::STRING  AS batch_uid,
    per.email                    AS email

FROM cdm_lms.person_course pc
JOIN cdm_lms.person per ON per.id = pc.person_id
JOIN cdm_lms.course cor ON cor.id = pc.course_id
JOIN cdm_lms.term   trm ON trm.id = cor.term_id
CROSS JOIN params

WHERE pc.course_role       = 'I'         -- instructors only
  AND pc.active             = 1          -- available + enabled enrollments only
  AND pc.row_deleted_time  IS NULL       -- exclude deleted memberships
  AND per.available_ind     = TRUE       -- exclude unavailable person records
  AND per.enabled_ind       = TRUE       -- exclude disabled person records
  AND cor.enabled_ind       = TRUE       -- exclude disabled courses (availability doesn't matter here)
  AND trm.name = params.term_name;
