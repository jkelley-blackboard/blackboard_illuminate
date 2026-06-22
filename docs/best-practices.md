[← Home](.)

# Best Practices & Data Notes

Things worth knowing when working with Blackboard Illuminate data in Snowflake. These are observations and patterns that aren't always obvious from the documentation alone.

---

## Cross-CDM Joins and Refresh Rate Differentials

CDM refresh rates vary significantly by source:

| CDM | Refresh Frequency |
|---|---|
| CDM_TLM (Telemetry) | Every 30 minutes |
| CDM_MEDIA (Video Studio) | Near real-time |
| CDM_CLB (Class Collaborate) | Every 2 hours |
| CDM_MAP (Mapping) | Every 2 hours |
| CDM_ALY (Ally) | Every 12 hours |
| CDM_LMS (Blackboard Learn) | Overnight |
| CDM_SIS (Anthology Student) | Daily at 8:00 AM UTC |

Any entity created and deleted between refresh cycles will be invisible to that CDM entirely. When that entity already has activity captured in a higher-frequency CDM, joins across CDMs will produce unmatched records.

**Treat unmatched records in cross-CDM joins as an expected artifact of refresh rate differentials, not a data quality issue.** For example, a course that was created and deleted within a single day may appear in CDM_TLM telemetry but never in CDM_LMS — the course existed and was used, but the overnight LMS refresh never captured it.

Design cross-CDM queries with this in mind: use `LEFT JOIN` rather than `INNER JOIN` where completeness matters, and document the assumption in your query comments.
