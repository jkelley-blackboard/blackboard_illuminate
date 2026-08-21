-- ============================================================
-- AI Conversations
--
-- Lists all instructors with at least one AI Conversation
-- assessment question in Blackboard Ultra, with a count of
-- AI-chat-type questions per instructor.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2025-09-21
-- Updated : 2026-08-21 -- quoted the questiontype literal instead of
--           relying on implicit text/number coercion, added the person
--           availability/enabled filters and the pc.active check now
--           standard elsewhere in this repo (see
--           unique_instructors_by_term.sql) so disabled/unavailable
--           accounts and disabled memberships don't show up as active
--           instructors, grouped by the instructor_email alias instead
--           of the bare column for consistency with instructor_id, and
--           moved the item_type/questiontype criteria that define "AI
--           Conversation question" into a params CTE at the top.
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        'TEST_QUESTION'::VARCHAR AS ai_item_type,
        '21'::VARCHAR            AS ai_chat_questiontype  -- Ultra bbmd_questiontype code for AI Conversation
)

SELECT
  per.stage['user_id']::text as instructor_id,
  per.email as instructor_email,
  SUM(CASE WHEN ci.stage['bbmd_questiontype']::text = params.ai_chat_questiontype THEN 1 ELSE 0 END) as ai_chat_quests

FROM CDM_LMS.course_item ci
  JOIN CDM_LMS.person_course pc on pc.course_id = ci.course_id
  JOIN CDM_LMS.person per on per.id = pc.person_id
  CROSS JOIN params

WHERE ci.row_deleted_time IS NULL       --no deleted questions
  AND ci.item_type = params.ai_item_type -- improves performance
  AND pc.course_role = 'I'         --instructors only
  AND pc.row_deleted_time is NULL  --no deleted instructors
  AND pc.active = 1                --available + enabled enrollments only
  AND per.available_ind = TRUE     --exclude unavailable person records
  AND per.enabled_ind = TRUE       --exclude disabled person records

GROUP BY instructor_id, instructor_email

HAVING ai_chat_quests > 0   --exclude instructors with no questions
