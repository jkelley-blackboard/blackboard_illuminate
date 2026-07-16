
/* ============================================================================
   Copyright (c) Blackboard Inc.
   All rights reserved.

   Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   Date:   2026-03-25

   Description:
     This code generates data extracts intended to be SIMILAR in structure
     and purpose to standard Snapshot SIS files, based on data available in
     Illuminate. These outputs are not official Snapshot SIS exports.

   Disclaimer:
     Provided "AS IS" without warranty or support of any kind. Use at your
     own risk.

   ============================================================================
*/

SELECT
    ih.STAGE:batch_uid::STRING          AS External_Node_Key,
    ih.NAME                             AS Name,
    parent.STAGE:batch_uid::STRING      AS Parent_Node_Key,
    ih.DESCRIPTION                      AS Description
FROM CDM_LMS.INSTITUTION_HIERARCHY ih
LEFT JOIN CDM_LMS.INSTITUTION_HIERARCHY parent
    ON ih.INSTITUTION_HIERARCHY_PARENT_ID = parent.ID
WHERE ih.ROW_DELETED_TIME IS NULL
ORDER BY
    ih.HIERARCHY_ID_SEQ;