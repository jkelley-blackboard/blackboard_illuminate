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

The practical risk is concentrated at the **CDM_TLM → CDM_LMS join boundary**, where a 30-minute telemetry stream references entities that are only snapshotted once nightly. Ephemeral LMS entities — student preview users being the most common example — can generate substantial telemetry that will never resolve to a CDM_LMS record. Outer joins with null awareness are always safer than inner joins across this boundary.

**Example:** An instructor creates a Student Preview user in Blackboard Ultra at 9:00 AM, browses the course as a student for 30 minutes, then deletes the preview user at 9:45 AM. CDM_TLM will capture all of this activity within the next 30-minute refresh cycle, recording page views, clicks, and interactions under the preview user's UUID. However, when CDM_LMS runs its nightly snapshot, the preview user no longer exists in the LMS and is never written to `CDM_LMS.PERSON`. Any query that inner joins `CDM_TLM.ULTRA_EVENTS` to `CDM_LMS.PERSON` on the user UUID will silently drop these events — not because the data is wrong, but because the entity was ephemeral.

In a unique user count or engagement report, an inner join produces an accurate-looking result that is actually understating activity. Using a left join with a `WHERE p.id IS NULL` check makes the gap visible and allows the analyst to categorize and exclude preview activity explicitly rather than losing it silently.
