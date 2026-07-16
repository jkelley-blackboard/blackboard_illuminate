-- Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--         jeff.kelley@blackboard.com
-- Date: 2025-09-21
-- (c) Blackboard Inc. All rights reserved.
-- Disclaimer: Provided as-is without support or warranty of any kind.
-- Purpose: List all instructors with at least one AI Conversation assessment in Blackboard Ultra


SELECT
  per.stage['user_id']::text as instructor_id,
  per.email as instructor_email,
  SUM(CASE WHEN ci.stage['bbmd_questiontype']::text = 21 THEN 1 ELSE 0 END) as ai_chat_quests

FROM CDM_LMS.course_item ci
  JOIN CDM_LMS.person_course pc on pc.course_id = ci.course_id
  JOIN CDM_LMS.person per on per.id = pc.person_id

WHERE ci.row_deleted_time IS NULL  --no deleted questions
  AND ci.item_type = 'TEST_QUESTION' -- improves performance
  AND pc.course_role = 'I'         --instructors only
  AND pc.row_deleted_time is NULL  --no deleted instructors

GROUP BY instructor_id, email

HAVING ai_chat_quests > 0   --exclude instructors with no questions
