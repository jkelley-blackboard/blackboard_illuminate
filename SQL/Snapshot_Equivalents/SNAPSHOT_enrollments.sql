/* ============================================================================
   Copyright (c) Blackboard Inc.
   All rights reserved.

   Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   Date:   2026-03-25

   Description:
     Generates Snapshot-SIS-like COURSE_MEMBERSHIP extracts based on available
     Illuminate data. Not an official Snapshot SIS export.
     
     Note that Illuminate doesn't hold the data_source_key for membership records

   Disclaimer:
     Provided "AS IS" without warranty or support of any kind. Use at your
     own risk.
   ============================================================================
*/

SELECT
    crs.stage['batch_uid']::TEXT  AS "EXTERNAL_COURSE_KEY",
    per.stage['batch_uid']::TEXT  AS "EXTERNAL_PERSON_KEY",
    CASE
        WHEN pcr.course_role_source_code = 'S' THEN 'student'
        WHEN pcr.course_role_source_code = 'P' THEN 'instructor'
        WHEN pcr.course_role_source_code = 'G' THEN 'guest'
        ELSE 'lookup:' || pcr.course_role_source_code
    END                           AS "ROLE",   --limited mapping
    CASE
        WHEN pcr.available_ind = TRUE THEN 'Y'
        ELSE 'N'
    END                           AS "AVAILABLE_IND",
    CASE
        WHEN pcr.enabled_ind = TRUE THEN 'enabled'
        ELSE 'disabled'
    END                           AS "ROW_STATUS"
FROM CDM_LMS.person_course pcr
JOIN CDM_LMS.person per
    ON per.id = pcr.person_id
JOIN CDM_LMS.course crs
    ON crs.id = pcr.course_id
WHERE pcr.row_deleted_time IS NULL
  AND crs.stage['service_level']::TEXT = 'F'  --only courses
ORDER BY
    crs.stage['batch_uid']::TEXT,
    per.stage['batch_uid']::TEXT;