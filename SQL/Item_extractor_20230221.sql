/*
  Grade Item Extract
    for every enrollment in select courses
    provides grade performance and date for item selected by name
    if the item doesn't exist or the user has no attempt/grade returns null row

  Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
           jeff.kelley@blackboard.com
  Date   : 2023-02-21
  (c) Blackboard Inc. All rights reserved.
  Provided as-is without support or warranty of any kind.
*/

SELECT
  term.name AS term,
  crs.stage['batch_uid']::string AS external_course_key,
  crs.course_number AS course_id,
  per.stage['batch_uid']::string AS external_person_key,
  per.stage['user_id']::string AS user_id,
  grades.item_name,
  grades.percent,
  grades.attempts,
  grades.last_attempt
  
FROM CDM_LMS.person_course pcr
   JOIN CDM_LMS.person per ON per.id = pcr.person_id
   JOIN CDM_LMS.course crs ON crs.id = pcr.course_id
   LEFT JOIN CDM_LMS.term term ON term.id = crs.term_id
   LEFT JOIN (                     --change to regular JOIN to filter out nulls                   
     SELECT                        --subquery to get grade data
       grd.person_course_id,
       gbk.name AS item_name,
       ROUND(grd.normalized_score,3) AS percent,
       grd.attempted_cnt AS attempts,
       grd.last_attempted_time AS last_attempt
     FROM CDM_LMS.grade grd
       JOIN CDM_LMS.gradebook gbk ON gbk.id = grd.gradebook_id
     WHERE gbk.name = 'Test 1: Solar System'      --the name of the item accross courses
       AND NOT gbk.deleted_ind
       AND grd.row_deleted_time IS NULL           --this should filter out all deleted courses, users and enrollments
     ) grades on grades.person_course_id = pcr.id

WHERE pcr.enabled_ind                         --filter out disabled (dropped) enrollements
  AND per.stage['user_id']::string NOT LIKE '%_previewuser'
  AND pcr.course_role_desc = 'Student'       
  AND crs.course_number like '%BIO101%'      --course ID filter
  AND term.name = '2023 Spring'              --term name filter

ORDER BY crs.course_number DESC
