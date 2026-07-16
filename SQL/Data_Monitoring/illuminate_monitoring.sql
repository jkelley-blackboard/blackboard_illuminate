-- =============================================================================
-- Anthology Illuminate — CDM Insert Monitoring (with executive summary)
-- Copyright Blackboard, Inc. All rights reserved.
-- Author:  Jeff Kelley, Principal Solutions Engineer, Blackboard Inc.
--          jeff.kelley@blackboard.com
-- Date:    2026-03-26
-- Ref:     https://help.anthology.com/illuminate/en/anthology-illuminate-developer/
--          refresh-rates-for-illuminate-canonical-data-models.html
--
-- Provided as-is, without warranty. Not an Anthology product or support item.
-- health_status reflects observed insert cadence only — not platform health.
-- =============================================================================

WITH parameters AS (
    -- Tune these to adjust lookback window and time-bucket granularity
    SELECT
        5    AS days_back,
        5    AS minute_bucket,   -- bucket width for grouping inserts
        '1970-01-01'::TIMESTAMP AS epoch_ts  -- fixed epoch for deterministic bucketing
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
        ('CDM_TLM.ULTRA_EVENTS',          30,   2, 'SCHEDULED_BATCH_30M'),
        ('CDM_MEDIA.ACTIVITY',            15,   3, 'NEAR_REALTIME'),
        ('CDM_LMS.ACTIVITY',              1440, 1, 'DAILY_ETL'),
        ('CDM_MAP.COURSE',                120,  2, 'SCHEDULED_BATCH_2H'),
        ('CDM_ALY.CONTENT',               720,  2, 'SCHEDULED_BATCH_12H'),
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
),

-- =====================================================
-- Detail output (per-bucket, per-source)
-- =====================================================
detail AS (
    SELECT
        source_table,
        source_profile,
        new_records,
        bucket_ts,
        TO_CHAR(bucket_ts, 'Mon DD, YYYY HH24:MI')      AS bucket_time,
        TO_CHAR(bucket_ts, 'HH24:MI')
            || '–' ||
        TO_CHAR(DATEADD(minute, minute_bucket - 1, bucket_ts), 'HH24:MI')
            AS bucket_label,

        DATEDIFF(minute, prior_bucket_ts, bucket_ts)     AS minutes_since_prior_bucket,
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
),

-- =====================================================
-- Executive summary rollup (one row per source)
-- =====================================================
summary AS (
    SELECT
        source_table,
        source_profile,
        COUNT(*)                                                        AS total_buckets,
        SUM(new_records)                                                AS total_records,
        SUM(CASE WHEN gap_class = 'LARGE_GAP'             THEN 1 ELSE 0 END) AS large_gaps,
        SUM(CASE WHEN gap_class = 'MINOR_VARIANCE'        THEN 1 ELSE 0 END) AS minor_variances,
        SUM(CASE WHEN gap_class IN ('ON_EXPECTED_CADENCE',
                                    'DAILY_LOAD_WINDOW')  THEN 1 ELSE 0 END) AS on_time_buckets,
        MAX(bucket_ts)                                                  AS last_seen,
        MIN(CASE WHEN gap_class = 'LARGE_GAP'
                 THEN bucket_ts END)                                    AS first_large_gap_ts,

        -- Health score: % of buckets that were on time (ignoring FIRST_SEEN)
        ROUND(
            100.0 * SUM(CASE WHEN gap_class IN ('ON_EXPECTED_CADENCE','DAILY_LOAD_WINDOW')
                             THEN 1 ELSE 0 END)
            / NULLIF(SUM(CASE WHEN gap_class != 'FIRST_SEEN' THEN 1 ELSE 0 END), 0)
        , 1)                                                            AS pct_on_time,

        -- ANOMALY if any large gaps; VARIANCE if more than 2 minor variances; else NORMAL
        CASE
            WHEN SUM(CASE WHEN gap_class = 'LARGE_GAP'      THEN 1 ELSE 0 END) > 0 THEN 'ANOMALY'
            WHEN SUM(CASE WHEN gap_class = 'MINOR_VARIANCE' THEN 1 ELSE 0 END) > 2  THEN 'VARIANCE'
            ELSE 'NORMAL'
        END                                                             AS health_status

    FROM detail
    GROUP BY 1, 2
),

-- =====================================================
-- Fleet-wide single-line rollup
-- =====================================================
fleet_summary AS (
    SELECT
        'ALL SOURCES'              AS source_table,
        NULL                       AS source_profile,
        SUM(total_buckets)         AS total_buckets,
        SUM(total_records)         AS total_records,
        SUM(large_gaps)            AS large_gaps,
        SUM(minor_variances)       AS minor_variances,
        SUM(on_time_buckets)       AS on_time_buckets,
        MAX(last_seen)             AS last_seen,
        MIN(first_large_gap_ts)    AS first_large_gap_ts,
        ROUND(AVG(pct_on_time), 1) AS pct_on_time,
        -- Explicit worst-case roll-up; alphabetical MAX not reliable with these labels
        CASE
            WHEN SUM(CASE WHEN health_status = 'ANOMALY'  THEN 1 ELSE 0 END) > 0 THEN 'ANOMALY'
            WHEN SUM(CASE WHEN health_status = 'VARIANCE' THEN 1 ELSE 0 END) > 0 THEN 'VARIANCE'
            ELSE 'NORMAL'
        END                        AS health_status
    FROM summary
)

-- =====================================================
-- Final output: per-source summary + fleet rollup
-- Swap this SELECT for "SELECT * FROM detail" for row-level view
-- =====================================================
SELECT * FROM summary
UNION ALL
SELECT * FROM fleet_summary
ORDER BY health_status DESC, source_table;
