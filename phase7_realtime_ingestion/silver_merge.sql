-- Snowflake SQL. Expected event schema is carried in RAW_EVENT (VARIANT) in Bronze.
-- A record is newer only when its event_time is greater than the current Silver event_time.
MERGE INTO SILVER_CDR_EVENTS AS target
USING (
  SELECT
    RAW_EVENT:cdr_id::STRING AS cdr_id,
    RAW_EVENT:event_id::STRING AS event_id,
    RAW_EVENT:subscriber_id::STRING AS subscriber_id,
    RAW_EVENT:call_type::STRING AS call_type,
    RAW_EVENT:start_timestamp::TIMESTAMP_TZ AS start_timestamp,
    RAW_EVENT:end_timestamp::TIMESTAMP_TZ AS end_timestamp,
    RAW_EVENT:duration_seconds::NUMBER AS duration_seconds,
    RAW_EVENT:estimated_charge_pence::NUMBER(12,2) AS estimated_charge_pence,
    RAW_EVENT:event_time::TIMESTAMP_TZ AS event_time,
    RAW_EVENT:source_sequence::NUMBER AS source_sequence,
    INGEST_TIME AS ingest_time
  FROM BRONZE_CDR_EVENTS
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY RAW_EVENT:cdr_id::STRING
    ORDER BY RAW_EVENT:event_time::TIMESTAMP_TZ DESC, INGEST_TIME DESC
  ) = 1
) AS source
ON target.cdr_id = source.cdr_id
WHEN MATCHED AND source.event_time > target.event_time THEN UPDATE SET
  event_id=source.event_id, subscriber_id=source.subscriber_id, call_type=source.call_type,
  start_timestamp=source.start_timestamp, end_timestamp=source.end_timestamp,
  duration_seconds=source.duration_seconds, estimated_charge_pence=source.estimated_charge_pence,
  event_time=source.event_time, source_sequence=source.source_sequence, ingest_time=source.ingest_time
WHEN NOT MATCHED THEN INSERT
  (cdr_id,event_id,subscriber_id,call_type,start_timestamp,end_timestamp,duration_seconds,
   estimated_charge_pence,event_time,source_sequence,ingest_time)
VALUES
  (source.cdr_id,source.event_id,source.subscriber_id,source.call_type,source.start_timestamp,
   source.end_timestamp,source.duration_seconds,source.estimated_charge_pence,source.event_time,
   source.source_sequence,source.ingest_time);
