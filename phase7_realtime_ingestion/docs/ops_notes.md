# Operations Notes — Phase 7

## Start
1. Activate the project's virtual environment and install requirements.
2. Start `python -m bronze_ingest.local_stream` in one terminal.
3. Start the producer in another terminal.
4. Confirm `data/bronze/events.jsonl` grows and `data/checkpoint.offset` increases.

## Restart / checkpoint replay
- Stop the consumer with Ctrl+C; do not delete the checkpoint.
- Restart with `python -m bronze_ingest.local_stream`.
- It seeks to the saved byte offset and continues from the next unprocessed complete line.
- To replay from the beginning in a controlled test, stop the consumer, back up outputs, then remove `data/checkpoint.offset`. Do not do this in production without deduplication and reconciliation controls.

## Checks after restart
- Compare input byte offset with `data/checkpoint.offset`.
- Verify Bronze count only grows by new input events, not by replayed lines.
- Check Silver uniqueness: `SELECT cdr_id, COUNT(*) FROM silver_cdr GROUP BY cdr_id HAVING COUNT(*) > 1;`
- Run `python scripts/reconcile.py`.
- Inspect `stream_audit` for `ignored` rows (duplicates/older versions).

## Incident response
- If the consumer stops, preserve input, Bronze, DB and checkpoint files before repair.
- A malformed JSON line stops processing at that line and does not advance the checkpoint past it. Fix/quarantine the line before restarting.
- For production Snowflake, inspect `SYSTEM$PIPE_STATUS`, COPY_HISTORY, task history, warehouse errors and storage notification delivery.
