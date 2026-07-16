/******************************************************************************
 * TITLE:        Course Item Deletion Audit Query
 * AUTHOR:       Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
 *               jeff.kelley@blackboard.com
 * DATE:         2026-02-20
 * RIGHTS:       (c) Blackboard Inc. All rights reserved.
 * WARRANTY:     This script is provided "AS IS" with no warranties, express
 *               or implied. Use at your own risk.
 * SUPPORT:      No support is provided. This script is unsupported and may
 *               require modification to suit your environment.
 * PURPOSE:      Retrieves course items and their deletion dates from the LMS
 *               database. Useful for auditing deleted content, identifying
 *               who created removed items, and tracking modification history.
 *               Filters are available for course ID and user ID.
 ******************************************************************************/

SELECT
    cr.course_number       AS bb_course_id,       -- Blackboard course identifier
    pr.stage:user_id::text AS created_by,          -- User ID of the item creator (from JSON stage field)
    ci.name                AS item_name,           -- Display name of the course item
    ci.item_type,                                  -- Type/category of the course item
    ci.created_time,                               -- Timestamp when the item was originally created
    ci.modified_time,                              -- Timestamp of the last modification
    DATE(ci.row_deleted_time) - 1 AS day_deleted   -- Deletion date (adjusted back 1 day to reflect true deletion date)
FROM CDM_LMS.course_item ci
    JOIN      CDM_LMS.course  cr ON cr.id = ci.course_id   -- Link item to its parent course
    LEFT JOIN CDM_LMS.person  pr ON pr.id = ci.person_id   -- Left join to retain items with no associated user
WHERE 1=1
    AND cr.course_number       LIKE '%'            -- [FILTER] Replace % with a course ID, e.g. 'CS101-%'
    --AND pr.stage:user_id::text LIKE '%'            -- [FILTER] Replace % with a user ID, e.g. '%jsmith%'
