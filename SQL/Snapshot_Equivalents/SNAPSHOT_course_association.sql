/* ============================================================================
   Copyright (c) Blackboard Inc.
   All rights reserved.

   Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   Date:   2026-03-25

   Description:
     Generates Snapshot-SIS-like COURSE_ASSOCIATION extracts based on
     Illuminate data. Not an official Snapshot SIS export.

   Notes:
     - Illuminate does not supply an external association key or an
       association-level data source.
     - EXTERNAL_ASSOCIATION_KEY might be derrived if you have a known standard.  
        Example:  crs.stage['batch_uid']::TEXT || '--' || ih.stage['batch_uid']::TEXT
     - DATA_SOURCE_KEY is supplied as an integration-level constant.

   Disclaimer:
     Provided "AS IS" without warranty or support of any kind. Use at your
     own risk.
   ============================================================================
*/

SELECT
    'n/a'                               AS "EXTERNAL_ASSOCIATION_KEY",
    crs.stage['batch_uid']::TEXT        AS "EXTERNAL_COURSE_KEY",
    ih.stage['batch_uid']::TEXT         AS "EXTERNAL_NODE_KEY",
    'n/a'                               AS "DATA_SOURCE_KEY",

    CASE
        WHEN ihc.primary_ind = TRUE THEN 'Y'
        ELSE 'N'
    END                                 AS "IS_PRIMARY_ASSOCIATION"

FROM CDM_LMS.institution_hierarchy_course ihc
JOIN CDM_LMS.course crs
    ON crs.id = ihc.course_id
JOIN CDM_LMS.institution_hierarchy ih
    ON ih.id = ihc.institution_hierarchy_id
WHERE ihc.row_deleted_time IS NULL
ORDER BY
    crs.stage['batch_uid']::TEXT,
    CASE
        WHEN ihc.primary_ind = TRUE THEN 0
        ELSE 1
    END;