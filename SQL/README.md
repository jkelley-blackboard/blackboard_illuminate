# SQL

Snowflake SQL queries against Blackboard Illuminate CDM data (`CDM_LMS`, `CDM_TLM`, etc.). Most files are written as editable examples — hardcoded filters, `{placeholder}` parameters, or a `params`/`Params` CTE near the top are meant to be adjusted for your own course, term, or date range before running.

See [Data_Monitoring/](Data_Monitoring/README.md) for CDM insert-freshness monitoring queries, and [Snapshot_Equivalents/](Snapshot_Equivalents/README.md) for Snapshot-SIS-style extracts built from Illuminate data.

## Activity & Participation

| File | Description |
|---|---|
| `basic_login_activity.sql` | Simplest starting point: a user's last system-wide login, from `SESSION_ACTIVITY`. |
| `basic_course_activity.sql` | Simplest starting point: one user's time and interactions in one course, from `COURSE_ACTIVITY`. |
| `basic_user_activity_summary.sql` | Combines the two above into a minimal per-course roster with login + activity totals. See `MultiCourseUserParticipation_20260424.sql` or `student_course_summary.sql` for more complete versions. |
| `single_user_weekly_course_activity.sql` | One user's weekly course access minutes and interactions across all their courses, for the current week. |
| `instructor_course_activity_summary.sql` | Per instructor/course/term access count, minutes, interactions, and first/last access dates. |
| `course_org_activity_check.sql` | Flags Classic/Original courses and organizations still seeing activity, to help prioritize Ultra migration outreach. Lookback window and activity-tier thresholds are tunable via a `Params` CTE. |
| `student_course_summary.sql` | Per-student, per-course summary combining access activity, submission counts, and grade summary. Adapted from the community `BBDN-BlackboardData-Queries/student-course-summary` script. |
| `MultiCourseUserParticipation_20260424.sql` | Extended version of Blackboard's "User Participation Report" — per enrollment, combines test/discussion submission counts, system-wide last login, and course access/duration/interaction stats. Filters live in a `params` CTE at the top. |

## Grading & Gradebook

| File | Description |
|---|---|
| `Term_Grade_Stats_20260202.sql` | Per-course grade metrics for a term: student counts, gradebook item counts, final-grade stats (max/min/avg/IQR), and instructor selection logic. |
| `Term_Grade_Stats_20260202_v2.sql` | Preferred over the file above — same report, with stricter roster filtering (excludes disabled, deleted, and preview-user enrollments). |
| `gradecenter_use_20230317.sql` | Per-instructor grading time/interactions alongside course student count, gradebook item count, and grades-recorded count (Grade Center usage). |
| `gradebook_extractor_20251219.sql` | Extracts gradebook column definitions and student roster/grade data for courses matching a batch_uid pattern. |
| `Item_extractor_20230221.sql` | For every enrollment in selected courses, extracts grade performance (percent, attempts, last attempt date) for one specific gradebook item matched by name. |
| `rubric-cell level results_20260424.sql` | One row per student attempt per rubric criterion cell (score, criterion name, gradebook column context). |

## Submissions & Course Content

| File | Description |
|---|---|
| `instructor_discussion_submissions.sql` | Instructor discussion-forum submissions for a specific course and date range. Parameterized with `{course_number}`, `{start_date}`, `{end_date}`. |
| `deleted_items_audit.sql` | Course item deletion audit — deleted items with creator, item type, timestamps, and deletion date. |
| `CTE_for_merged_enrollments.sql` | Reusable CTE that maps a student's enrollment in a merged/child course shell back to their parent-course enrollment. |
| `ally_instructor_fixes_by_course_user.sql` | Ally accessibility fixes made through the Instructor Feedback panel, aggregated by course and user, with fix counts, score-change stats, and a `report_open_count` column (course Accessibility Report opens — attached to existing fix rows, not a separate grain). Header includes caveats on ambiguous user ID formats worth reading before trusting results. See the [Ally Events Guide](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/docs/Ally_Events_Guide.md) for the full `event_type`/`DATA` catalog this query draws from. |
| `collaborate_recording_report_20220908.sql` | Collaborate recording metadata (name, link, duration, size, download/playback counts) in a format matching Blackboard's own Recording Report, for use with companion download/delete scripts. |

## Ultra Events & AI

| File | Description |
|---|---|
| `ultra_activity_audit_example_courseConvert.sql` | Example template for auditing a specific Ultra Events analytics tag — as written, who clicked "Convert to Ultra" in a course. |
| `ultra_activity_audit_example_itemDelete.sql` | Companion to `deleted_items_audit.sql` — that query only shows who *created* a deleted item, not who deleted it. Filters Ultra Events telemetry to the delete-confirmation click of either UI flow (single-item overflow menu, or bulk-edit), time-windowed against the overnight `CDM_LMS` snapshot, to identify the deleting user. |
| `AI_Conversations.sql` | Instructors who have at least one AI Conversation-type assessment question in an Ultra course. |
| `AI_Conversation_Use_Counter.sql` | Per-course count of AI Conversation "send" click events and distinct assessments used, from Ultra Events telemetry. |

---

Provided as-is, without support or warranty. See the repository [LICENSE](../LICENSE).
