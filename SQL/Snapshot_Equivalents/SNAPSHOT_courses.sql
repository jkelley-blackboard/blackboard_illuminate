/* ============================================================================
   Copyright (c) Blackboard Inc.
   All rights reserved.

   Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   Date:   2026-03-25

   Description:
     Generates Snapshot-SIS-like extracts based on available Illuminate data.
     Not an official Snapshot SIS export.

   Disclaimer:
     Provided "AS IS" without warranty or support of any kind. Use at your
     own risk.
   ============================================================================
*/

SELECT
    crs.stage['batch_uid']::TEXT        AS "EXTERNAL_COURSE_KEY",
    crs.course_number                  AS "COURSE_ID",
    crs.name                           AS "COURSE_NAME",
    crs.start_date                     AS "START_DATE",
    crs.end_date                       AS "END_DATE",
    crsparent.stage['batch_uid']::TEXT AS "PARENT_COURSE_KEY",
    crs.description                    AS "DESCRIPTION",
    'n/a'                              AS "TERM_KEY",
    CASE
        WHEN crs.available_ind = TRUE THEN 'Y'
        ELSE 'N'
    END                                AS "AVAILABLE_IND",
    CASE
        WHEN crs.enabled_ind = TRUE THEN 'enabled'
        ELSE 'disabled'
    END                                AS "ROW_STATUS",
    crs.stage:data_src_batchuid::TEXT  AS "DATA_SOURCE_KEY",
    tr.name                            AS "_TERM_NAME"   -- term batch_uid not available in Illuminate
FROM course crs
LEFT JOIN term tr
    ON tr.id = crs.term_id
LEFT JOIN course crsparent
    ON crsparent.id = crs.course_parent_id
WHERE crs.row_deleted_time IS NULL
  AND crs.stage:service_level = 'F'
ORDER BY
    CASE
        WHEN crs.course_parent_id IS NULL THEN 0
        ELSE 1
    END,
    crs.stage['batch_uid']::TEXT;