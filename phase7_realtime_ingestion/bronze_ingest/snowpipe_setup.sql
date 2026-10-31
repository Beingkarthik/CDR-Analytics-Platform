-- Snowflake production adapter reference (configure storage integration/stage per your cloud account).
-- Raw landing is append-only. Snowpipe copies JSON events into Bronze and adds only ingestion timestamp.
CREATE OR REPLACE FILE FORMAT CDR_JSON_FORMAT TYPE = JSON STRIP_OUTER_ARRAY = FALSE;
-- Create an external stage with your cloud storage URL and storage integration:
-- CREATE OR REPLACE STAGE CDR_EVENT_STAGE URL='s3://YOUR_BUCKET/cdr/events/'
--   STORAGE_INTEGRATION=YOUR_STORAGE_INTEGRATION FILE_FORMAT=CDR_JSON_FORMAT;
CREATE TABLE IF NOT EXISTS BRONZE_CDR_EVENTS (
  RAW_EVENT VARIANT NOT NULL,
  INGEST_TIME TIMESTAMP_TZ NOT NULL DEFAULT CURRENT_TIMESTAMP()
);
-- After creating the stage, enable auto-ingest using your cloud notification integration:
-- CREATE OR REPLACE PIPE CDR_EVENTS_PIPE AUTO_INGEST=TRUE
--   AS COPY INTO BRONZE_CDR_EVENTS (RAW_EVENT)
--   FROM (SELECT $1 FROM @CDR_EVENT_STAGE)
--   FILE_FORMAT=(FORMAT_NAME=CDR_JSON_FORMAT);
-- Monitor with SYSTEM$PIPE_STATUS('CDR_EVENTS_PIPE') and COPY_HISTORY.
