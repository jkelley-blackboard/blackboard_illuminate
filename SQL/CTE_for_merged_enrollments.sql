
/*
================================================================================
 Description:    Example CTE (enrollment map) to get child course information on merged courses.
 Author:         Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
                 jeff.kelley@blackboard.com
 Date:           2025-11-20
 (c) Blackboard Inc. All rights reserved.
 Provided as-is without support or warranty of any kind.
================================================================================
*/

WITH enrollment_map AS (
    SELECT
     parentpc.id AS parent_person_course_id,  --join on this

     -- return any of these        
     pc.course_id AS child_course_id,
     c.course_number AS child_course_number,
     c.stage:batchUid::string AS child_batch_uid

    FROM cdm_lms.person_course pc
    INNER JOIN cdm_lms.course c ON pc.course_id = c.id
    INNER JOIN cdm_lms.person p ON pc.person_id = p.id

    -- Parent course for the merged shell
    INNER JOIN cdm_lms.course parentc ON parentc.id = c.course_parent_id

    -- Parent enrollment (this is asssumed by same user with enrollment in parent)
    INNER JOIN cdm_lms.person_course parentpc
        ON parentpc.course_id = parentc.id
        AND parentpc.person_id = pc.person_id

    WHERE  pc.course_role_source_code IN ('S') -- Students only
        AND c.course_parent_id IS NOT NULL  --CTE only looks at child courses
        AND pc.enabled_ind = TRUE  -- Valid, non-deleted child enrollment
        AND pc.row_deleted_time IS NULL
        -- for large data set apply addtional filters on the set of children  (ex. c.created_time)
)
SELECT
    p.stage:user_id::string as username,
    CASE
      WHEN em.child_course_number IS NULL THEN FALSE
      ELSE TRUE
      END AS merged_enrollment_ind,
    CASE 
      WHEN em.child_course_number IS NULL THEN c.course_number
      ELSE em.child_course_number
      END AS reporting_courseId,
    c.course_number AS parent_courseId
    

FROM cdm_lms.course c
  JOIN cdm_lms.person_course pc on pc.course_id = c.id
  JOIN cdm_lms.person p on p.id = pc.person_id
  LEFT JOIN enrollment_map em on em.parent_person_course_id = pc.id

WHERE c.course_parent_id IS NULL
