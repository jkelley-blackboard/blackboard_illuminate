-- ============================================================
-- Ultra Activity Audit — Example: Who Deleted a Course Item
-- Companion to deleted_items_audit.sql: CDM_LMS.course_item only
-- records who *created* an item (person_id), not who deleted it.
-- This query uses Ultra Events telemetry to identify the user (and
-- click) behind a content deletion that deleted_items_audit.sql
-- can't answer on its own.
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
-- This query filters on both confirmation tags (2 and 4). The two are
-- not otherwise ambiguous with each other: the bulk-edit confirm tag
-- names "delete" explicitly, and the single-item confirm tag is
-- disambiguated by the course + day-of join to a row known to be
-- deleted in CDM_LMS rather than by the tag alone (it's shared by the
-- overflow menu's confirmation dialog generally). One bulk-delete
-- click can account for multiple deleted items on the same day —
-- that shows up here as the same click_time repeated across several
-- item_name rows, which is expected fan-out, not a duplicate bug.
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
  per.stage:user_id::text  AS clicked_by,                    -- NULL here likely means a preview user or other entity never snapshotted to CDM_LMS
  cor.course_number        AS bb_course_id,
  ci.name                  AS item_name,
  ci.item_type,
  ci.row_deleted_time      AS lms_deletion_snapshot_time,    -- when the nightly CDM_LMS snapshot first showed the item gone
  ue.event_type,
  ue.data:objectId::text   AS objectId,
  ue.event_time            AS click_time,
  --ue.data::text           -- uncomment to examine the full data object
FROM CDM_LMS.course_item ci
  JOIN CDM_LMS.course cor
    ON cor.id = ci.course_id
  JOIN CDM_TLM.ultra_events ue
    ON '_' || cor.source_id || '_1' = ue.data:contextId::text
   AND ue.event_time::date = DATE(ci.row_deleted_time) - 1   -- click happens the day before the LMS snapshot records the deletion
  LEFT JOIN CDM_LMS.person per
    ON per.stage:uuid::text = ue.data:userId::text
WHERE ci.row_deleted_time IS NOT NULL          -- only deleted items
  AND cor.course_number LIKE '%'               -- select course(s) by Blackboard course id
  AND ci.name LIKE '%'                         -- narrow to a specific item name if known
  AND ue.data:objectId::text IN (
        'components.directives.content-item-base.overflowMenu.confirm.button',           -- single-item delete confirmation
        'course.content.bulkEdit.panelFooter.dialog.dialogFooter.confirmButton.delete'    -- bulk-edit delete confirmation
      )
ORDER BY ci.row_deleted_time DESC, ue.event_time DESC;
