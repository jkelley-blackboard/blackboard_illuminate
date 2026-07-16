-- Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--         jeff.kelley@blackboard.com
-- Date: 2025-10-08
-- (c) Blackboard Inc. All rights reserved.
-- Disclaimer: Provided as-is without support or warranty of any kind.
-- Purpose: Get a click count and unique assessment counts for AI Conversations in Blackboard Ultra

SELECT 
    crs.course_number AS course_id,                          -- Course identifier
    COUNT(*) AS total_clicks,                                -- Total number of AI chat send events
    COUNT(DISTINCT REGEXP_SUBSTR(
        ue.data:interactionUrl::string,                      -- Extract assessment ID from interaction URL
        '/assessment/(_[0-9]+_[0-9]+)',                      -- Regex pattern for Ultra assessment ID
        1, 1, 'e', 1
    )) AS unique_assessments                                 -- Count of distinct assessments interacted with

FROM CDM_TLM.ultra_events ue
JOIN CDM_LMS.course crs 
  ON crs.source_id = REGEXP_SUBSTR(
      ue.data:contextId::string, '[0-9]+'                   -- Extract course source ID from contextId
  )

WHERE ue.data:objectId::string = 'ai.chat.chat.controls.send' -- Filter for AI chat send button clicks
  AND ue.event_time > '2025-08-01'                            -- Only include events after August 1, 2025

GROUP BY crs.course_number
ORDER BY total_clicks DESC;