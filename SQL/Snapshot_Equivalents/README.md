
# Snapshot-Style SQL Extracts (Illuminate)

## Overview

This directory contains SQL scripts that generate **Snapshot-style data extracts** using data available in **Illuminate (Blackboard Data)**. These extracts are intended to be **structurally similar** to Blackboard **Snapshot SIS flat files**, but they are **not official Snapshot exports**.

The scripts support common Snapshot object types, including:
- Users (Person)
- Courses
- Course Memberships
- Institution Hierarchy
- Course Associations (course ↔ hierarchy mapping)

---

## Reference

Unofficial Snapshot SIS object specs (field lists, formats, headers) are maintained at:
https://github.com/jkelley-blackboard/Blackboard-SIS-Integration-Resources/blob/main/snapshot/specs/

---

## Important Notes

- These SQL files generate **Snapshot-like outputs**, not Blackboard-generated Snapshot files.
- Field availability is limited to what is stored in Illuminate; some Snapshot fields are:
  - **Derived** (e.g., association keys), or
  - **Supplied via placeholders** where no authoritative source exists.
- Blackboard-generated identifiers (such as internal external association keys) are **not recoverable** from Illuminate once lost.

All scripts include inline comments documenting:
- Derived values
- Placeholder usage
- Known limitations

---

## Assumptions and Conventions

- External keys are sourced from `STAGE['batch_uid']` where available.
- JSON fields are accessed using **bracket notation** (`['key']`) for clarity and safety.
- Output column names are **fully capitalized** and **quoted**.
- Date fields (where applicable) follow Snapshot-compatible formats (`YYYYMMDD`).
- Only fields defined by the relevant Snapshot object header are included.

---

## Load Order (If Used for Provisioning)

If these outputs are used to seed or reload data in Blackboard, the recommended processing order is:

1. Institution Hierarchy  
2. Courses  
3. Course Associations  
4. Users  
5. Course Memberships

---

## Disclaimer

These scripts are provided **"AS IS"**, without warranty or support of any kind.  
They are intended for analysis, validation, or controlled integration scenarios where official Snapshot SIS files are unavailable.
