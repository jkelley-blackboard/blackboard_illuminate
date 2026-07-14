[← Home](.)

# Basic User Activity Tracking with CDM_LMS

> **Disclaimer:** Nothing on this page supersedes the [official Blackboard Illuminate documentation](https://help.blackboard.com/Anthology_Illuminate) or any agreement your institution has with Blackboard. These notes are supplemental only — provided as-is, without warranty or support. Column behavior described below is inferred from working queries in this repo, not copied from the Illuminate Data Dictionary — verify against your own dictionary entries before relying on it.

---

## Overview

"Activity" in `CDM_LMS` is split across three tables, depending on whether you're asking *"when did this person last use the system at all?"* or *"how much did they do inside a specific course?"*:

| Table | Answers | Grain (observed) |
|---|---|---|
| `CDM_LMS.SESSION_ACTIVITY` | When did this person last log in, system-wide? | Multiple rows per person; aggregate to get "last login" |
| `CDM_LMS.COURSE_ACTIVITY` | How much time/interaction did this person log in this course? | Multiple rows per enrollment (`PERSON_COURSE_ID`); aggregate to get per-enrollment totals |
| `CDM_LMS.ACTIVITY` | Raw system-wide activity events | Not used for reporting examples in this repo yet — see note below |

This guide covers the first two, which are the tables the SQL examples in this repo actually use for reporting. It intentionally does not cover `CDM_TLM` (Telemetry/Ultra Events) — see [Best Practices & Data Notes](best-practices) for the gotchas involved in joining `CDM_TLM` back to `CDM_LMS`.

---

## CDM_LMS.SESSION_ACTIVITY — System Login Activity

This is the system-wide "last logged in" signal — it isn't scoped to a course.

Columns used in this repo's queries:

- `PERSON_ID` — references `CDM_LMS.PERSON.ID`
- `LAST_ACCESSED_TIME` — timestamp of the login/session event
- `ROW_DELETED_TIME` — standard soft-delete marker; filter to `IS NULL`

There appear to be multiple rows per person over time (not one summary row per person), so always aggregate with `MAX(LAST_ACCESSED_TIME) GROUP BY PERSON_ID` rather than selecting a row directly.

**Minimal pattern:**

```sql
SELECT
    person_id,
    MAX(last_accessed_time) AS last_login_time
FROM CDM_LMS.SESSION_ACTIVITY
WHERE row_deleted_time IS NULL
GROUP BY person_id;
```

See [`SQL/basic_login_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_login_activity.sql) for the full example joined to `PERSON`.

---

## CDM_LMS.COURSE_ACTIVITY — Per-Enrollment Course Activity

This is where course-level time-on-task and interaction counts live.

Columns used in this repo's queries:

- `PERSON_COURSE_ID` — references `CDM_LMS.PERSON_COURSE.ID`. This is the reliable join key — treat any direct `PERSON_ID`/`COURSE_ID` columns on this table as unconfirmed until you've checked your own Data Dictionary.
- `DURATION_SUM` — time-on-task. **Units are seconds** — every query in this repo that surfaces "minutes" divides `DURATION_SUM` by 60.
- `INTERACTION_CNT` — count of discrete interactions/clicks in that row.
- `FIRST_ACCESSED_TIME` / `LAST_ACCESSED_TIME` — access window for that row.
- `ID` — row identifier; used with `COUNT(DISTINCT id)` to count discrete access events.
- `ROW_DELETED_TIME` — standard soft-delete marker; filter to `IS NULL`.

Like `SESSION_ACTIVITY`, this table has multiple rows per enrollment (likely bucketed over time — e.g. daily), not one row per `PERSON_COURSE_ID`. Always aggregate:

```sql
SELECT
    person_course_id,
    MIN(first_accessed_time)        AS first_access,
    MAX(last_accessed_time)         AS last_access,
    ROUND(SUM(duration_sum) / 60, 1) AS total_minutes,
    SUM(interaction_cnt)             AS total_interactions
FROM CDM_LMS.COURSE_ACTIVITY
WHERE row_deleted_time IS NULL
GROUP BY person_course_id;
```

See [`SQL/basic_course_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_course_activity.sql) for the full example joined to `PERSON`, `PERSON_COURSE`, and `COURSE`.

---

## CDM_LMS.ACTIVITY — System-Wide Activity Log

This table is currently only referenced in this repo for [pipeline freshness monitoring](https://github.com/jkelley-blackboard/blackboard_illuminate/tree/main/SQL/Data_Monitoring) (checking `ROW_INSERTED_TIME` cadence), not for reporting on what users actually did. If you plan to query it for activity reporting, confirm its column list against your Illuminate Data Dictionary first — no reporting example against it is included here yet.

---

## Gotchas

- **`DURATION_SUM` is seconds, not minutes.** Divide by 60 before displaying "time on task."
- **Both activity tables are one-to-many per person/enrollment.** Never assume a single row — always `GROUP BY` and aggregate, or you'll silently undercount.
- **Filter soft deletes everywhere.** `ROW_DELETED_TIME IS NULL` on every table in the join, including `PERSON`, `PERSON_COURSE`, and `COURSE` — not just the activity table itself.
- **`CDM_LMS` refreshes overnight.** Today's activity typically won't be visible until the next day's load — don't expect same-day numbers. See [Best Practices & Data Notes](best-practices) for the full CDM refresh-rate table.
- **`LEFT JOIN` from the roster, not the activity table**, when you want to include users/enrollments with zero activity in the window (e.g. to spot non-participation). An `INNER JOIN` against the activity tables will silently drop anyone who hasn't logged in or accessed the course yet.

---

## Example Queries

| File | Purpose |
|---|---|
| [`basic_login_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_login_activity.sql) | Last system-wide login per person |
| [`basic_course_activity.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_course_activity.sql) | Total time and interactions per person, per course |
| [`basic_user_activity_summary.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/basic_user_activity_summary.sql) | One course roster with login + course activity combined |

For a more complete version with submission counts, grades, and parameterized filters, see [`SQL/MultiCourseUserParticipation_20260424.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/MultiCourseUserParticipation_20260424.sql) and [`SQL/student_course_summary.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/student_course_summary.sql).
