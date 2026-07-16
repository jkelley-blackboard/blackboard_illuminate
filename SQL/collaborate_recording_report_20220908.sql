-- ============================================================
-- Collaborate Recording Report
-- Extract Recording info in a format similar to the Recording Report
-- https://help.blackboard.com/Collaborate/Ultra/Manager/Recording_Report
-- for use with download/delete python scripts
-- Added course information and instructor usernames.
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2022-09-08
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
-- ============================================================


SELECT DISTINCT 
    cou.course_number as course_id,
    cou.name as course_name,
    instructors.id_list as instructors,
    cou.row_deleted_time as course_deleted_on,
    TO_CHAR(clm.created_time,'%m/%d/%Y %H:%M') as "RecordingCreated",  --local time zone (vs UTC)
    'https://us.bbcollab.com/recording/'||
        clm.stage['media_uid']::text as "RecordingLink",
    'LTI_KEY' as "SessionOwner",                                --put your LTI Key here
    clr.name as "SessionName",
    clm.name as "RecordingName",
    cou.course_number as "ContextIdentifier",
    cou.name as "ContextName",   
    clm.stage['media_uid']::text as recording_uid,
    (clm.duration/60000) as duration_in_minutes,
    (clm.size*0.000000001) as size_in_gb,
    clm.download_cnt as download_count,
    clm.last_download_time as last_downloaded,
    clm.playback_cnt as playback_count,
    clm.last_playback_time as last_playedback,
    clm.public_access_ind as public_ind,
    clm.created_time

FROM cdm_clb.media as clm
  JOIN cdm_clb.room as clr on clr.id = clm.room_id
  JOIN cdm_clb.session as cls on cls.room_id = clr.id
  JOIN cdm_map.course_room as cmc on cmc.clb_room_id = clr.id
  JOIN cdm_lms.course as cou on cou.id = cmc.lms_course_id
  -- instructors
  LEFT JOIN (
    SELECT
      pc.course_id
      ,LISTAGG(per.stage['user_id']::text, ';') id_list
    FROM CDM_LMS.person_course pc
	LEFT JOIN CDM_LMS.person per on per.id = pc.person_id
    WHERE pc.course_role_source_code = 'P'
    GROUP BY pc.course_id
	) instructors on cou.id = instructors.course_id

WHERE clm.media_category = 'R'
  AND clm.row_deleted_time IS NULL                                --don't include already deleted recordings
  AND clm.created_time < '2019-01-01'

ORDER BY created_time ASC

-- LIMIT 10