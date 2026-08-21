[← Home](.)

# What You Can Find in Illuminate

> **Disclaimer:** Nothing on this page supersedes the [official Blackboard Illuminate documentation](https://help.blackboard.com/Anthology_Illuminate) or any agreement your institution has with Blackboard. Delivered-report descriptions below are summarized from [Illuminate Reporting](https://help.anthology.com/illuminate/en/illuminate-reporting.html) at a category level — verify the exact fields/filters of any specific delivered report against its own help page before assuming parity with a SQL example here. SQL-side notes are inferred from working queries in this repo, not copied from the Data Dictionary.

---

## Two ways to get data out of Illuminate

Illuminate gives you data in two layers, and this page maps both together, domain by domain:

1. **Delivered reports** — pre-built, no SQL required. Organized by Illuminate into three pillars (**Learning**, **Teaching**, **Leading**), plus **Custom Reports** (build-your-own dashboards) and **Data Q&A** (ask questions in plain language). If a delivered report already answers your question, use it — it's maintained by Anthology and doesn't require Snowflake access.
2. **Direct CDM access via SQL** — the [`SQL/`](https://github.com/jkelley-blackboard/blackboard_illuminate/tree/main/SQL) examples in this repo. Reach for these when you need something a delivered report doesn't offer: a non-standard grain, a cross-CDM join, a specific term/course scope, or a metric the delivered reports simply don't expose (e.g. per-instructor grading activity, not just per-course).

The sections below group both layers by the question they answer, not by which CDM schema or report menu they happen to live in.

---

## Student Activity & Engagement

**Delivered reports:** Student Engagement Report, Student Summary Report (*Learning* pillar).

**What the SQL examples add:** finer control over grain (system-wide vs. per-course vs. weekly), and the ability to combine activity with submissions/grades/login in one roster rather than switching reports.

| File | Question it answers |
|---|---|
| [`basic_login_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_login_activity.sql) | When did this person last log in, system-wide? |
| [`basic_course_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_course_activity.sql) | How much time/interaction did this person log in one course? |
| [`basic_user_activity_summary.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_user_activity_summary.sql) | Minimal roster combining the two above |
| [`single_user_weekly_course_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/single_user_weekly_course_activity.sql) | One user's weekly access minutes/interactions, current week |
| [`unique_instructors_by_term.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/unique_instructors_by_term.sql) | Who are the active instructors this term? (dedup across courses) |
| [`instructor_course_activity_summary.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/instructor_course_activity_summary.sql) | Per instructor/course/term: access count, minutes, interactions, first/last access |
| [`student_course_summary.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/student_course_summary.sql) | Per-student, per-course: activity + submissions + grade summary combined |
| [`MultiCourseUserParticipation_20260424.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/MultiCourseUserParticipation_20260424.sql) | Blackboard's "User Participation Report," extended: submissions + login + activity per enrollment |

**Core tables:** `CDM_LMS.SESSION_ACTIVITY` (system-wide login), `CDM_LMS.COURSE_ACTIVITY` (per-enrollment time/interactions). See the [Activity Tracking Guide](Activity_Tracking_Guide) for column-level detail and the "always aggregate, never assume one row" gotcha.

---

## Grading & Assessment

**Delivered reports:** Student Performance and Grades Report (*Learning*), Assessment and Grading Report (*Teaching*).

**What the SQL examples add:** per-instructor grading *activity* (not just grade values) — including a proxy that works in Ultra courses, where the delivered report's likely activity-tracking signal has the same Original-only blind spot found in `CDM_LMS.COURSE_TOOL_ACTIVITY` (see Gotchas below) — plus rubric-cell-level detail and single-item lookups across a course set.

| File | Question it answers |
|---|---|
| [`Term_Grade_Stats_20260202_v2.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/Term_Grade_Stats_20260202_v2.sql) | Per-course grade metrics for a term: counts, gradebook item counts, final-grade stats (max/min/avg/IQR) |
| [`instructor_gradebook_use_by_term.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/instructor_gradebook_use_by_term.sql) | How much is each instructor actually using the gradebook, this term — works for Original **and** Ultra |
| [`gradebook_extractor_20251219.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/gradebook_extractor_20251219.sql) | Full gradebook column definitions + student roster/grade data for a course set |
| [`Item_extractor_20230221.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/Item_extractor_20230221.sql) | Performance on one named gradebook item, across every enrollment in a course set |
| [`rubric-cell level results_20260424.sql`](<https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/rubric-cell level results_20260424.sql>) | One row per student attempt per rubric criterion cell |

**Core tables:** `CDM_LMS.GRADEBOOK` (item definitions), `CDM_LMS.GRADE` (scores, `MODIFIER_PERSON_ID`/`MODIFIER_ROLE` for who graded), `CDM_LMS.COURSE_TOOL_ACTIVITY` (grading time/interactions, Original courses only).

---

## Discussion & Collaboration

**Delivered reports:** Social and Collaborative Engagement Report (*Learning*), Collaboration Session Activity Report (*Leading*).

| File | Question it answers |
|---|---|
| [`instructor_discussion_submissions.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/instructor_discussion_submissions.sql) | Instructor discussion-forum submissions for a course and date range |
| [`collaborate_recording_report_20220908.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/collaborate_recording_report_20220908.sql) | Collaborate recording metadata (link, duration, size, download/playback counts), in Blackboard's own Recording Report format |

**Core tables:** `CDM_LMS.COURSE_ITEM` (discussion posts), `CDM_CLB.MEDIA` (Collaborate recordings) — the only example in this repo drawing from `CDM_CLB`.

---

## AI Feature Adoption

**Delivered reports:** AI Design Assistant Adoption Report (*Teaching*) — note this is a *different* Ultra feature (course-build assistance for instructors) from what the SQL examples below cover (the student-facing **AI Conversation** assessment type). There is currently no delivered-report equivalent in this repo's examples for AI Conversation adoption specifically.

| File | Question it answers |
|---|---|
| [`AI_Conversations.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/AI_Conversations.sql) | Which instructors have built at least one AI Conversation assessment question |
| [`AI_Conversation_Use_Counter.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/AI_Conversation_Use_Counter.sql) | Click counts and unique-assessment counts for AI Conversation usage, per course |

**Core tables:** `CDM_LMS.COURSE_ITEM` (question type), `CDM_TLM.ULTRA_EVENTS` (click telemetry) — this pairing is the general pattern for any Ultra-Events-based feature-adoption question.

---

## Institutional Administration & Course Lifecycle

**Delivered reports:** Course Administration Report, Learning Platform Adoption Report (*Leading*), Instructional Practices Report, Course Summary Report (*Teaching*).

| File | Question it answers |
|---|---|
| [`course_org_activity_check.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/course_org_activity_check.sql) | Which Classic/Original courses & orgs still see activity, to prioritize Ultra migration |
| [`deleted_items_audit.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/deleted_items_audit.sql) | Deleted course items — creator, type, timestamps (who *created* it) |
| [`ultra_activity_audit_example_itemDelete.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ultra_activity_audit_example_itemDelete.sql) | Candidate deleters for an item, from Ultra Events (who likely *deleted* it — `deleted_items_audit.sql` can't tell you this) |
| [`ultra_activity_audit_example_courseConvert.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ultra_activity_audit_example_courseConvert.sql) | Who clicked "Convert to Ultra" in a course — a template for auditing any single Ultra Events tag |
| [`CTE_for_merged_enrollments.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/CTE_for_merged_enrollments.sql) | Maps a merged/child-course enrollment back to its parent-course enrollment (example pattern) |
| [`course_hierarchy_export_for_jenzabar.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/course_hierarchy_export_for_jenzabar.sql) | Course → primary institution hierarchy node mapping, for SIS integration |

**Core tables:** `CDM_LMS.COURSE`, `CDM_LMS.COURSE_ITEM`, `CDM_TLM.ULTRA_EVENTS`, `CDM_LMS.INSTITUTION_HIERARCHY_COURSE`.

---

## Accessibility (Ally)

**Delivered reports:** none of the three pillars above cover Ally specifically — Ally has its own reporting surface outside this taxonomy. This repo's example is the most complete coverage here.

| File | Question it answers |
|---|---|
| [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql) | Who made content-accessibility fixes through the Ally Instructor Feedback panel, and how many, by course/user |

**Core tables:** `CDM_TLM.ALLY_EVENTS` (refreshes every 30 min, same cadence as `ULTRA_EVENTS` — faster than the 12-hour `CDM_ALY` score refresh). See the [Ally Events Guide](Ally_Events_Guide) for the dual user-ID-format gotcha (`_874_1`-style vs. 32-char UUID) before joining this to `PERSON`.

---

## Learning Tool Adoption (General Pattern)

**Delivered reports:** Learning Tool Activity and Use Report, Learning Tools Adoption Report (*Leading*).

There's no single dedicated example file for "adoption of tool X" in general — `AI_Conversation_Use_Counter.sql` and `instructor_gradebook_use_by_term.sql` are both instances of the same underlying pattern: **join `CDM_TLM.ULTRA_EVENTS` (or `COURSE_TOOL_ACTIVITY` for Original courses) to the roster/content table that defines the tool's scope, filtered to that tool's specific event/objectId.** Reuse that pattern for any other tool-adoption question (discussion boards, journals, blogs, etc.) not already covered above.

---

## SIS-Style Extracts (Snapshot Equivalents)

Not a delivered-report category — a different *output format* for data covered above, structured to resemble Blackboard Snapshot SIS flat files for institutions that need that shape without an official Snapshot export. See [`SQL/Snapshot_Equivalents/`](https://github.com/jkelley-blackboard/blackboard_illuminate/tree/main/SQL/Snapshot_Equivalents) for Users, Courses, Course Memberships, Institution Hierarchy, and Course Association extracts. Not an official Snapshot export — some fields are derived or placeholder-only where Illuminate has no authoritative source.

---

## Data Pipeline Health (not a report at all)

**No delivered-report equivalent** — this is infrastructure monitoring, not institutional reporting. [`SQL/Data_Monitoring/`](https://github.com/jkelley-blackboard/blackboard_illuminate/tree/main/SQL/Data_Monitoring) tracks CDM insert cadence to flag stale pipelines before they silently affect every report above. If numbers in *any* of the reports above look wrong, check here before assuming a query bug.

---

## What You Won't Find Here

Everything above is bounded by what Illuminate actually captures and how often. Some real limitations, not just style gotchas:

- **Nothing is truly real-time.** The fastest CDM (`CDM_TLM`) is still a 30-minute batch. If you need "what is this student doing right now," Illuminate is the wrong tool — that's a live-Learn-session question, not an analytics-warehouse one.
- **Entities that never survive to a refresh cycle are invisible, not just delayed.** A course (or a preview user) created and deleted inside one `CDM_LMS` overnight window never appears in `CDM_LMS` at all — not "shows up late," genuinely absent. Only its `CDM_TLM` telemetry trail (if any) survives, and even that only for 30 minutes' worth of retention context around the event, not indefinitely.
- **Who deleted something, in general, isn't captured as a fact — at best it's inferred.** `deleted_items_audit.sql` tells you who *created* a deleted item; there is no `DELETED_BY` column. `ultra_activity_audit_example_itemDelete.sql` gets you *candidate* deleters by matching Ultra Events delete-confirmation clicks — and only for Ultra courses, only within whatever telemetry retention window applies, and as a set of candidates when multiple people had access, not a guaranteed single answer.
- **Ultra gradebook *time-on-task* isn't recoverable at all**, proxy or otherwise. `instructor_gradebook_use_by_term.sql`'s `grade.modifier_person_id` proxy tells you a grade was touched and when — it cannot tell you how long an instructor spent grading, the way `COURSE_TOOL_ACTIVITY` does for Original courses. That signal simply doesn't exist for Ultra.
- **Message/document content itself, mostly not.** These CDMs expose metadata and counts — who clicked, how many items, when a fix happened — not the underlying content body. There's no example here (or obvious CDM path) to pull the actual text of a discussion post, an AI Conversation transcript, or a submitted document; if you need content instead of activity, that's a different (likely non-Illuminate) system.
- **`CDM_MEDIA` (Video Studio) and `CDM_MAP` (Mapping) have no example coverage in this repo at all** — not because they're inaccessible, just unexplored here. If you need Video Studio viewership or hierarchy-mapping data, you're extending this repo's pattern into new territory, not adapting an existing example.
- **`CDM_SIS` (Anthology Student) isn't touched by anything in this repo either** — everything here is Learn/Illuminate-side. Financial, admissions, or other non-LMS institutional data lives elsewhere entirely.
- **`LEARN.ACTIVITY_ACCUMULATOR_ARCHIVE` requires Illuminate Premium.** Without that license tier, any query referencing it (see `SQL/Data_Monitoring/`) fails outright — table not found, not empty results.
- **`SQL/Snapshot_Equivalents/` outputs are not official Snapshot SIS files.** Some fields Blackboard's real Snapshot export contains — internal association keys in particular — have no authoritative source left in Illuminate once the original identifier is lost. Those come back as placeholders or derived values, never the genuine article.
- **None of this replaces the delivered reports' built-in permission/visibility scoping.** A SQL example run directly in Snowflake sees whatever the connecting role can see — it doesn't inherit the role-based row-level scoping a delivered report applies for, say, a department chair vs. an institutional admin. That's a query-design responsibility here, not something the CDM enforces for you.

---

## Gotchas that cut across every domain above

- **Refresh rates differ by CDM** — `CDM_TLM` every 30 min, `CDM_ALY` every 12 hours, `CDM_LMS` overnight. A delivered report and a same-day SQL query against a fast-refreshing CDM can disagree simply because `CDM_LMS` hasn't caught up yet. See [Best Practices & Data Notes](best-practices).
- **Ultra doesn't track gradebook activity the same way Original does.** `COURSE_TOOL_ACTIVITY` with `tool_source_id = 'instructor_gradebook'` is Original-course-only; for Ultra, use `CDM_LMS.GRADE.MODIFIER_PERSON_ID`/`MODIFIER_ROLE` instead (see `instructor_gradebook_use_by_term.sql`).
- **Role fields aren't consistent across tables.** `PERSON_COURSE.COURSE_ROLE` (normalized, e.g. `'I'`), `COURSE_ROLE_SOURCE_CODE` (raw Learn code), and `COURSE_ROLE_DESC` (description string) can all appear in different queries — prefer the normalized `COURSE_ROLE` unless you have a specific reason not to.
- **"Enabled" isn't "active."** `PERSON_COURSE.ACTIVE` combines availability + enabled state; checking `ENABLED_IND` alone (as some older queries in this repo do) can under-filter.
- **Preview users generate real `CDM_TLM` telemetry but never land in `CDM_LMS`.** Inner-joining Ultra Events to `PERSON` silently drops this traffic; left join and check for nulls instead.

---

Provided as-is, without support or warranty. See the repository [LICENSE](../LICENSE).
