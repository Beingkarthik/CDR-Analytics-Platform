-- Phase 9: CDR Performance Optimization Log
-- Optimization 1: Disable result cache for comparable benchmark runs
ALTER SESSION SET USE_CACHED_RESULT = FALSE;

-- Optimization 2: Inspect query profile before changing SQL
-- Review bytes scanned, partitions scanned, and execution operators.

-- Optimization 3: Keep the existing X-Small warehouse and 60-second auto-suspend.
-- Avoid unnecessary warehouse scaling for the current small dataset.

-- Optimization 4: Filter query history to relevant CDR workloads.
SELECT
    QUERY_ID,
    QUERY_TYPE,
    EXECUTION_TIME,
    BYTES_SCANNED
FROM TABLE(
    CDR_ANALYTICS.INFORMATION_SCHEMA.QUERY_HISTORY(
        END_TIME_RANGE_START => DATEADD('HOUR', -24, CURRENT_TIMESTAMP()),
        RESULT_LIMIT => 100
    )
)
WHERE EXECUTION_STATUS = 'SUCCESS'
  AND (
      QUERY_TEXT ILIKE '%FACT_CDR_EVENTS%'
      OR QUERY_TEXT ILIKE '%RAW.CDR_RECORDS%'
  )
ORDER BY EXECUTION_TIME DESC;
