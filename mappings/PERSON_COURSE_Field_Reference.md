# PERSON_COURSE Table — Field Reference

> Each non-STAGE field links directly to its entry in the Illuminate Data Dictionary.
> All STAGE attributes link to the shared `PERSON_COURSE.stage` dictionary entry.
>
> **Grain:** One row per Person and Course combination.
> **Source:** `LEARN.COURSE_USERS`

## Identifiers & Keys

- **[ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ID)** — Snowflake surrogate key for the enrollment record.
- **[SOURCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-SOURCE_ID)** — Blackboard Learn internal primary key (`pk1`) from `LEARN.COURSE_USERS`. This value is stable and never reused.
- **[PERSON_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-PERSON_ID)** — References `CDM_LMS.PERSON.ID`.
- **[COURSE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-COURSE_ID)** — References `CDM_LMS.COURSE.ID`.
- **[INSTANCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-INSTANCE_ID)** — Identifies the Blackboard Learn deployment. All records from a single deployment share this value.

## Course Role

- **[COURSE_ROLE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-COURSE_ROLE)** — Canonical role name for this person in the course (e.g., Student, Instructor).
- **[COURSE_ROLE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-COURSE_ROLE_DESC)** — Human-readable description of the canonical course role.
- **[COURSE_ROLE_SOURCE_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-COURSE_ROLE_SOURCE_CODE)** — The role code as defined in Blackboard Learn, preserving institution-specific role configurations.
- **[COURSE_ROLE_SOURCE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-COURSE_ROLE_SOURCE_DESC)** — The role name as defined in Blackboard Learn, preserving institution-specific role labels.
- **[ACT_AS_INSTRUCTOR_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ACT_AS_INSTRUCTOR_IND)** — TRUE if this role is configured to behave like an Instructor role, regardless of the role's name. Preferred over role name matching for identifying instructor-like access.
- **[STUDENT_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-STUDENT_IND)** — TRUE if the person is a student in the course. Derived from course role (`S`) with Preview and Support users excluded.
- **[PRIMARY_INSTRUCTOR_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-PRIMARY_INSTRUCTOR_IND)** — TRUE if this user is designated as the primary instructor for the course.

## Availability & Enablement

- **[ACTIVE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ACTIVE)** — `1` = the enrollment is active; `0` = inactive. Derived from the availability and enablement flags. Use this field as the standard filter for active enrollments in reporting.
- **[AVAILABLE_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-AVAILABLE_IND)** — The availability toggle on the enrollment record, indicating whether the user has course access.
- **[ENABLED_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ENABLED_IND)** — The system-level enablement flag from the enrollment record.

## Accommodations

- **[DUE_DATE_EXCEPTION](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-DUE_DATE_EXCEPTION)** — Due date accommodation for this user in Ultra courses. `NULL` = no accommodation; `≤ 0` = unlimited extension; `> 0` = additional time in seconds. Applies to Ultra course sections only.
- **[TIME_LIMIT_EXCEPTION](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-TIME_LIMIT_EXCEPTION)** — Time limit accommodation for this user in Ultra courses. `NULL` = no accommodation; `0` = unlimited time; `150` = 1.5× the standard limit; `200` = 2× the standard limit. Applies to Ultra course sections only.

## Lifecycle & Audit

- **[ENROLLMENT_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ENROLLMENT_TIME)** — Timestamp when the enrollment was created in Blackboard Learn.
- **[MODIFIED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-MODIFIED_TIME)** — Timestamp when the enrollment record was last updated in Blackboard Learn.
- **[ROW_INSERTED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ROW_INSERTED_TIME)** — Timestamp when the record was first written to Snowflake.
- **[ROW_UPDATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ROW_UPDATED_TIME)** — Timestamp of the most recent update to the record in Snowflake.
- **[ROW_DELETED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-ROW_DELETED_TIME)** — Timestamp when the record was soft-deleted in Snowflake, reflecting removal from the Blackboard source.

## Data Source & Governance (STAGE)

- **[STAGE:pk1](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON_COURSE-STAGE)** — Blackboard `pk1` of the enrollment record; mirrors `SOURCE_ID`.

> The enrollment data source key — visible to administrators in the Blackboard enrollment management interface — is an attribute of the Blackboard enrollment record that is outside Illuminate's current scope. The data source key for the associated user and course records is available via `CDM_LMS.PERSON.STAGE:data_src_batchuid` and `CDM_LMS.COURSE.STAGE:data_src_batchuid` respectively.

## Blackboard Enrollment Fields Outside Illuminate Scope

| Blackboard Field | Notes |
|---|---|
| Availability Override Date | Date-based availability override on the enrollment record; outside current scope. |
| Enrollment Data Source Key | Identifies the integration or authority that owns the enrollment record (e.g., `SIS_STUDENTS`, `SYSTEM`). Not included in Illuminate. |

## Notes

| Topic | Detail |
|---|---|
| **Choosing an enrollment filter** | `ACTIVE = 1` is the recommended filter for most reporting use cases. `ENABLED_IND` and `AVAILABLE_IND` are available for scenarios requiring finer control over enrollment state. |
| **Identifying instructor-like roles** | Use `ACT_AS_INSTRUCTOR_IND = TRUE` rather than matching on role names. This accounts for custom institution-defined roles that inherit instructor privileges. |
| **Accommodations and course experience** | `DUE_DATE_EXCEPTION` and `TIME_LIMIT_EXCEPTION` apply to Ultra course sections only and will be `NULL` for Original course enrollments. |
| **Enrollment timestamp** | PERSON_COURSE uses `ENROLLMENT_TIME` for the source-side enrollment date. `ROW_INSERTED_TIME` reflects when the record arrived in Snowflake, which may differ. |

## Supplementing Gaps with the REST API

The enrollment-level fields above that are outside Illuminate's scope (e.g., availability override date, enrollment data source key) may be available directly from Blackboard Learn via the **Learn REST API** — e.g. `GET /learn/api/public/v1/courses/{courseId}/users/{userId}`. This is a live call against your Learn environment, not a Snowflake/Illuminate query, so it requires a registered REST integration with the appropriate entitlements and is best suited to one-off lookups or small-scale enrichment rather than bulk reporting. Verify current endpoint paths and versions against your Learn REST API documentation.
