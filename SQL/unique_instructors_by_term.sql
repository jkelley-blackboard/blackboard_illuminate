-- ============================================================
-- Unique Instructors for a Specific Term
--
-- Returns one row per unique person who holds an active instructor
-- membership (COURSE_ROLE = 'I', ACTIVE = 1) in any course belonging
-- to the specified term. Excludes soft-deleted memberships and
-- courses (a deleted person record implies a deleted membership, so
-- no separate PERSON.ROW_DELETED_TIME check is needed). An instructor
-- teaching multiple courses in the term is returned once.
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
  AND cor.row_deleted_time IS NULL       -- exclude deleted courses
  AND trm.name = params.term_name;
