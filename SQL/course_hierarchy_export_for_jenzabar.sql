/* ============================================================================
   Copyright (c) Blackboard Inc.
   All rights reserved.

   Author: Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
   Date:   2026-07-29

   Description:
     Course-to-hierarchy export for Jenzabar to map institution hierarchy
     nodes. Returns each course's visible Course ID, name, and the external
     key of its PRIMARY institution hierarchy node.

   Notes:
     - COURSE_ID is COURSE.course_number, the Course ID visible in Blackboard
       Learn (not the Snowflake surrogate key).
     - PRIMARY_EXTERNAL_NODE_KEY is the institution hierarchy node's
       STAGE:batch_uid where INSTITUTION_HIERARCHY_COURSE.primary_ind = TRUE.
       A course can be associated with multiple nodes; only the primary
       association is returned here. See SNAPSHOT_course_association.sql
       for the full (non-primary-only) association list.
     - LEFT JOINs are used so courses with no primary hierarchy association
       still appear, with PRIMARY_EXTERNAL_NODE_KEY = NULL. Change to INNER
       JOINs if only mapped courses should be included.
     - service_level = 'F' restricts results to standard Full courses,
       matching SNAPSHOT_courses.sql. Remove/adjust if Organizations,
       Programs, etc. should also be included.

   Disclaimer:
     Provided "AS IS" without warranty or support of any kind. Use at your
     own risk.
   ============================================================================
*/

SELECT
    crs.course_number           AS "COURSE_ID",
    crs.name                    AS "COURSE_NAME",
    ih.stage['batch_uid']::TEXT AS "PRIMARY_EXTERNAL_NODE_KEY"
FROM CDM_LMS.course crs
LEFT JOIN CDM_LMS.institution_hierarchy_course ihc
    ON ihc.course_id = crs.id
    AND ihc.primary_ind = TRUE
    AND ihc.row_deleted_time IS NULL
LEFT JOIN CDM_LMS.institution_hierarchy ih
    ON ih.id = ihc.institution_hierarchy_id
    AND ih.row_deleted_time IS NULL
WHERE crs.row_deleted_time IS NULL
  AND crs.stage:service_level = 'F'
ORDER BY
    crs.course_number;
