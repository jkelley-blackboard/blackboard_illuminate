-- ============================================================
-- Ultra Activity Audit — Example: Who Deleted a Course Item
-- Companion to deleted_items_audit.sql: CDM_LMS.course_item only
-- records who *created* an item (person_id), not who deleted it.
-- This query uses Ultra Events telemetry to identify the user(s)
-- behind a content deletion that deleted_items_audit.sql can't
-- answer on its own.
--
-- Author : Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date   : 2026-07-21
-- (c) Blackboard Inc. All rights reserved.
-- Provided as-is without support or warranty of any kind.
--
-- NOTE ON THE objectId FILTER: Ultra has two separate UI flows for
-- deleting content, each ending in its own confirmation tag. Only the
-- confirmation click of each flow reliably corresponds to a completed
-- deletion — earlier clicks in the flow just open a menu or a
-- selection state the user could still back out of:
--
--   Single-item delete (via the item's overflow menu):
--     1. components.directives.content-item-base.overflowMenu.global.delete.link
--     2. components.directives.content-item-base.overflowMenu.confirm.button  <- filtered on below
--
--   Bulk delete (via Course Content > Bulk Edit):
--     1. course.outline.copyDetails.overflowMenu.menu.course.outline.bulkEditLink.link  — enters bulk-edit mode
--     2. course.content.bulkEdit.table.ContentTable.sortableTable.tableBody.tableBody.tableRowContainer.tableRow.tableRow.cell.tableRowCell.checkbox.select.checkbox  — checks an item's box (fires once per item selected)
--     3. course.content.bulkEdit.panelFooter.actions.delete  — clicks the delete action on the bulk-edit panel
--     4. course.content.bulkEdit.panelFooter.dialog.dialogFooter.confirmButton.delete  <- filtered on below
--
-- WHY THIS QUERY CANNOT PIN ONE CLICK TO ONE ITEM: confirmed against
-- real telemetry, both confirmation events carry an empty
-- interactionContext — the click payload never names *which* item was
-- deleted, only the course (contextId). And CDM_LMS.course_item's
-- row_deleted_time is snapshot-day granularity: every item deleted on
-- the same calendar day gets the exact same timestamp (the nightly
-- snapshot run), not the moment it was actually deleted. So there is
-- no key, in either table, that ties a specific item to a specific
-- click — only "this course, this day" is knowable.
--
-- Rather than fake a row-level join (which silently cross-multiplies
-- every item deleted that day against every delete-confirmation click
-- that day — e.g. 13 items x 3 single-item clicks = 39 misleading
-- rows, each implying a pairing that isn't real), this query
-- aggregates to what the data actually supports: per deleted item,
-- the set of users who confirmed *a* deletion in that course that
-- day, and how many confirmation clicks happened. One candidate is a
-- confident answer. More than one means the day had multiple deleters
-- active and you cannot tell from this data alone who deleted which
-- item — cross-check IP address / sessionId / interactionUrl timing
-- via the commented-out ue.data::text column, or narrow the course/
-- item filters to isolate a single incident.
--
-- NOTE ON THE TIME WINDOW: CDM_LMS refreshes overnight, so
-- ci.row_deleted_time reflects when the nightly snapshot first
-- showed the item gone — one day after the actual delete click (see
-- deleted_items_audit.sql). This query looks for telemetry on the
-- day before that snapshot. If your join comes back empty, widen the
-- window (e.g. BETWEEN DATE(ci.row_deleted_time) - 2 AND
-- DATE(ci.row_deleted_time)) before assuming there's no match.
--
-- NOTE ON THE LEFT JOIN to person: preview users and other ephemeral
-- LMS entities can generate telemetry but never appear in a nightly
-- CDM_LMS.PERSON snapshot. Left join and inspect NULLs rather than
-- inner-joining and silently dropping them — see docs/best-practices.md.
-- ============================================================

SELECT
  cor.course_number        AS bb_course_id,
  ci.name                  AS item_name,
  ci.item_type,
  ci.row_deleted_time      AS lms_deletion_snapshot_time,    -- when the nightly CDM_LMS snapshot first showed the item gone
  LISTAGG(DISTINCT per.stage:user_id::text, ', ')
    WITHIN GROUP (ORDER BY per.stage:user_id::text) AS candidate_deleters,  -- one name = confident answer; multiple = see note above
  COUNT(DISTINCT ue.data:eventId::text) AS delete_confirm_clicks_that_day, -- distinct confirmation clicks in this course that day (not a per-item count)
  MIN(ue.event_time)       AS earliest_click_time,
  MAX(ue.event_time)       AS latest_click_time
  --, ue.data::text          -- uncomment (and remove aggregation) to examine individual event payloads
FROM CDM_LMS.course_item ci
  JOIN CDM_LMS.course cor
    ON cor.id = ci.course_id
  JOIN CDM_TLM.ultra_events ue
    ON '_' || cor.source_id || '_1' = ue.data:contextId::text
   AND ue.event_time::date = DATE(ci.row_deleted_time) - 1   -- click happens the day before the LMS snapshot records the deletion
  LEFT JOIN CDM_LMS.person per
    ON per.stage:uuid::text = ue.data:userId::text            -- NULL candidate likely means a preview user or other entity never snapshotted to CDM_LMS
WHERE ci.row_deleted_time IS NOT NULL          -- only deleted items
  AND cor.course_number LIKE '%'               -- select course(s) by Blackboard course id
  AND ci.name LIKE '%'                         -- narrow to a specific item name if known
  AND ue.data:objectId::text IN (
        'components.directives.content-item-base.overflowMenu.confirm.button',           -- single-item delete confirmation
        'course.content.bulkEdit.panelFooter.dialog.dialogFooter.confirmButton.delete'    -- bulk-edit delete confirmation
      )
GROUP BY cor.course_number, ci.name, ci.item_type, ci.row_deleted_time
ORDER BY ci.row_deleted_time DESC;
