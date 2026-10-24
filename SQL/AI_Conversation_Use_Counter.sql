-- ============================================================
-- AI Conversation Use Counter
--
-- Student message count and unique-assessment count for AI
-- Conversations in Blackboard Ultra, per course, from AI chat send
-- events in ULTRA_EVENTS. The send button's analytics id was renamed
-- in 2026 (old id last seen 2026-06-23, new id from 2026-09-30), so
-- both are counted.
--
-- Student Preview exclusion: an instructor using Student Preview fires
-- the same send events a student does, but ULTRA_EVENTS logs them in
-- one of two ways:
--   1. Under the INSTRUCTOR's own userId. These are removed by
--      requiring a student (course_role = 'S') membership in the
--      course.
--   2. Under the <instructor>_previewuser account. That account has a
--      student membership, so it passes the role check and is removed
--      by the user_id filter instead.
-- Both filters are needed; either one alone leaves preview activity in.
-- Side effect: events from a user whose membership hasn't loaded into
-- CDM_LMS yet are also dropped, so very recent activity may undercount.
--
-- Soft deletes: include_deleted_memberships defaults to FALSE (active
-- enrollments only). Memberships are reduced to one per person per course
-- (the live one if there is one, otherwise the most recently deleted)
-- before the role check, so a student dropped and re-added isn't counted
-- twice, and an instructor with an old deleted student membership doesn't
-- pass as a student.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2025-10-08
-- Updated : 2026-08-21 -- moved the AI-chat-send event id and the activity
--           start date into a params CTE at the top, matching the
--           convention established in AI_Conversations.sql.
-- Updated : 2026-10-21 -- added the new send id
--           ai.chat.conversation.dialog.sendButton alongside
--           ai.chat.chat.controls.send.
-- Updated : 2026-10-21 -- excluded Student Preview activity (see above)
--           by joining the event's userId to a student membership in
--           the course and dropping _previewuser accounts; renamed
--           total_clicks to total_messages.
-- Updated : 2026-10-24 -- added include_deleted_memberships and reduced
--           memberships to one per person per course (see above).
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        'ai.chat.chat.controls.send'::VARCHAR             AS ai_chat_send_object_id,      -- through mid-2026
        'ai.chat.conversation.dialog.sendButton'::VARCHAR AS ai_chat_send_object_id_new,  -- from 2026-09-30
        '2025-08-01'::DATE                                AS activity_start_date,  -- edit to change the reporting window
        FALSE                                             AS include_deleted_memberships   -- TRUE keeps dropped/removed enrollments
),

-- One membership per person per course, live first (see header)
memberships AS (
    SELECT pc.person_id, pc.course_id, pc.course_role
    FROM CDM_LMS.person_course pc
    CROSS JOIN params
    WHERE params.include_deleted_memberships OR pc.row_deleted_time IS NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY pc.course_id, pc.person_id
                               ORDER BY pc.row_deleted_time DESC NULLS FIRST) = 1
)

SELECT
    crs.course_number AS course_id,                          -- Course identifier
    COUNT(*) AS total_messages,                              -- Student AI chat messages sent (one send event per message)
    COUNT(DISTINCT REGEXP_SUBSTR(
        ue.data:interactionUrl::string,                      -- Extract assessment ID from interaction URL
        '/assessment/(_[0-9]+_[0-9]+)',                      -- Regex pattern for Ultra assessment ID
        1, 1, 'e', 1
    )) AS unique_assessments                                 -- Count of distinct assessments interacted with

FROM CDM_TLM.ultra_events ue
CROSS JOIN params
JOIN CDM_LMS.course crs
  ON crs.source_id = REGEXP_SUBSTR(
      ue.data:contextId::string, '[0-9]+'                   -- Extract course source ID from contextId
  )
JOIN CDM_LMS.person per
  ON per.stage['uuid']::text = ue.data:userId::text         -- ULTRA_EVENTS userId is the person uuid
JOIN memberships pc
  ON pc.person_id = per.id
 AND pc.course_id = crs.id

WHERE ue.data:objectId::string IN (params.ai_chat_send_object_id,
                                   params.ai_chat_send_object_id_new) -- Filter for AI chat send button clicks
  AND ue.event_time > params.activity_start_date
  -- Student Preview exclusion, part 1: preview clicks logged under the
  -- instructor's userId join to an instructor membership, not 'S'.
  AND pc.course_role = 'S'
  -- Student Preview exclusion, part 2: preview clicks logged under the
  -- preview account itself (user_id ends in _previewuser).
  AND per.stage['user_id']::text NOT ILIKE '%previewuser'

GROUP BY crs.course_number
ORDER BY total_messages DESC;
