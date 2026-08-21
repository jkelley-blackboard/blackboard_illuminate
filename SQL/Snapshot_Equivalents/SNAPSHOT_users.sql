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
    p.stage['batch_uid']::TEXT          AS "EXTERNAL_PERSON_KEY",
    p.stage['user_id']::TEXT            AS "USER_ID",
    p.stage['student_id']::TEXT         AS "STUDENT_ID",
    p.first_name                        AS "FIRST_NAME",
    p.last_name                         AS "LAST_NAME",
    p.email                             AS "EMAIL",
    p.institution_role_source_code      AS "INSTITUTION_ROLE",
    CASE
        WHEN p.system_role_source_code = 'N' THEN 'none'
        WHEN p.system_role_source_code = 'Z' THEN 'system_admin'
        WHEN p.system_role_source_code = 'O' THEN 'observer'
        WHEN p.system_role_source_code = 'U' THEN 'guest'
        ELSE 'lookup:' || p.system_role_source_code
    END                                 AS "SYSTEM_ROLE",   -- limited mapping
    CASE
        WHEN p.available_ind = TRUE THEN 'Y'
        ELSE 'N'
    END                                 AS "AVAILABLE_IND",
    CASE
        WHEN p.enabled_ind = TRUE THEN 'enabled'
        ELSE 'disabled'
    END                                 AS "ROW_STATUS",
    p.stage['data_src_batchuid']::TEXT  AS "DATA_SOURCE_KEY"
FROM CDM_LMS.person p
WHERE p.row_deleted_time IS NULL
ORDER BY
    p.stage['batch_uid']::TEXT;