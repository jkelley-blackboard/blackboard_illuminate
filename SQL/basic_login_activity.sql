-- ============================================================
-- Basic User Activity Tracking — Last System Login
-- Source : CDM_LMS.SESSION_ACTIVITY
-- Grain  : Multiple rows per person over time; aggregated here
--          to one row per person (most recent login).
-- Purpose: Simplest possible "when did this user last log in"
--          query — system-wide, not scoped to a course.
-- See    : docs/Activity_Tracking_Guide.md
-- Author : jeff.kelley@blackboard.com
-- Provided as-is, without warranty or support.
-- ============================================================

SELECT
    p.id                                     AS person_id,
    p.stage:user_id::STRING                  AS bb_user_id,
    CONCAT(p.first_name, ' ', p.last_name)   AS full_name,
    MAX(sa.last_accessed_time)               AS last_login_time

FROM CDM_LMS.SESSION_ACTIVITY sa
JOIN CDM_LMS.PERSON p
    ON p.id = sa.person_id

WHERE sa.row_deleted_time IS NULL  -- exclude deleted session records
    AND p.row_deleted_time IS NULL -- exclude deleted persons

GROUP BY
    p.id,
    bb_user_id,
    full_name

ORDER BY last_login_time DESC NULLS LAST;
