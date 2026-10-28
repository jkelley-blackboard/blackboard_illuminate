-- ============================================================
-- Student Engagement by Term
--
-- One row per student enrollment in the courses of the selected terms,
-- with active days, last course access, total minutes in the course and
-- discussion post count. An Illuminate equivalent of the common Direct
-- Data Access pattern built on ods_aa_course_activity and msg_main.
--
-- Terms are selected by TERM.NAME (term_names CTE, case-insensitive).
-- Illuminate's TERM has no external term key (batch_uid): its STAGE
-- holds only data_src_pk1, and SOURCE_ID is the Learn pk1. See
-- mappings/TERM_Field_Reference.md. Courses with no term are excluded.
--
-- Population:
--   - Students only, via PERSON_COURSE.STUDENT_IND (role S without
--     Student Preview users).
--   - Disabled courses and disabled memberships are excluded (ENABLED_IND),
--     as are unavailable memberships and anything deleted.
--   - Unavailable courses and disabled/unavailable user accounts are
--     included. Uncomment the filters in WHERE to drop them.
--   - Students with no activity get NULL metrics, not 0.
--
-- Metrics (from CDM_LMS.COURSE_ACTIVITY and CDM_LMS.SUBMISSION):
--   - active_days: distinct calendar days with a course access, counted
--     in report_tz.
--   - last_access_date: in report_tz, without an offset. Each
--     COURSE_ACTIVITY row spans a stretch of course activity, from
--     FIRST_ACCESSED_TIME to LAST_ACCESSED_TIME. By default this is the
--     latest LAST_ACCESSED_TIME: the student's last recorded activity in
--     the course. To match DDA's ods_aa_course_activity
--     .initial_datetime_access (when the student last entered the
--     course), use the commented FIRST_ACCESSED_TIME version instead
--     (swap the two last_access_date lines in course_activity). That is
--     earlier by up to the length of the last stretch of activity.
--   - total_course_minutes: DURATION_SUM is seconds, divided by 60.
--   - post_count: DISCUSSION_FORUM submissions. This covers Original and
--     Ultra discussions; Ultra discussions are forumlink items too, and
--     lab2/forum_thread items carry no submissions (checked on a demo
--     tenant, 2026-10-28).
--   - No time window by default. Set activity_start / activity_end in
--     params to apply one to all metrics.
--
-- Time zones: CDM_LMS timestamps are TIMESTAMP_LTZ and display in the
-- session time zone (America/Los_Angeles on AWS US West accounts), so
-- every timestamp is converted to report_tz explicitly. Without that,
-- days are counted in whatever zone the session happens to use.
--
-- See    : docs/Activity_Tracking_Guide.md
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2026-10-28
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================

WITH params AS (
    SELECT
        NULL::TIMESTAMP_TZ          AS activity_start,  -- NULL = all history; give an offset,
        NULL::TIMESTAMP_TZ          AS activity_end,    --   e.g. '2026-09-01 00:00 -04:00'
        'America/New_York'::VARCHAR AS report_tz        -- zone for counting days and reporting times
),

-- TERM.NAME values, matched case-insensitively. Edit for your terms.
term_names (term_name) AS (
    SELECT * FROM VALUES ('2025 Fall'), ('2026 Spring')
),

students AS (
    SELECT
        pc.id                          AS person_course_id,
        t.name                         AS term_name,
        p.stage:user_id::STRING        AS user_id,
        p.stage:student_id::STRING     AS student_id,
        p.first_name,
        p.last_name,
        p.company,
        c.course_number                AS course_id,
        c.stage:batch_uid::STRING      AS external_course_key
    FROM CDM_LMS.PERSON_COURSE pc
    JOIN CDM_LMS.COURSE c
        ON c.id = pc.course_id
    JOIN CDM_LMS.PERSON p
        ON p.id = pc.person_id
    JOIN CDM_LMS.TERM t
        ON t.id = c.term_id
    WHERE LOWER(t.name) IN (SELECT LOWER(term_name) FROM term_names)
      AND t.row_deleted_time IS NULL
      AND c.enabled_ind                         -- drop disabled courses (NULL counts as disabled)
      AND c.row_deleted_time IS NULL
      -- AND c.available_ind                    -- drop unavailable courses
      AND pc.student_ind                        -- role S, without Student Preview users
      AND pc.available_ind
      AND pc.enabled_ind                        -- drop disabled memberships
      AND pc.row_deleted_time IS NULL
      AND p.row_deleted_time IS NULL
      -- AND p.enabled_ind AND p.available_ind  -- drop disabled/unavailable users
),

course_activity AS (
    SELECT
        ca.person_course_id,
        COUNT(DISTINCT DATE(CONVERT_TIMEZONE(params.report_tz, ca.first_accessed_time)))
                                           AS active_days,
        MAX(CONVERT_TIMEZONE(params.report_tz, ca.last_accessed_time))::TIMESTAMP_NTZ
                                           AS last_access_date,   -- last recorded activity in the course
        -- Alternative (see header): when the student last entered the
        -- course, as in DDA. To use it, comment out the two lines above
        -- and uncomment the two below.
        -- MAX(CONVERT_TIMEZONE(params.report_tz, ca.first_accessed_time))::TIMESTAMP_NTZ
        --                                 AS last_access_date,
        ROUND(SUM(ca.duration_sum) / 60, 2) AS total_course_minutes  -- DURATION_SUM is seconds
    FROM CDM_LMS.COURSE_ACTIVITY ca
    JOIN students s
        ON s.person_course_id = ca.person_course_id
    CROSS JOIN params
    WHERE ca.row_deleted_time IS NULL
      AND (params.activity_start IS NULL OR ca.first_accessed_time >= params.activity_start)
      AND (params.activity_end   IS NULL OR ca.first_accessed_time <  params.activity_end)
    GROUP BY ca.person_course_id
),

postings AS (
    SELECT
        sub.person_course_id,
        COUNT(*) AS post_count
    FROM CDM_LMS.SUBMISSION sub
    JOIN students s
        ON s.person_course_id = sub.person_course_id
    CROSS JOIN params
    WHERE sub.item_type = 'DISCUSSION_FORUM'
      AND sub.row_deleted_time IS NULL
      AND (params.activity_start IS NULL OR sub.submitted_time >= params.activity_start)
      AND (params.activity_end   IS NULL OR sub.submitted_time <  params.activity_end)
    GROUP BY sub.person_course_id
)

SELECT
    s.term_name,
    s.course_id,
    s.external_course_key,
    s.user_id,
    s.student_id,
    s.first_name,
    s.last_name,
    s.company,
    ca.active_days,
    ca.last_access_date,
    ca.total_course_minutes,
    po.post_count
FROM students s
LEFT JOIN course_activity ca
    ON ca.person_course_id = s.person_course_id
LEFT JOIN postings po
    ON po.person_course_id = s.person_course_id
ORDER BY
    s.term_name,
    s.course_id,
    s.user_id;
