/* =============================================================================
   ALLY INSTRUCTOR-MADE ACCESSIBILITY FIXES — COURSE / USER SUMMARY
   =============================================================================

   Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
            jeff.kelley@blackboard.com
   Date   : 2026-07-16
   (c) Blackboard Inc. All rights reserved.
   Provided as-is without support or warranty of any kind.

   PURPOSE
   -------
   Answers: "Does Illuminate contain the user who made content accessibility
   fixes in courses?"

   Scope: fixes made THROUGH THE ALLY INSTRUCTOR FEEDBACK PANEL only. This
   does not capture accessibility improvements made by replacing/re-uploading
   content through normal LMS content authoring outside the Ally workflow.

   Grain: one row per (course, user), with total fix count, average net
   score change, and a breakdown of fix count by alteration type.

   SOURCES
   -------
   - CDM_TLM.ALLY_EVENTS  (event type: ALTERED_THROUGH_INSTRUCTOR_FEEDBACK)
       12-hour refresh for CDM_ALY scores, but ALLY_EVENTS lives in CDM_TLM
       and refreshes every 30 minutes, same cadence as ULTRA_EVENTS.
   - CDM_LMS.PERSON
   - CDM_LMS.COURSE

   KEY IDENTIFIER FORMATS (confirmed against sample data, not exhaustively
   validated against the full production table — see NOTES below)
   -------------------------------------------------------------------
   - DATA:userId       — two observed formats:
                           (a) "_874_1" style  -> numeric segment maps to
                               CDM_LMS.PERSON.SOURCE_ID
                           (b) 32-char hex UUID -> maps to
                               CDM_LMS.PERSON.STAGE:uuid
                         In the sample data, ALTERED_THROUGH_INSTRUCTOR_FEEDBACK
                         events only used format (a). The hex format (b) was
                         only seen on instructor-report-UI events
                         (ENGAGE_INSTRUCTOR_REPORT, etc.), not on the fix
                         event itself. The join below still checks both
                         formats defensively.
   - DATA:contextId    — "_10880_1" style; numeric segment maps to
                         CDM_LMS.COURSE.SOURCE_ID.
   - CDM_LMS.COURSE.STAGE:service_level — "F" = course, "C" = organization.
                         Surfaced below as course_or_org_type for readability;
                         confirm F/C are the only two values present in your
                         instance before relying on this mapping being
                         exhaustive.

   NOTES / OPEN ITEMS TO VALIDATE BEFORE PRESENTING RESULTS
   ----------------------------------------------------------
   1. Confirm CDM_LMS.PERSON.SOURCE_ID stores the BARE NUMBER (e.g. "874")
      and not the full "_874_1" string. If it stores the full string, drop
      the REGEXP_SUBSTR extraction on raw_user_id and join on the raw value
      directly.
   2. Confirm match rates are non-trivial by checking id_format counts and
      NULL join results before trusting this report's totals:
        SELECT id_format, COUNT(*), COUNT(username) FROM ... GROUP BY 1
   3. BeginPdfAutoTagging and ApprovePdfAutoTagging may represent two ends
      of one workflow (kick off vs. approve AI tagging) rather than two
      independent fixes. If BeginPdfAutoTagging rows do not carry a
      meaningful scoreChangeType, consider excluding them from
      total_fix_count to avoid double-counting effort.
   4. avg_score_improvement is a NET average — it includes fixes where
      scoreChangeType = 'WORSE' or 'SAME' alongside 'BETTER'. This is
      intentional (an honest "did this help" number) but should be
      described to stakeholders as "average net change," not "average
      size of improvement."

   DISCLAIMER
   ----------
   Provided as-is, without support or warranty of any kind, express or
   implied. Validate identifier join logic and match rates against your
   own production data before relying on these results for reporting,
   billing, compliance, or any other downstream decision. Column names,
   refresh cadences, and identifier formats reflect Illuminate schema
   knowledge current as of the time this query was written and may change
   without notice in future Illuminate releases.
   ============================================================================= */

WITH params AS (
    -- Activity date range — adjust as needed for each run.
    SELECT
        '2026-01-01'::DATE AS start_date,
        '2026-07-14'::DATE AS end_date
),

ally_fixes AS (
    -- Raw ALTERED_THROUGH_INSTRUCTOR_FEEDBACK events within the date window.
    SELECT
        DATA:userId::STRING                AS raw_user_id,
        DATA:contextId::STRING             AS raw_course_context_id,
        DATA:result:alterationType::STRING AS alteration_type,
        DATA:result:scoreBefore::FLOAT     AS score_before,
        DATA:result:scoreAfter::FLOAT      AS score_after
    FROM CDM_TLM.ALLY_EVENTS, params
    WHERE EVENT_TYPE = 'ALTERED_THROUGH_INSTRUCTOR_FEEDBACK'
      AND EVENT_TIME::DATE BETWEEN params.start_date AND params.end_date
),

classified AS (
    -- Classify userId format and extract numeric segments for joining.
    SELECT
        *,
        CASE
            WHEN raw_user_id RLIKE '^_[0-9]+_[0-9]+$' THEN 'source_id'
            WHEN LENGTH(raw_user_id) = 32             THEN 'uuid'
            ELSE 'unknown'
        END AS id_format,
        REGEXP_SUBSTR(raw_user_id, '[0-9]+')           AS extracted_numeric_id,
        REGEXP_SUBSTR(raw_course_context_id, '[0-9]+') AS extracted_course_id
    FROM ally_fixes
),

joined AS (
    -- Resolve person and course dimension attributes.
    SELECT
        c.*,
        co.COURSE_NUMBER,
        co.ID                          AS course_id,
        p.STAGE:user_id::STRING        AS username,
        CASE co.STAGE:service_level::STRING
            WHEN 'F' THEN 'Course'
            WHEN 'C' THEN 'Organization'
            ELSE co.STAGE:service_level::STRING  -- unexpected value; pass through raw
        END                             AS course_or_org_type
    FROM classified c
    LEFT JOIN CDM_LMS.PERSON p
        ON (c.id_format = 'source_id' AND p.SOURCE_ID = c.extracted_numeric_id)
        OR (c.id_format = 'uuid'      AND p.STAGE:uuid::STRING = c.raw_user_id)
    LEFT JOIN CDM_LMS.COURSE co
        ON co.SOURCE_ID = c.extracted_course_id
)

-- Final rollup: one row per course/user, with total and per-type fix counts.
SELECT
    COURSE_NUMBER AS bb_course_id,
    course_or_org_type,
    username,
    COUNT(*)                                                      AS total_fix_count,
    AVG(score_after - score_before)::NUMBER(10,3)                AS avg_score_improvement,

    -- Per-alteration-type breakdown (all 13 confirmed values as of this
    -- writing; add/remove columns if new alterationType values appear).
    COUNT_IF(alteration_type = 'AddFile')                         AS add_file_count,
    COUNT_IF(alteration_type = 'WysiwygFixApplied')               AS wysiwyg_fix_applied_count,
    COUNT_IF(alteration_type = 'EditAlternativeDescription')      AS edit_alternative_description_count,
    COUNT_IF(alteration_type = 'RemoveFile')                      AS remove_file_count,
    COUNT_IF(alteration_type = 'PdfFixApplied')                   AS pdf_fix_applied_count,
    COUNT_IF(alteration_type = 'UnsetDecorative')                 AS unset_decorative_count,
    COUNT_IF(alteration_type = 'AddLibraryReference')             AS add_library_reference_count,
    COUNT_IF(alteration_type = 'RemoveAlternativeDescription')    AS remove_alternative_description_count,
    COUNT_IF(alteration_type = 'SetDecorative')                   AS set_decorative_count,
    COUNT_IF(alteration_type = 'AddAlternativeDescription')       AS add_alternative_description_count,
    COUNT_IF(alteration_type = 'RemoveLibraryReference')          AS remove_library_reference_count,
    COUNT_IF(alteration_type = 'EditLibraryReference')            AS edit_library_reference_count,
    COUNT_IF(alteration_type = 'BeginPdfAutoTagging')             AS begin_pdf_auto_tagging_count,
    COUNT_IF(alteration_type = 'ApprovePdfAutoTagging')           AS approve_pdf_auto_tagging_count

FROM joined
GROUP BY COURSE_NUMBER, course_or_org_type, username
ORDER BY total_fix_count DESC;
