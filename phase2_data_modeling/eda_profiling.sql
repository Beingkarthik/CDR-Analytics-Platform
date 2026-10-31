-- ============================================================
-- Phase 2 Task 1 — EDA Profiling SQL
-- Project: Telecom Data Engineering
-- Datasets: cdr_records, fraud_labels, fraud_simulation_patterns,
--           rated_cdrs, roaming_cdrs, subscriber_plans,
--           switch_reconciliation, tariff_tables
-- PostgreSQL 15+
-- ============================================================

-- ============================================================
-- 0. TABLE LOAD NOTES
-- ============================================================
-- Load order (respects FK dependencies):
--   1. subscriber_plans
--   2. tariff_tables
--   3. cdr_records
--   4. rated_cdrs
--   5. fraud_labels
--   6. fraud_simulation_patterns
--   7. switch_reconciliation
--   8. roaming_cdrs  (loaded from XML via python ETL or pg_read_file)

-- ============================================================
-- 1. CDR_RECORDS
-- ============================================================

-- 1.1 Row count
SELECT COUNT(*) AS row_count FROM cdr_records;

-- 1.2 Null rates per column
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE cdr_id IS NULL)               / COUNT(*), 2) AS cdr_id_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE subscriber_id IS NULL)        / COUNT(*), 2) AS subscriber_id_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE call_type IS NULL)            / COUNT(*), 2) AS call_type_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE originating_number IS NULL)   / COUNT(*), 2) AS originating_number_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE terminating_number IS NULL)   / COUNT(*), 2) AS terminating_number_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE start_timestamp IS NULL)      / COUNT(*), 2) AS start_timestamp_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE end_timestamp IS NULL)        / COUNT(*), 2) AS end_timestamp_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE duration_seconds IS NULL)     / COUNT(*), 2) AS duration_seconds_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE estimated_charge_pence IS NULL)/ COUNT(*), 2) AS charge_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE plan_id IS NULL)              / COUNT(*), 2) AS plan_id_null_pct
FROM cdr_records;

-- 1.3 Duplicate full rows
SELECT COUNT(*) - COUNT(DISTINCT (cdr_id, subscriber_id, start_timestamp, end_timestamp)) AS duplicate_rows
FROM cdr_records;

-- 1.4 Duplicate cdr_id (business key)
SELECT COUNT(*) AS duplicate_cdr_ids
FROM (
    SELECT cdr_id FROM cdr_records GROUP BY cdr_id HAVING COUNT(*) > 1
) t;

-- 1.5 Numeric stats
SELECT
    MIN(duration_seconds)        AS dur_min,
    MAX(duration_seconds)        AS dur_max,
    ROUND(AVG(duration_seconds)::numeric, 2) AS dur_mean,
    MIN(data_volume_mb)          AS data_min,
    MAX(data_volume_mb)          AS data_max,
    ROUND(AVG(data_volume_mb)::numeric, 2)   AS data_mean,
    MIN(estimated_charge_pence)  AS charge_min,
    MAX(estimated_charge_pence)  AS charge_max,
    ROUND(AVG(estimated_charge_pence)::numeric, 2) AS charge_mean
FROM cdr_records;

-- 1.6 Impossible values
SELECT
    COUNT(*) FILTER (WHERE duration_seconds < 0)         AS negative_duration,
    COUNT(*) FILTER (WHERE duration_seconds > 86400)     AS duration_over_24h,
    COUNT(*) FILTER (WHERE estimated_charge_pence < 0)   AS negative_charge,
    COUNT(*) FILTER (WHERE start_timestamp::timestamptz > end_timestamp::timestamptz) AS end_before_start,
    COUNT(*) FILTER (WHERE start_timestamp IS NULL)      AS null_start_ts
FROM cdr_records;

-- 1.7 Inconsistent call_type casing
SELECT call_type, COUNT(*) AS cnt
FROM cdr_records
GROUP BY call_type
ORDER BY cnt DESC;

-- 1.8 Distinct categorical values
SELECT 'call_direction' AS col, call_direction AS val, COUNT(*) AS cnt FROM cdr_records GROUP BY call_direction
UNION ALL
SELECT 'rat_type', rat_type, COUNT(*) FROM cdr_records GROUP BY rat_type
UNION ALL
SELECT 'termination_cause', termination_cause, COUNT(*) FROM cdr_records GROUP BY termination_cause
ORDER BY col, cnt DESC;

-- 1.9 Referential integrity: plan_id FK to subscriber_plans
SELECT COUNT(DISTINCT c.plan_id) AS orphan_plan_ids
FROM cdr_records c
LEFT JOIN subscriber_plans sp ON c.plan_id = sp.plan_id
WHERE sp.plan_id IS NULL;

-- ============================================================
-- 2. FRAUD_LABELS
-- ============================================================

-- 2.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT fraud_id) AS distinct_fraud_ids,
    ROUND(100.0 * COUNT(*) FILTER (WHERE notes IS NULL) / COUNT(*), 2)        AS notes_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE scd_end_date IS NULL) / COUNT(*), 2) AS scd_end_null_pct
FROM fraud_labels;

-- 2.2 Duplicate full rows
SELECT COUNT(*) - COUNT(DISTINCT (fraud_id, scd_version)) AS duplicate_rows
FROM fraud_labels;

-- 2.3 SCD integrity: fraud_ids with more than one current version
SELECT fraud_id, SUM(scd_current) AS current_count
FROM fraud_labels
GROUP BY fraud_id
HAVING SUM(scd_current) > 1;

-- 2.4 SCD integrity: fraud_ids with no current version
SELECT fraud_id, SUM(scd_current) AS current_count
FROM fraud_labels
GROUP BY fraud_id
HAVING SUM(scd_current) = 0;

-- 2.5 Inconsistent fraud_type casing
SELECT fraud_type, COUNT(*) AS cnt
FROM fraud_labels
GROUP BY fraud_type
ORDER BY cnt DESC;

-- 2.6 Impossible: negative financial impact
SELECT COUNT(*) AS negative_financial_impact
FROM fraud_labels
WHERE financial_impact_gbp < 0;

-- 2.7 Status distribution
SELECT status, COUNT(*) FROM fraud_labels GROUP BY status ORDER BY COUNT(*) DESC;

-- ============================================================
-- 3. FRAUD_SIMULATION_PATTERNS
-- ============================================================

-- 3.1 Row count and nulls
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT pattern_id) AS distinct_patterns,
    COUNT(*) FILTER (WHERE avg_call_duration_seconds < 0) AS negative_avg_duration,
    COUNT(*) FILTER (WHERE detection_threshold_score < 0) AS negative_threshold_score,
    COUNT(*) FILTER (WHERE detection_threshold_score > 1) AS threshold_over_1
FROM fraud_simulation_patterns;

-- 3.2 Inconsistent confirmed_fraud_flag values
SELECT confirmed_fraud_flag, COUNT(*) AS cnt
FROM fraud_simulation_patterns
GROUP BY confirmed_fraud_flag
ORDER BY cnt DESC;

-- 3.3 Inconsistent fraud_type casing
SELECT fraud_type, COUNT(*) AS cnt
FROM fraud_simulation_patterns
GROUP BY fraud_type
ORDER BY cnt DESC;

-- 3.4 Numeric stats
SELECT
    MIN(avg_call_duration_seconds) AS dur_min,
    MAX(avg_call_duration_seconds) AS dur_max,
    ROUND(AVG(avg_call_duration_seconds)::numeric, 2) AS dur_mean,
    MIN(call_volume_per_hour) AS vol_min,
    MAX(call_volume_per_hour) AS vol_max,
    ROUND(AVG(call_volume_per_hour)::numeric, 2) AS vol_mean,
    MIN(detection_threshold_score) AS thresh_min,
    MAX(detection_threshold_score) AS thresh_max
FROM fraud_simulation_patterns;

-- 3.5 Referential integrity: linked_subscriber_id vs fraud_labels
SELECT COUNT(DISTINCT fsp.linked_subscriber_id) AS orphan_subscriber_ids
FROM fraud_simulation_patterns fsp
LEFT JOIN fraud_labels fl ON fsp.linked_subscriber_id = fl.subscriber_id
WHERE fl.subscriber_id IS NULL;

-- ============================================================
-- 4. RATED_CDRs
-- ============================================================

-- 4.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT rated_id) AS distinct_rated_ids,
    ROUND(100.0 * COUNT(*) FILTER (WHERE charge_pence IS NULL) / COUNT(*), 2) AS charge_null_pct
FROM rated_cdrs;

-- 4.2 Duplicate cdr_id (one CDR rated more than once)
SELECT COUNT(*) AS duplicate_cdr_ratings
FROM (
    SELECT cdr_id FROM rated_cdrs GROUP BY cdr_id HAVING COUNT(*) > 1
) t;

-- 4.3 Impossible values
SELECT
    COUNT(*) FILTER (WHERE charge_pence < 0)                      AS negative_charges,
    COUNT(*) FILTER (WHERE billable_duration_seconds < 0)         AS negative_billable_dur,
    COUNT(*) FILTER (WHERE rated_correctly_flag = 0)              AS incorrect_ratings
FROM rated_cdrs;

-- 4.4 Inconsistent time_band casing
SELECT time_band_applied, COUNT(*) AS cnt
FROM rated_cdrs
GROUP BY time_band_applied
ORDER BY cnt DESC;

-- 4.5 Referential integrity: cdr_id FK to cdr_records
SELECT COUNT(DISTINCT r.cdr_id) AS orphan_cdr_ids
FROM rated_cdrs r
LEFT JOIN cdr_records c ON r.cdr_id = c.cdr_id
WHERE c.cdr_id IS NULL;

-- 4.6 CDRs in cdr_records with no rating
SELECT COUNT(*) AS unrated_cdrs
FROM cdr_records c
LEFT JOIN rated_cdrs r ON c.cdr_id = r.cdr_id
WHERE r.cdr_id IS NULL;

-- 4.7 Referential integrity: tariff_id FK to tariff_tables
SELECT COUNT(DISTINCT r.tariff_id) AS orphan_tariff_ids
FROM rated_cdrs r
LEFT JOIN tariff_tables tt ON r.tariff_id = tt.tariff_id
WHERE tt.tariff_id IS NULL;

-- ============================================================
-- 5. ROAMING_CDRs (loaded as roaming_cdrs table from XML ETL)
-- ============================================================

-- 5.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE calling_number IS NULL)     / COUNT(*), 2) AS calling_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE destination_number IS NULL) / COUNT(*), 2) AS destination_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE event_start IS NULL)        / COUNT(*), 2) AS event_start_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE partner_id IS NULL)         / COUNT(*), 2) AS partner_id_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE roaming_country IS NULL)    / COUNT(*), 2) AS country_null_pct
FROM roaming_cdrs;

-- 5.2 Duplicate full rows
SELECT COUNT(*) - COUNT(DISTINCT (served_imsi, event_start, record_type)) AS duplicate_rows
FROM roaming_cdrs;

-- 5.3 Impossible values
SELECT
    COUNT(*) FILTER (WHERE total_call_event_duration < 0) AS negative_duration,
    COUNT(*) FILTER (WHERE charge_amount < 0)              AS negative_charge
FROM roaming_cdrs;

-- 5.4 Record type distribution
SELECT record_type, COUNT(*) AS cnt
FROM roaming_cdrs
GROUP BY record_type
ORDER BY cnt DESC;

-- 5.5 Numeric stats
SELECT
    MIN(total_call_event_duration) AS dur_min,
    MAX(total_call_event_duration) AS dur_max,
    ROUND(AVG(total_call_event_duration)::numeric, 4) AS dur_mean,
    MIN(charge_amount)  AS charge_min,
    MAX(charge_amount)  AS charge_max,
    ROUND(AVG(charge_amount)::numeric, 4)  AS charge_mean
FROM roaming_cdrs;

-- 5.6 Referential integrity: served_imsi vs cdr_records.imsi
SELECT COUNT(DISTINCT r.served_imsi) AS orphan_imsi_count
FROM roaming_cdrs r
LEFT JOIN cdr_records c ON r.served_imsi::bigint = c.imsi
WHERE c.imsi IS NULL;

-- ============================================================
-- 6. SUBSCRIBER_PLANS
-- ============================================================

-- 6.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT plan_id) AS distinct_plans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE free_data_gb IS NULL)   / COUNT(*), 2) AS free_data_null_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE monthly_fee_gbp IS NULL)/ COUNT(*), 2) AS fee_null_pct
FROM subscriber_plans;

-- 6.2 Duplicate plan_id (business key)
SELECT plan_id, COUNT(*) AS cnt
FROM subscriber_plans
GROUP BY plan_id
HAVING COUNT(*) > 1;

-- 6.3 Impossible values
SELECT
    COUNT(*) FILTER (WHERE rate_per_minute_pence < 0) AS negative_rate,
    COUNT(*) FILTER (WHERE monthly_fee_gbp < 0)       AS negative_fee
FROM subscriber_plans;

-- 6.4 Plan categories
SELECT plan_category, COUNT(*) FROM subscriber_plans GROUP BY plan_category ORDER BY COUNT(*) DESC;

-- ============================================================
-- 7. SWITCH_RECONCILIATION
-- ============================================================

-- 7.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    ROUND(100.0 * COUNT(*) FILTER (WHERE missing_count < 0)  / COUNT(*), 2) AS negative_missing_pct,
    ROUND(100.0 * COUNT(*) FILTER (WHERE loss_rate_pct > 5)  / COUNT(*), 2) AS high_loss_pct
FROM switch_reconciliation;

-- 7.2 Reconciliation status distribution
SELECT reconciliation_status, COUNT(*) FROM switch_reconciliation GROUP BY reconciliation_status ORDER BY COUNT(*) DESC;

-- 7.3 SLA met flag distribution
SELECT sla_met_flag, COUNT(*) FROM switch_reconciliation GROUP BY sla_met_flag;

-- 7.4 Impossible values
SELECT
    COUNT(*) FILTER (WHERE missing_count < 0)    AS negative_missing_count,
    COUNT(*) FILTER (WHERE received_cdr_count < 0) AS negative_received
FROM switch_reconciliation;

-- 7.5 Numeric stats
SELECT
    MIN(loss_rate_pct) AS loss_min,
    MAX(loss_rate_pct) AS loss_max,
    ROUND(AVG(loss_rate_pct)::numeric, 4) AS loss_mean,
    MIN(missing_count) AS missing_min,
    MAX(missing_count) AS missing_max
FROM switch_reconciliation;

-- 7.6 Switch vendor breakdown
SELECT switch_vendor, COUNT(*) FROM switch_reconciliation GROUP BY switch_vendor;

-- ============================================================
-- 8. TARIFF_TABLES
-- ============================================================

-- 8.1 Row count and null rates
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT tariff_id) AS distinct_tariffs,
    ROUND(100.0 * COUNT(*) FILTER (WHERE number_prefix IS NULL) / COUNT(*), 2) AS prefix_null_pct
FROM tariff_tables;

-- 8.2 Duplicate full rows
SELECT COUNT(*) - COUNT(DISTINCT tariff_id) AS duplicate_rows
FROM tariff_tables;

-- 8.3 Impossible values
SELECT
    COUNT(*) FILTER (WHERE rate_per_minute_pence < 0) AS negative_rate,
    COUNT(*) FILTER (WHERE surcharge_pence < 0)       AS negative_surcharge
FROM tariff_tables;

-- 8.4 Destination type distribution
SELECT destination_type, COUNT(*) FROM tariff_tables GROUP BY destination_type ORDER BY COUNT(*) DESC;

-- 8.5 Time band / day type distribution
SELECT time_band, day_type, COUNT(*) FROM tariff_tables GROUP BY time_band, day_type ORDER BY time_band, day_type;

-- 8.6 Numeric stats
SELECT
    MIN(rate_per_minute_pence) AS rate_min,
    MAX(rate_per_minute_pence) AS rate_max,
    ROUND(AVG(rate_per_minute_pence)::numeric, 4) AS rate_mean,
    MIN(surcharge_pence) AS surcharge_min,
    MAX(surcharge_pence) AS surcharge_max
FROM tariff_tables;

-- ============================================================
-- END OF EDA PROFILING SQL
-- ============================================================
