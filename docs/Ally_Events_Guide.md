[← Home](.)

# CDM_TLM.ALLY_EVENTS — event_type and DATA Field Guide

> **Disclaimer:** Nothing on this page supersedes the [official Blackboard Illuminate documentation](https://help.blackboard.com/Anthology_Illuminate) or any agreement your institution has with Blackboard. This guide is reverse-engineered from sample rows pulled from a production `CDM_TLM.ALLY_EVENTS` table, not copied from the Illuminate Data Dictionary — event types, field names, and observed value lists are **not guaranteed to be exhaustive**. Verify against your own instance before relying on this for reporting, billing, compliance, or any other downstream decision.

---

## Overview

`CDM_TLM.ALLY_EVENTS` is a telemetry stream of user interactions with Ally — the accessibility-checking product embedded in Blackboard Learn/Ultra. Every row is one discrete event: an instructor opening a feedback panel, applying a fix, downloading an alternative format, sorting a report table, and so on.

| Column | Notes |
|---|---|
| `UUID` | Row identifier, `ALLY_<uuid>` format. |
| `EVENT_TIME` | When the event occurred (source system time, with offset). |
| `EVENT_TYPE` | The event name — see catalog below. Mirrors `DATA:type`. |
| `DATA` | VARIANT column holding the full event payload. See field guide below. |
| `ROW_INSERTED_TIME` | When Snowflake ingested the row. Rows land in batches — many rows share an identical `ROW_INSERTED_TIME`. |

**Refresh cadence:** `ALLY_EVENTS` lives in `CDM_TLM` and refreshes every 30 minutes (same cadence as `ULTRA_EVENTS`) — **not** the 12-hour cadence of `CDM_ALY` (Ally's own score/report tables). See [Best Practices & Data Notes](best-practices) for the general CDM refresh-rate table and cross-CDM join gotchas.

**Grain:** One row per discrete user action. Content that has multiple issues, or an instructor who opens/closes the panel multiple times, produces multiple rows — this is a raw event log, not a summary table.

---

## DATA — Common Envelope Fields

Every event type shares this outer shape. The event-specific payload lives in `DATA:result`, which varies by `event_type` (catalog below).

| Field | Notes |
|---|---|
| `clientId` | `null` in every sample observed. |
| `contextId` | Course/org context, e.g. `"_10513_1"`. Numeric segment maps to `CDM_LMS.COURSE.SOURCE_ID`. |
| `contextType` | Only `"course"` observed. Unconfirmed whether organizations report a different value — check `CDM_LMS.COURSE.STAGE:service_level` (`F`=course, `C`=organization) if you need to distinguish, as documented in [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql). |
| `date` | ISO-8601 UTC timestamp; redundant with `EVENT_TIME`. |
| `environmentId` | Ally hosting region/environment, e.g. `"us-east-1:production"`. |
| `instanceId` | Blackboard Learn deployment identifier. |
| `objectId` | The content item this event is about, e.g. `"_1704847_1"`. **`null` for course/report-level events** (see catalog). Two sentinel-style patterns also observed: the literal `"content:irrelevant"` for course-level HTML checks (e.g. banner/syllabus contrast) not tied to a specific content item, and `"content:_<id>_1"` (e.g. `"content:_534698_1"`) for a specific HTML-fragment content block — seen on WYSIWYG fixes and alternative-format events. |
| `objectType` | `image`, `document`, `pdf`, `presentation`, `html-fragment`, `html-page` observed; `null` when `objectId` is `null`. Not confirmed exhaustive — Ally supports other content types (audio, video, etc.) not seen in this sample. |
| `productId` | Always `"ALLY"`. |
| `result` | Event-specific payload. Shape depends on `event_type` — see catalog below. |
| `tenantId` | Ally tenant UUID, constant per institution. |
| `type` | Mirrors the `EVENT_TYPE` column. |
| `userId` | **Two formats observed** — see [Identifier Gotchas](#identifier-gotchas) below. |

---

## Event Type Catalog

Grouped by the Ally workflow they belong to. `result` fields listed are what's been observed in sample data only.

### Instructor Feedback Panel (content-level)

Fired when an instructor opens the per-item accessibility panel from inside a course, reviews a specific rule's score, and optionally fixes it. `objectId`/`objectType` are populated on all of these.

| event_type | Fires when | `DATA:result` fields |
|---|---|---|
| `ENGAGE_INSTRUCTOR_FEEDBACK` | Panel opened for one rule on one content item. | `platformUi`, `ruleName`, `score`, `scoreIndicatorRange` |
| `CLOSE_INSTRUCTOR_FEEDBACK` | Panel closed. Same shape as `ENGAGE_INSTRUCTOR_FEEDBACK`. `ruleName` is sometimes **absent** — observed on rows where `score = "1"` / `scoreIndicatorRange = "perfect"`, suggesting it's omitted when no rule is flagged. | `platformUi`, `ruleName` (sometimes omitted), `score`, `scoreIndicatorRange` |
| `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK` | Instructor applied a fix through the panel — the actual accessibility-fix event. Fully documented (13 known `alterationType` values) in [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql). | `alterationType`, `platformUi`, `ruleName`, `scoreBefore`, `scoreAfter`, `scoreChangeType` |

### Instructor Report (course-level)

Fired inside the course-level Accessibility Report UI (the ranked list of issues across the whole course), not tied to one content item. `objectId`/`objectType` are `null` on all of these.

| event_type | Fires when | `DATA:result` fields |
|---|---|---|
| `ENGAGE_INSTRUCTOR_REPORT` | Report opened. | `{}` — empty object. |
| `INSTRUCTOR_REPORT_LAUNCHER` | A launcher/quick-start shortcut clicked (e.g. "fix easiest issues first"). | `eventType: "click"`, `launcher` (e.g. `"easiest"`) |
| `INSTRUCTOR_REPORT_ISSUES_LIST_SELECTED` | An issue row selected from the report's issues list. | `eventType: "click"`, `ruleName` |
| `INSTRUCTOR_REPORT_ISSUES_LIST_SORT` | Issues list sorted by a column. | `eventType: "click"`, `sortBy` (e.g. `"description"`, `"contentCount"`) |
| `INSTRUCTOR_REPORT_ISSUES_LIST_SORT_SEVERITY` | Issues list sorted specifically by severity — a distinct event type from the generic sort above, not a `sortBy` value of it. | `eventType: "click"`, `sortBy: "severity"` |
| `INSTRUCTOR_REPORT_CONTENT_LIST_SORT` | The *content* list (not the issues list) sorted by a column — a separate view from the issues list, with its own dedicated sort event type following the same `_SORT` / `_SORT_SEVERITY` split pattern. | `eventType: "click"`, `sortBy` (e.g. `"issueCount"`) |
| `INSTRUCTOR_REPORT_CONTENT_BACK_TO_OVERVIEW` | Navigated from a content-detail view back to the report overview. | `eventType: "click"` |

### Alternative Format Downloads

Fired when any user (student or instructor) uses Ally's "download alternative format" menu on a content item (e.g. tagged PDF, translation, audio/Beeline, text-to-speech). `objectId`/`objectType` populated — including the `"content:_<id>_1"` pattern for HTML-fragment content blocks (see [Identifier Gotchas](#identifier-gotchas)).

| event_type | Fires when | `DATA:result` fields |
|---|---|---|
| `ENGAGE_ALTERNATIVE_FORMAT` | Alternative-format menu opened for an item. | `aafsEnabled` (string `"true"`/`"false"`), `platformUi` |
| `BEGIN_DOWNLOAD_ALTERNATIVE_FORMAT` | A specific format download started. | `formatType` (`"Beeline"`, `"Translation"`, `"Tts"`, `"Html"`, `"Source"`, `"ImmersiveReader"`, ...), `formatParam` (only observed on `Translation` — locale code, e.g. `"es-MX"`), `platformUi` |
| `COMPLETE_DOWNLOAD_ALTERNATIVE_FORMAT` | Download finished successfully. | `formatType`, `platformUi` |
| `CANCEL_DOWNLOAD_ALTERNATIVE_FORMAT` | Download canceled/failed. | `formatType`, `platformUi` |

### Other

| event_type | Fires when | `DATA:result` fields |
|---|---|---|
| `NEED_EXTRA_HELP` | User clicked a "need extra help" / support link inside Ally UI. | `helpType` (e.g. `"DefaultHelp"`), `role` (e.g. `"Instructor"`) |

---

## Observed Value Reference

Not exhaustive — these are only the values seen in sample data. Treat any value not listed here as possible, not as an error.

- **`ruleName`** (accessibility rule the score/fix applies to): `ImageDescription`, `ImageContrast`, `Scanned`, `AlternativeText`, `Contrast`, `HeadingsPresence`, `Tagged`, `Title`, `LanguageCorrect`, `HtmlColorContrast`, `TableHeaders`, `Security`, `Ocred`. Note `ImageContrast` and `Contrast` are both observed as distinct rule names — don't collapse them.
- **`alterationType`** (fix type, `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK` only): see the 13-value breakdown in [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql)
- **`objectType`**: `image`, `document`, `pdf`, `presentation`, `html-fragment`, `html-page`
- **`formatType`**: `Beeline`, `Translation`, `Tts`, `Html`, `Source`, `ImmersiveReader`
- **`scoreIndicatorRange`**: `low`, `medium`, `high`, `perfect` — see approximate thresholds below

### score → scoreIndicatorRange (approximate, inferred — not documented cutoffs)

| `score` range observed | `scoreIndicatorRange` |
|---|---|
| 0 – 0.25 | `low` |
| ~0.36 – 0.64 | `medium` |
| ~0.75 – 0.98 | `high` |
| 1 (exactly) | `perfect` |

The gaps between these bands (roughly 0.25–0.36 and 0.64–0.75) were never observed, so the exact cutoffs are unconfirmed — treat these as directional, not authoritative. The `high` floor moved down from an earlier estimate of ~0.95 once a `score: "0.75"` / `scoreIndicatorRange: "high"` row turned up — a reminder that these bands will keep shifting as more data comes in.

### `ruleName` can be absent even on `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK`

Every earlier sample had `ruleName` present on `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK` events, but `alterationType: "RemoveLibraryReference"` rows have been observed with **no `ruleName` key at all** in `result`. Don't assume it's always there — check for its existence before referencing it, rather than assuming `NOT NULL`.

---

## Identifier Gotchas

- **`userId` has two formats, and the split appears to be per-user, not per-event-type:**
  - `"_11638_1"` style — numeric segment maps to `CDM_LMS.PERSON.SOURCE_ID`.
  - 32-char lowercase hex (e.g. `"2fd0970cbc874c7a89cb4cc5d954204d"`) — maps to `CDM_LMS.PERSON.STAGE:uuid`.

  Each individual person in the sample data consistently used **one** format across every event type they appeared in — including a hex-format user who generated `ENGAGE_INSTRUCTOR_FEEDBACK` and `CLOSE_INSTRUCTOR_FEEDBACK` events, not just report-UI events. This **contradicts** the narrower claim in [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql) that the hex format was "only seen on instructor-report-UI events, not on the fix event itself" — that held for `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK` specifically in that sample, but not for `ENGAGE_INSTRUCTOR_FEEDBACK`/`CLOSE_INSTRUCTOR_FEEDBACK`. Don't assume format correlates with event type; check both formats defensively regardless of which event you're querying, as that query already does.
- **`contextId`** — `"_10880_1"` style; numeric segment maps to `CDM_LMS.COURSE.SOURCE_ID`.
- **String-typed values that look numeric/boolean** — `score`, `scoreBefore`, `scoreAfter`, and `aafsEnabled` are all stored as strings inside the VARIANT (e.g. `"0.25"`, `"true"`), not native FLOAT/BOOLEAN. Cast explicitly (`::FLOAT`, `::BOOLEAN`) before comparing or aggregating.

---

## Example Queries

| File | Purpose |
|---|---|
| [`ally_instructor_fixes_by_course_user.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ally_instructor_fixes_by_course_user.sql) | `ALTERED_THROUGH_INSTRUCTOR_FEEDBACK` rolled up by course/user, with `alterationType` breakdown and identifier-join caveats. |

For the sibling telemetry table (`CDM_TLM.ULTRA_EVENTS`, non-Ally Ultra UI analytics events), see [`ultra_activity_audit_example_courseConvert.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/ultra_activity_audit_example_courseConvert.sql) and [`AI_Conversation_Use_Counter.sql`](https://github.com/jkelley-blackboard/blackboard_illuminate/blob/main/SQL/AI_Conversation_Use_Counter.sql) — same `DATA` VARIANT pattern, different event catalog.

### Discovery query — run this periodically to extend this guide

```sql
SELECT
    EVENT_TYPE,
    COUNT(*)                                   AS event_count,
    ARRAY_AGG(DISTINCT DATA:objectType::STRING) AS object_types_seen,
    ANY_VALUE(DATA)                             AS sample_payload
FROM CDM_TLM.ALLY_EVENTS
WHERE EVENT_TIME >= DATEADD(day, -30, CURRENT_DATE())
GROUP BY EVENT_TYPE
ORDER BY event_count DESC;
```
