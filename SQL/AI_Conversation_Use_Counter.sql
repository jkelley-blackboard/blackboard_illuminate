-- ============================================================
-- AI Conversation Use Counter
--
-- Click count and unique-assessment count for AI Conversations in
-- Blackboard Ultra, per course, from ai.chat.chat.controls.send
-- events in ULTRA_EVENTS.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2025-10-08
-- Updated : 2026-08-21 -- moved the AI-chat-send event id and the activity
--           start date into a params CTE at the top, matching the
--           convention established in AI_Conversations.sql.
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        'ai.chat.chat.controls.send'::VARCHAR AS ai_chat_send_object_id,
        '2025-08-01'::DATE                    AS activity_start_date   -- edit to change the reporting window
)

SELECT
    crs.course_number AS course_id,                          -- Course identifier
    COUNT(*) AS total_clicks,                                -- Total number of AI chat send events
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

WHERE ue.data:objectId::string = params.ai_chat_send_object_id -- Filter for AI chat send button clicks
  AND ue.event_time > params.activity_start_date

GROUP BY crs.course_number
ORDER BY total_clicks DESC;