# PERSON Table — Field Reference

> Each non-STAGE field links directly to its entry in the Illuminate Data Dictionary.
> All STAGE attributes link to the shared `PERSON.stage` dictionary entry.

## Identifiers & Keys

- **[ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-ID)** — Snowflake surrogate key for the person record.
- **[GLOBAL_PERSON_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-GLOBAL_PERSON_ID)** — Cross-CDM identifier linking a person across Illuminate data models.
- **[SOURCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-SOURCE_ID)** — Blackboard Learn internal primary key (`pk1`) for the user record. This value is stable and never reused.
- **[STAGE:uuid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Blackboard-generated UUID, used in LTI and cross-system integrations.
- **[STAGE:batch_uid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Institution-assigned external user key; unique within Blackboard Learn.
- **[STAGE:user_id](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Blackboard username used for login and authentication binding (e.g., LDAP, SSO).
- **[STAGE:student_id](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Institution student ID; informational, not required to be unique in Blackboard.
- **[STAGE:foundations_id](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Internal identifier used for integration with Blackboard platform services.

## Identity & Profile Information

- **[FIRST_NAME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-FIRST_NAME)** — User's first name.
- **[LAST_NAME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-LAST_NAME)** — User's last name.
- **[EMAIL](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-EMAIL)** — User's email address.
- **[AVATAR_URL](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-AVATAR_URL)** — URL of the user's profile avatar image, when one has been set.
- **[BIRTH_DATE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-BIRTH_DATE)** — User's date of birth, when provided by the source system.
- **[POSTAL_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-POSTAL_CODE)** — User's postal code, when provided by the source system.

## Organizational & Employment Attributes

- **[JOB_TITLE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-JOB_TITLE)** — User's job title, when provided by the source system.
- **[DEPARTMENT](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-DEPARTMENT)** — User's department, when provided by the source system.
- **[COMPANY](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-COMPANY)** — User's organization or company, when provided by the source system.

## Institutional & System Roles

- **[INSTITUTION_ROLE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-INSTITUTION_ROLE)** — User's primary institutional role (e.g., Student, Faculty, Staff).
- **[INSTITUTION_ROLE_SOURCE_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-INSTITUTION_ROLE_SOURCE_CODE)** — Source code for the institutional role as defined in Blackboard.
- **[INSTITUTION_ROLE_SOURCE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-INSTITUTION_ROLE_SOURCE_DESC)** — Display name of the institutional role source code.
- **[SYSTEM_ROLE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-SYSTEM_ROLE)** — User's primary Blackboard system role, which governs platform-level permissions.
- **[SYSTEM_ROLE_SOURCE_CODE](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-SYSTEM_ROLE_SOURCE_CODE)** — Source code for the system role as defined in Blackboard.
- **[SYSTEM_ROLE_SOURCE_DESC](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-SYSTEM_ROLE_SOURCE_DESC)** — Display name of the system role source code.

## Availability & Enablement

- **[AVAILABLE_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-AVAILABLE_IND)** — Availability flag from the Blackboard user record.
- **[ENABLED_IND](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-ENABLED_IND)** — Enablement flag from the Blackboard user record.

## Lifecycle & Audit

- **[CREATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-CREATED_TIME)** — Timestamp when the user record was created in Blackboard.
- **[MODIFIED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-MODIFIED_TIME)** — Timestamp when the user record was last updated in Blackboard.
- **[ROW_INSERTED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-ROW_INSERTED_TIME)** — Timestamp when the record was first written to Snowflake.
- **[ROW_UPDATED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-ROW_UPDATED_TIME)** — Timestamp of the most recent update to the record in Snowflake.
- **[ROW_DELETED_TIME](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-ROW_DELETED_TIME)** — Timestamp when the record was soft-deleted in Snowflake, reflecting removal from the Blackboard source.

## Data Source & Governance (STAGE)

- **[STAGE:data_src_batchuid](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-STAGE)** — Data source key identifying the integration or authority that owns this user record (e.g., `SYSTEM`, `SIS`, `PENDING_PURGE`).
- **[INSTANCE_ID](https://illuminate.blackboard.com/dictionary/entries/entry/CDM_LMS-PERSON-INSTANCE_ID)** — Identifies the Blackboard Learn deployment. All records from a single deployment share this value.

## Blackboard User Profile Fields Outside Illuminate Scope

The following fields are available in the Blackboard Learn user profile interface, but are NOT represented in Illuminate. Illuminate focuses on the core person attributes most relevant to learning analytics and institutional reporting. Fields primarily used for directory, HR, or contact management purposes are outside Illuminate's current scope.

| Category | Field | Notes |
|---|---|---|
| **Name & Identity** | Title | — |
| | Middle Name | — |
| | Suffix | — |
| | Other Name | — |
| | Name Pronunciation | UI display preference only |
| **Education & Academic Profile** | Education Level | — |
| **Email** | Institution Email | Illuminate stores only the primary email address per user.  This one is used only for MS integration. |
| **Demographics** | Gender | — |
| | Pronouns | — |
| **Address** | Street 1 | — |
| | Street 2 | — |
| | City | — |
| | State / Province | — |
| | Country | — |
| **Contact** | Home Phone | — |
| | Work Phone | — |
| | Work Fax | — |
| | Mobile Phone | — |
| **Web** | Website | — |
| **Institutional Structure** | Hierarchy / Node associations | User-to-node relationships are out of scope |
| **Roles** | Secondary Institution Roles | Illuminate stores the primary institutional role and primary system role only |
| | Secondary System Roles | See above |
