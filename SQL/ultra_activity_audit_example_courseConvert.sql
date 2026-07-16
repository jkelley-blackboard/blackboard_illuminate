-- ============================================================
-- Ultra Activity Audit — Example: Who Converted a Course to Ultra
-- Example of using the objectId value from Ultra Events
-- for audit activity investigations.
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2026-02-20
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================


SELECT
  per.stage:user_id::text AS username,
  cor.course_number AS bb_course_id,
  ue.data:objectId::text AS objectId,
  ue.event_type,
  ue.event_time,
  --ue.data::text   -- uncomment to examine the full data object
FROM CDM_TLM.ultra_events ue
JOIN CDM_LMS.person per
  ON per.stage:uuid::text = ue.data:userId::text
JOIN CDM_LMS.course cor
  ON '_' || cor.source_id || '_1' = ue.data:contextId::text
WHERE cor.course_number like '%'   --select course(s) by Blackboard course id
  AND per.stage:user_id::text like '%'   -- select user(s) by Blackboard user id
  AND ue.event_time BETWEEN '2026-02-01' AND '2026-02-20'  --select timeframe
  AND ue.data:objectId::text = 'course.conversion.statusBar.useUltra.button'  -- select the analytics_id tag for the button
ORDER BY ue.event_time DESC;