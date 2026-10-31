-- Basic source-to-target reconciliation
SELECT COUNT(*) AS target_count
FROM fact_cdr_events;

-- Compare this with the cleansed source count produced by Phase 4.
