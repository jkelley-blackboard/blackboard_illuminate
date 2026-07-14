# TERM Table — Field Reference

> Each non-STAGE field links directly to its entry in the Illuminate Data Dictionary.
> All STAGE attributes link to the shared `TERM.stage` dictionary entry.
>
> **Grain:** One row per Term.
> **Source:** `LEARN.TERM`

## Identifiers & Keys

- **[ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-ID)** — Snowflake surrogate key for the term record.
- **[SOURCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-SOURCE_ID)** — Blackboard internal primary key (`pk1`) for the term. This value is stable and never reused.
- **[INSTANCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-INSTANCE_ID)** — Identifies the Blackboard deployment. All records from a single deployment share this value.

## Descriptive Metadata

- **[NAME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-NAME)** — Term name as it appears in Blackboard.
- **[DESCRIPTION](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-DESCRIPTION)** — Term description as entered in Blackboard. This field may contain HTML markup when the rich text editor is used.

## Scheduling

- **[START_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-START_TIME)** — Full timestamp of the term start date.
- **[END_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-END_TIME)** — Full timestamp of the term end date.
- **[START_DATE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-START_DATE)** *(Deprecated per Data Dictionary)* — Date portion of the term start. Sourced from `LEARN.TERM.START_DATE`.
- **[END_DATE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-END_DATE)** *(Deprecated per Data Dictionary)* — Date portion of the term end. Sourced from `LEARN.TERM.END_DATE`.

## Availability & Enablement

- **[AVAILABLE_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-AVAILABLE_IND)** — Availability flag from the Blackboard term record.
- **[ENABLED_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-ENABLED_IND)** — System-level enablement flag from the Blackboard term record.

## Lifecycle & Audit

- **[MODIFIED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-MODIFIED_TIME)** — Timestamp when the term record was last updated in Blackboard.
- **[ROW_INSERTED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-ROW_INSERTED_TIME)** — Timestamp when the record was first written to Snowflake. For deployments with historical term data loaded at Illuminate onboarding, this value reflects the load date rather than when the term was originally created in Blackboard.
- **[ROW_UPDATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-ROW_UPDATED_TIME)** — Timestamp of the most recent update to the record in Snowflake.
- **[ROW_DELETED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-ROW_DELETED_TIME)** — Timestamp when the record was soft-deleted in Snowflake, reflecting removal from the Blackboard source.

> TERM does not have a `CREATED_TIME` column sourced from Blackboard.

## Data Source & Governance (STAGE)

- **[STAGE:data_src_pk1](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-TERM-STAGE)** — Numeric identifier for the data source record in Blackboard, identifying the integration or authority that owns this term record.

## Blackboard Term Fields Outside Illuminate Scope
The following data related to terms in the Blackboard application are not included in the Illuminate data model.

| Blackboard Field | Notes |
|---|---|
| Term Data Source Key | The human-readable data source key label is not included in Illuminate for Term. `STAGE:data_src_pk1` provides the numeric identifier for the same data source record. |
| Duration Type | Controls how course access within the term is calculated (e.g., fixed dates, days from enrollment). |
| Course Late Access / Reinstatement settings | Term-level late access configuration. |
| Term Type | Introduced in Blackboard 2026: Unspecified, Semester, Trimester, Quarter, Intersession, Module, Annual. Not yet represented in Illuminate. |
| Term Hierarchy | Introduced in Blackboard 2026: term-to-term associations allowing parent/child term relationships. Not yet represented in Illuminate. |
| Performance Results Scale | Introduced in Blackboard 2026 in support of Outcomes integration. Not yet represented in Illuminate. |

## Supplementing Gaps with the REST API

The term settings above that are outside Illuminate's scope (e.g., Term Type, Term Hierarchy, Duration Type) may be available directly from Blackboard Learn via the **Learn REST API** — e.g. `GET /learn/api/public/v1/terms/{termId}`. This is a live call against your Learn environment, not a Snowflake/Illuminate query, so it requires a registered REST integration with the appropriate entitlements and is best suited to one-off lookups or small-scale enrichment rather than bulk reporting. Verify current endpoint paths and versions against your Learn REST API documentation.
