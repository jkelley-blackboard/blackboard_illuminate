# COURSE Table — Field Reference

> Each non-STAGE field links directly to its entry in the Illuminate Data Dictionary.
> All STAGE attributes link to the shared `COURSE.stage` dictionary entry.

## Identifiers & Keys

- **[ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ID)** — Snowflake surrogate key for the course record.
- **[SOURCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-SOURCE_ID)** — Blackboard Learn internal primary key (`pk1`). This value is stable, never reused, and is visible in course URLs.
- **[COURSE_NUMBER](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-COURSE_NUMBER)** — The visible Course ID in Blackboard Learn. Unique within a live deployment; historical records in Snowflake may reflect prior courses that shared the same ID over time.
- **[STAGE:uuid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Blackboard-generated UUID, used in LTI and cross-system integrations.
- **[STAGE:batch_uid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Institution-assigned external course key; unique within Blackboard Learn.
- **[STAGE:foundations_id](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Internal identifier used for integration with Blackboard platform services.

## Relationships

- **[COURSE_PARENT_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-COURSE_PARENT_ID)** — References `COURSE.id` of the parent course in a merged/cross-listed set.
- **[STAGE:crsmain_parent_pk1](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Blackboard `pk1` of the parent course; the source value underlying `COURSE_PARENT_ID`.
- **[TERM_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-TERM_ID)** — References `TERM.id` in Snowflake.
- **[COPY_FROM_COURSES](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-COPY_FROM_COURSES)** — References `COURSE.id` values for courses from which this course was copied.

## Descriptive Metadata

- **[NAME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-NAME)** — Course name as it appears in Blackboard Learn.
- **[DESCRIPTION](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-DESCRIPTION)** — Course description as entered in Blackboard Learn.

## Course Experience / Design

- **[DESIGN_MODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-DESIGN_MODE)** — Indicates whether the course uses the Ultra or Original course experience.
- **[DESIGN_MODE_SOURCE_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-DESIGN_MODE_SOURCE_CODE)** — The underlying `ULTRA_STATUS` value from Blackboard; functionally equivalent to `DESIGN_MODE`.
- **[DESIGN_MODE_SOURCE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-DESIGN_MODE_SOURCE_DESC)** — Reserved for future use; currently unpopulated.

## Enrollment Configuration

- **[ENROLLMENT_METHOD](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ENROLLMENT_METHOD)** — Course enrollment type: `I` = Instructor/Admin managed; `E` = email approval; `S` = self-enrollment.
- **[ENROLLMENT_METHOD_SOURCE_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ENROLLMENT_METHOD_SOURCE_CODE)** — The underlying `ENROLL_OPTION` value from Blackboard; functionally equivalent to `ENROLLMENT_METHOD`.
- **[ENROLLMENT_METHOD_SOURCE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ENROLLMENT_METHOD_SOURCE_DESC)** — Reserved for future use; currently unpopulated.

## Availability & Enablement

- **[AVAILABLE_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-AVAILABLE_IND)** — The availability flag as set directly on the course record in Blackboard.
- **[AVAILABLE_TO_STUDENTS_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-AVAILABLE_TO_STUDENTS_IND)** — Derived availability indicator that accounts for term dates, course dates, and the availability flag. Use this field for student access reporting.
- **[ENABLED_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ENABLED_IND)** — System-level enablement flag from the Blackboard course record.
- **[STAGE:avl_rule_indicator](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Indicates whether date-based availability rules are active for this course.

## Scheduling

> `START_DATE` and `END_DATE` are superseded by `START_TIME` and `END_TIME`, which preserve full timestamp precision. New queries should use `START_TIME` and `END_TIME`.

- **[START_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-START_TIME)** — Full timestamp of the configured course start date.
- **[END_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-END_TIME)** — Full timestamp of the configured course end date.
- **~~[START_DATE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-START_DATE)~~** *(Superseded)* — Date-only version of the course start. Use `START_TIME` instead.
- **~~[END_DATE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-END_DATE)~~** *(Superseded)* — Date-only version of the course end. Use `END_TIME` instead.

## Access Activity (Derived)

- **[FIRST_COURSE_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-FIRST_COURSE_TIME)** — Timestamp of the earliest recorded access to the course by any user, derived from `CDM_LMS.COURSE_ACTIVITY`.
- **[LAST_COURSE_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-LAST_COURSE_TIME)** — Timestamp of the most recent recorded access to the course by any user, derived from `CDM_LMS.COURSE_ACTIVITY`.
- **[FIRST_COURSE_WEEK](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-FIRST_COURSE_WEEK)** — Monday of the week containing `FIRST_COURSE_TIME`; useful for week-aligned reporting.
- **[LAST_COURSE_WEEK](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-LAST_COURSE_WEEK)** — Monday of the week containing `LAST_COURSE_TIME`; useful for week-aligned reporting.

## Lifecycle & Audit

- **[CREATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-CREATED_TIME)** — Timestamp when the course was created in Blackboard Learn.
- **[MODIFIED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-MODIFIED_TIME)** — Timestamp when the course record was last updated in Blackboard Learn.
- **[ROW_INSERTED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ROW_INSERTED_TIME)** — Timestamp when the record was first written to Snowflake.
- **[ROW_UPDATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ROW_UPDATED_TIME)** — Timestamp of the most recent update to the record in Snowflake.
- **[ROW_DELETED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-ROW_DELETED_TIME)** — Timestamp when the record was soft-deleted in Snowflake, reflecting removal from the Blackboard source.

## Settings and Other Metadata (STAGE)

- **[STAGE:uuid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Blackboard-generated UUID, used in LTI and cross-system integrations.
- **[STAGE:batch_uid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Institution-assigned external course key; unique within Blackboard Learn.
- **[STAGE:foundations_id](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Internal identifier used for integration with Blackboard platform services.
- **[STAGE:crsmain_parent_pk1](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Blackboard `pk1` of the parent course in a merged set. See also `COURSE_PARENT_ID`.
- **[STAGE:data_src_batchuid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Human-readable data source key identifying the integration that owns this course record (e.g., `SYSTEM`, `FLAT_FILES`, `SIS`).
- **[STAGE:data_src_pk1](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Numeric identifier for the data source record in Blackboard; companion to `data_src_batchuid`.
- **[STAGE:avl_rule_indicator](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Indicates whether date-based availability rules govern student access to this course.
- **[STAGE:service_level](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Distinguishes the type of course or container record. Known values: `F` = Full/Free Course; `C` = Community (Organization); `R` = Registered Course *(not used)*; `T` = Test Drive *(not used)*; `S` = System *(only the singular "SYSTEM" course)*; `L` = System *(not used)*; `P` = Program; `J` = Subject; `M` = Course Template *(behavior TBD)*; `N` = Organization Template *(behavior TBD)*; `O` = Learning Object Repository.
- **[STAGE:allow_guest](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Guest access setting (`Y`/`N`).
- **[STAGE:allow_observer](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Observer access setting (`Y`/`N`).
- **[STAGE:sos_id_pk2](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-STAGE)** — Legacy tenant identifier from earlier Blackboard hosting architectures; retained for historical continuity.
- **[INSTANCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-COURSE-INSTANCE_ID)** — Identifies the Blackboard Learn deployment. All records from a single deployment share this value.

## Blackboard Course Settings Outside Illuminate Scope

The following settings are configurable in the Blackboard Learn course interface, but are not represented in Illuminate. Illuminate focuses on the course attributes most relevant to learning analytics and institutional reporting.

| Category | Field | Notes |
|---|---|---|
| **General Information** | Subject Area | Legacy catalog metadata; distinct from 2026 Subject features |
| | Discipline | Legacy catalog metadata; distinct from 2026 Subject/Program features |
| | Subject ID | Course–Subject associations are a 2026 platform feature |
| **Availability** | Duration Type | Course duration type semantics are reflected in date fields |
| | Course Complete Flag | Course completion state is managed in Blackboard; not reflected in COURSE |
| **Categories** | Course Categories | Catalog and category metadata are outside current scope |
| **Enrollment Options** | Self-enrollment dates, times, access code | `ENROLLMENT_METHOD = 'S'` indicates self-enrollment is enabled; the associated configuration details are outside current scope |
| **Localization** | Language Pack | Course-level language setting |
| **Content View** | Text / Icon View | Original course view preference |
| **Course Banner** | Banner image | Course branding asset |

## Supplementing Gaps with the REST API

Several of the course settings above (e.g., subject/discipline metadata, categories, banner image) aren't present in Illuminate but may be available directly from Blackboard Learn via the **Learn REST API** — e.g. `GET /learn/api/public/v3/courses/{courseId}`. This is a live call against your Learn environment, not a Snowflake/Illuminate query, so it requires a registered REST integration with the appropriate entitlements and is best suited to one-off lookups or small-scale enrichment rather than bulk reporting. Verify current endpoint paths and versions against your Learn REST API documentation.
