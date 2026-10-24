-- ============================================================
-- AI Conversation Use by Assessment
--
-- Student message count, student count and first/last activity for
-- AI Conversations in Blackboard Ultra, per course and assessment,
-- from AI chat send events in ULTRA_EVENTS. Assessment-level version
-- of AI_Conversation_Use_Counter.sql; same event ids and filters.
--
-- The send button's analytics id was renamed in 2026 (old id last
-- seen 2026-06-23, new id from 2026-09-30), so both are counted.
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
-- Soft deletes: include_deleted_assessments and include_deleted_memberships
-- both default to FALSE (active only). An assessment that hasn't loaded into
-- COURSE_ITEM has no deletion time and is always kept. Memberships are
-- reduced to one per person per course (the live one if there is one,
-- otherwise the most recently deleted) before the role check, so a student
-- dropped and re-added isn't counted twice, and an instructor with an old
-- deleted student membership doesn't pass as a student.
--
-- Assessment name and deletion time come from CDM_LMS.COURSE_ITEM,
-- matched through stage:course_contents_pk1_list. They are NULL when
-- the assessment hasn't loaded into COURSE_ITEM yet.
--
-- Creator: COURSE_ITEM.PERSON_ID is not populated for these assessments,
-- so creator_user_id is the user on the earliest instructor setup event
-- (ai.chat.question.*) for the assessment, regardless of the reporting
-- window. That is the first person to open the AI Conversation editor
-- on it, which is normally the author. It is NULL when there are no
-- setup events, notably for assessments that arrived by course copy
-- (setup events stay with the original) and for ones built before
-- these events were captured.
--
-- Author  : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--           jeff.kelley@blackboard.com
-- Date    : 2026-10-21
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        'ai.chat.chat.controls.send'::VARCHAR             AS ai_chat_send_object_id,      -- through mid-2026
        'ai.chat.conversation.dialog.sendButton'::VARCHAR AS ai_chat_send_object_id_new,  -- from 2026-09-30
        '2025-08-01'::DATE                                AS activity_start_date,  -- edit to change the reporting window
        FALSE                                             AS include_deleted_assessments,  -- TRUE keeps assessments deleted in COURSE_ITEM
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
),

-- One row per assessment content id, so the name lookup can't duplicate events
assessment_names AS (
    SELECT
        '_' || f.value::string || '_1'                    AS assessment_id,       -- same format as the URL id
        MAX_BY(ci.name, ci.row_updated_time)              AS assessment_name,
        MAX_BY(ci.row_deleted_time, ci.row_updated_time)  AS assessment_deleted_time
    FROM CDM_LMS.course_item ci,
         LATERAL FLATTEN(input => ci.stage:course_contents_pk1_list) f
    WHERE ci.source_id LIKE 'QTI_ASI_DATA;%'                -- assessment rows
      AND ci.item_type IN ('TEST', 'ASSIGNMENT', 'SURVEY')
    GROUP BY 1
),

-- Earliest instructor setup event per assessment = creator (see header)
creators AS (
    SELECT
        ue.data:interactionContext:content:id::string     AS assessment_id,       -- same format as the URL id
        MIN_BY(ue.data:userId::string, ue.event_time)     AS creator_uuid,
        MIN(ue.event_time)                                AS first_setup_event
    FROM CDM_TLM.ultra_events ue
    WHERE ue.data:objectId::string LIKE 'ai.chat.question.%'  -- instructor setup/edit screen
      AND ue.data:interactionContext:content:id IS NOT NULL
    GROUP BY 1
),

student_sends AS (
    SELECT
        crs.course_number,
        REGEXP_SUBSTR(
            ue.data:interactionUrl::string,                  -- Extract assessment ID from interaction URL
            '/assessment/(_[0-9]+_[0-9]+)',                  -- Regex pattern for Ultra assessment ID
            1, 1, 'e', 1
        )                                                    AS assessment_id,
        per.id                                               AS person_id,
        ue.event_time
    FROM CDM_TLM.ultra_events ue
    CROSS JOIN params
    JOIN CDM_LMS.course crs
      ON crs.source_id = REGEXP_SUBSTR(
          ue.data:contextId::string, '[0-9]+'               -- Extract course source ID from contextId
      )
    JOIN CDM_LMS.person per
      ON per.stage['uuid']::text = ue.data:userId::text     -- ULTRA_EVENTS userId is the person uuid
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
)

SELECT
    s.course_number                 AS course_id,            -- Course identifier
    s.assessment_id,                                          -- Ultra assessment (course contents) ID
    n.assessment_name,                                        -- NULL if not yet in COURSE_ITEM
    n.assessment_deleted_time,                                -- Set if the assessment has since been deleted
    cp.stage['user_id']::text       AS creator_user_id,      -- First user to open the AI Conversation editor; NULL for copies
    COUNT(*)                        AS total_messages,       -- Student AI chat messages sent (one send event per message)
    COUNT(DISTINCT s.person_id)     AS students,             -- Distinct students who sent at least one message
    MIN(s.event_time)               AS first_message,
    MAX(s.event_time)               AS last_message
FROM student_sends s
CROSS JOIN params
LEFT JOIN assessment_names n
  ON n.assessment_id = s.assessment_id
LEFT JOIN creators c
  ON c.assessment_id = s.assessment_id
LEFT JOIN CDM_LMS.person cp
  ON cp.stage['uuid']::text = c.creator_uuid
WHERE params.include_deleted_assessments OR n.assessment_deleted_time IS NULL
GROUP BY s.course_number, s.assessment_id, n.assessment_name, n.assessment_deleted_time, cp.stage['user_id']::text
ORDER BY course_id, total_messages DESC;
