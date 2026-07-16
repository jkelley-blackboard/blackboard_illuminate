-- =============================================================================
-- Anthology Illuminate — CDM Insert Monitoring (QuickSight dataset variant)
-- Copyright Blackboard, Inc. All rights reserved.
-- Author:  Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date:    2026-03-26
-- Ref:     https://help.anthology.com/illuminate/en/anthology-illuminate-developer/
--          refresh-rates-for-illuminate-canonical-data-models.html
--
-- Provided as-is, without warranty. Not an Anthology product or support item.
-- gap_class reflects observed insert cadence only — not platform health.
--
-- QUICKSIGHT NOTES:
--   Intended for use as a QuickSight custom SQL dataset (Direct Query mode).
--   Differences from illuminate_monitoring_detail.sql:
--     - Lookback window extended to 30 days; use QuickSight date filters
--       to narrow the visible range on dashboards
--     - bucket_time and bucket_label display columns removed; apply date
--       formatting natively in QuickSight field settings
-- =============================================================================

WITH parameters AS (
    -- Extended to 30 days for QuickSight; use date filter controls to slice
    SELECT
        30   AS days_back,
        5    AS minute_bucket,
        '1970-01-01'::TIMESTAMP AS epoch_ts
),

date_window AS (
    SELECT
        DATEADD(day, -days_back, CURRENT_TIMESTAMP()) AS start_ts,
        minute_bucket,
        epoch_ts
    FROM parameters
),

-- =====================================================
-- Source configuration (cadence expectations)
-- Each source declares its own expected gap and variance
-- tolerance; add new sources here AND in all_events_raw
-- =====================================================
source_config AS (
    SELECT
        column1 AS source_table,
        column2 AS expected_gap_minutes,
        column3 AS small_gap_multiplier,  -- acceptable gap = expected * this
        column4 AS source_profile
    FROM VALUES
        ('CDM_TLM.ULTRA_EVENTS',                  30,   2, 'SCHEDULED_BATCH_30M'),
        ('CDM_MEDIA.ACTIVITY',                    15,   3, 'NEAR_REALTIME'),
        ('CDM_LMS.ACTIVITY',                      1440, 1, 'DAILY_ETL'),
        ('CDM_MAP.COURSE',                        120,  2, 'SCHEDULED_BATCH_2H'),
        ('CDM_ALY.CONTENT',                       720,  2, 'SCHEDULED_BATCH_12H'),
        -- LEARN schema requires Illuminate Premium. Comment out the line below
        -- (and the matching UNION ALL block in all_events_raw) if not licensed.
        ('LEARN.ACTIVITY_ACCUMULATOR_ARCHIVE',    240,  2, 'SCHEDULED_BATCH_4H')
),

-- =====================================================
-- Physical event union
-- Snowflake doesn't support dynamic table references, so
-- each source must be unioned explicitly. Keep in sync
-- with source_config above.
-- =====================================================
all_events_raw AS (
    SELECT 'CDM_TLM.ULTRA_EVENTS' AS source_table, ROW_INSERTED_TIME AS event_ts
    FROM cdm_tlm.ultra_events
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)

    UNION ALL
    SELECT 'CDM_MEDIA.ACTIVITY', ROW_INSERTED_TIME
    FROM cdm_media.activity
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)

    UNION ALL
    SELECT 'CDM_LMS.ACTIVITY', ROW_INSERTED_TIME
    FROM cdm_lms.activity
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)

    UNION ALL
    SELECT 'CDM_MAP.COURSE', ROW_INSERTED_TIME
    FROM cdm_map.course
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)

    UNION ALL
    SELECT 'CDM_ALY.CONTENT', ROW_INSERTED_TIME
    FROM cdm_aly.content
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)

    -- LEARN schema requires Illuminate Premium. Comment out this block
    -- (and the matching row in source_config) if not licensed.
    UNION ALL
    SELECT 'LEARN.ACTIVITY_ACCUMULATOR_ARCHIVE', ROW_INSERTED_TIME
    FROM learn.activity_accumulator_archive
    WHERE ROW_INSERTED_TIME >= (SELECT start_ts FROM date_window)
),

-- Join raw events to their cadence metadata
all_events AS (
    SELECT
        e.source_table,
        e.event_ts,
        c.expected_gap_minutes,
        c.small_gap_multiplier,
        c.source_profile
    FROM all_events_raw e
    JOIN source_config c ON e.source_table = c.source_table
),

-- Snap each event timestamp to the nearest minute_bucket boundary
bucketed AS (
    SELECT
        e.source_table,
        e.expected_gap_minutes,
        e.small_gap_multiplier,
        e.source_profile,

        DATEADD(
            minute,
            FLOOR(DATEDIFF(minute, d.epoch_ts, e.event_ts) / d.minute_bucket) * d.minute_bucket,
            d.epoch_ts
        ) AS bucket_ts,

        COUNT(*) AS new_records
    FROM all_events e
    CROSS JOIN date_window d   -- scalar pull; date_window must remain single-row
    GROUP BY 1,2,3,4,5
),

-- Attach prior bucket timestamp for gap calculation
final AS (
    SELECT
        b.*,
        d.minute_bucket,
        LAG(bucket_ts) OVER (
            PARTITION BY source_table
            ORDER BY bucket_ts
        ) AS prior_bucket_ts
    FROM bucketed b
    CROSS JOIN date_window d   -- scalar pull; date_window must remain single-row
)

-- bucket_time and bucket_label omitted; format bucket_ts in QuickSight field settings
SELECT
    source_table,
    source_profile,
    new_records,
    bucket_ts,
    DATEDIFF(minute, prior_bucket_ts, bucket_ts)  AS minutes_since_prior_bucket,
    expected_gap_minutes,

    CASE
        WHEN prior_bucket_ts IS NULL
            THEN 'FIRST_SEEN'

        -- Tolerate ±60 min drift around the 24h mark for daily ETL jobs
        WHEN source_profile = 'DAILY_ETL'
             AND DATEDIFF(minute, prior_bucket_ts, bucket_ts) BETWEEN 1380 AND 1500
            THEN 'DAILY_LOAD_WINDOW'

        -- Within one bucket-width of the expected cadence = on time
        WHEN ABS(DATEDIFF(minute, prior_bucket_ts, bucket_ts) - expected_gap_minutes)
             <= minute_bucket
            THEN 'ON_EXPECTED_CADENCE'

        -- Gap exceeded expected but within the per-source tolerance multiplier
        WHEN DATEDIFF(minute, prior_bucket_ts, bucket_ts)
             <= expected_gap_minutes * small_gap_multiplier
            THEN 'MINOR_VARIANCE'

        ELSE 'LARGE_GAP'
    END AS gap_class

FROM final
ORDER BY source_table, bucket_ts DESC;
