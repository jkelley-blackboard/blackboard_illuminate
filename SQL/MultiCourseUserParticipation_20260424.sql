-- ============================================================
-- User Participation Report (Extended)
-- Replicates the Blackboard "User Participation Report"
-- with additional engagement metrics from Illuminate.
--
-- Sources:
--   CDM_LMS.SUBMISSION       - test, discussion, and all submissions
--   CDM_LMS.SESSION_ACTIVITY - last login timestamp (system-wide)
--   CDM_LMS.COURSE_ACTIVITY  - last course access, duration, interactions
--
-- SUBMISSION.ITEM_TYPE values:
--   TEST             = resource/x-bb-asmt-test-link
--   DISCUSSION_FORUM = resource/x-bb-forumlink
--   JOURNAL          = resource/x-bb-journallink
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2026-04-24
-- © Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
--
-- Changes:
--   2026-07-28 - Added JOURNAL submission metrics; reordered output
--                columns to course, user, membership/engagement, then
--                total and per-item-type submission counts.
-- ============================================================

WITH

-- ============================================================
-- PARAMETERS — edit these values to filter the report
-- Set a value to NULL to disable that filter
-- ============================================================
params AS (
    SELECT
        -- Term filter: match on TERM.NAME; set NULL to include all terms
        '2026 Spring'::VARCHAR                  AS term_name

        -- Activity window for submissions, logins, and course access
      , '2026-01-01'::TIMESTAMP_LTZ             AS activity_after
      , CURRENT_TIMESTAMP()                     AS activity_before
),

-- ── Active student enrollments ──────────────────────────────
enrollments AS (
    SELECT
        pc.ID                                   AS person_course_id
      , pc.PERSON_ID
      , p.FIRST_NAME
      , p.LAST_NAME
      , p.STAGE:user_id::STRING                 AS user_id
      , p.STAGE:batch_uid::STRING               AS student_batch_uid
      , p.AVAILABLE_IND
      , c.COURSE_NUMBER                         AS course_id
      , c.STAGE:batch_uid::STRING               AS course_batch_uid
      , c.TERM_ID
    FROM CDM_LMS.PERSON_COURSE      pc
    JOIN CDM_LMS.PERSON             p   ON p.ID = pc.PERSON_ID
    JOIN CDM_LMS.COURSE             c   ON c.ID = pc.COURSE_ID
    JOIN CDM_LMS.TERM               t   ON t.ID = c.TERM_ID
    CROSS JOIN params
    WHERE pc.STUDENT_IND         = TRUE
      AND pc.ROW_DELETED_TIME    IS NULL
      AND p.ROW_DELETED_TIME     IS NULL
      AND c.ROW_DELETED_TIME     IS NULL
      AND t.ROW_DELETED_TIME     IS NULL
      AND (params.term_name IS NULL
           OR t.NAME = params.term_name)
),

-- ── Submission counts (single scan, conditional aggregation) ─
submissions AS (
    SELECT
        s.PERSON_COURSE_ID

      , MAX(CASE WHEN s.ITEM_TYPE = 'TEST'
            THEN s.SUBMITTED_TIME END)          AS most_recent_test_submission
      , COUNT(CASE WHEN s.ITEM_TYPE = 'TEST'
            THEN 1 END)                         AS total_test_submissions

      , MAX(CASE WHEN s.ITEM_TYPE = 'DISCUSSION_FORUM'
            THEN s.SUBMITTED_TIME END)          AS most_recent_discussion_submission
      , COUNT(CASE WHEN s.ITEM_TYPE = 'DISCUSSION_FORUM'
            THEN 1 END)                         AS total_discussion_submissions

      , MAX(CASE WHEN s.ITEM_TYPE = 'JOURNAL'
            THEN s.SUBMITTED_TIME END)          AS most_recent_journal_submission
      , COUNT(CASE WHEN s.ITEM_TYPE = 'JOURNAL'
            THEN 1 END)                         AS total_journal_submissions

      , MAX(s.SUBMITTED_TIME)                   AS most_recent_submission
      , COUNT(*)                                AS total_submissions

    FROM CDM_LMS.SUBMISSION         s
    CROSS JOIN params
    WHERE s.ROW_DELETED_TIME IS NULL
      AND (params.activity_after  IS NULL OR s.SUBMITTED_TIME >= params.activity_after)
      AND (params.activity_before IS NULL OR s.SUBMITTED_TIME <= params.activity_before)
    GROUP BY s.PERSON_COURSE_ID
),

-- ── Last system login (person-level) ────────────────────────
last_login AS (
    SELECT
        PERSON_ID
      , MAX(LAST_ACCESSED_TIME)                 AS last_login_time
    FROM CDM_LMS.SESSION_ACTIVITY
    CROSS JOIN params
    WHERE ROW_DELETED_TIME IS NULL
      AND (params.activity_after  IS NULL OR LAST_ACCESSED_TIME >= params.activity_after)
      AND (params.activity_before IS NULL OR LAST_ACCESSED_TIME <= params.activity_before)
    GROUP BY PERSON_ID
),

-- ── Course engagement (enrollment-level) ────────────────────
course_engagement AS (
    SELECT
        PERSON_COURSE_ID
      , MAX(LAST_ACCESSED_TIME)                 AS last_course_access
      , SUM(DURATION_SUM)                       AS total_duration_seconds
      , SUM(INTERACTION_CNT)                    AS total_interactions
    FROM CDM_LMS.COURSE_ACTIVITY
    CROSS JOIN params
    WHERE ROW_DELETED_TIME IS NULL
      AND (params.activity_after  IS NULL OR LAST_ACCESSED_TIME >= params.activity_after)
      AND (params.activity_before IS NULL OR LAST_ACCESSED_TIME <= params.activity_before)
    GROUP BY PERSON_COURSE_ID
)

-- ── Final output ────────────────────────────────────────────
SELECT
    -- Course fields
    e.COURSE_ID
  , e.COURSE_BATCH_UID

    -- User fields
  , e.FIRST_NAME
  , e.LAST_NAME
  , e.USER_ID
  , e.STUDENT_BATCH_UID

    -- Membership fields
  , CASE WHEN e.AVAILABLE_IND THEN 'Y' ELSE 'N' END   AS available_in_system
  , ll.LAST_LOGIN_TIME
  , ce.LAST_COURSE_ACCESS
  , COALESCE(ce.TOTAL_DURATION_SECONDS, 0)             AS total_time_in_course_seconds
  , ROUND(COALESCE(ce.TOTAL_DURATION_SECONDS, 0) / 60, 1) AS total_time_in_course_minutes
  , COALESCE(ce.TOTAL_INTERACTIONS, 0)                 AS total_interactions

    -- Total submissions (all item types)
  , s.MOST_RECENT_SUBMISSION
  , COALESCE(s.TOTAL_SUBMISSIONS, 0)                   AS total_submissions

    -- Submissions by item type
  , s.MOST_RECENT_TEST_SUBMISSION
  , COALESCE(s.TOTAL_TEST_SUBMISSIONS, 0)              AS total_test_submissions
  , s.MOST_RECENT_DISCUSSION_SUBMISSION
  , COALESCE(s.TOTAL_DISCUSSION_SUBMISSIONS, 0)        AS total_discussion_board_submissions
  , s.MOST_RECENT_JOURNAL_SUBMISSION
  , COALESCE(s.TOTAL_JOURNAL_SUBMISSIONS, 0)           AS total_journal_submissions

FROM enrollments                    e
LEFT JOIN submissions               s   ON s.PERSON_COURSE_ID  = e.PERSON_COURSE_ID
LEFT JOIN last_login                ll  ON ll.PERSON_ID         = e.PERSON_ID
LEFT JOIN course_engagement         ce  ON ce.PERSON_COURSE_ID  = e.PERSON_COURSE_ID

ORDER BY
    e.LAST_NAME
  , e.FIRST_NAME
  , e.COURSE_ID
;