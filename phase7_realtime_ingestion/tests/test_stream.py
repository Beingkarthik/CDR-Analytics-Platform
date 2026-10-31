import json, os, subprocess, sys
from pathlib import Path

def setup_env(tmp_path, monkeypatch):
    incoming = tmp_path / "incoming.jsonl"
    bronze = tmp_path / "bronze.jsonl"
    db = tmp_path / "test.db"
    checkpoint = tmp_path / "offset"
    monkeypatch.setenv("CDR_INPUT_FILE", str(incoming))
    monkeypatch.setenv("CDR_BRONZE_FILE", str(bronze))
    monkeypatch.setenv("CDR_DB", str(db))
    monkeypatch.setenv("CDR_CHECKPOINT", str(checkpoint))
    # Module reads env at import, so reload after setting variables.
    import importlib
    import bronze_ingest.local_stream as stream
    importlib.reload(stream)
    return stream, incoming, bronze, db, checkpoint

def event(cdr_id, event_time, event_id):
    return {"event_id":event_id,"cdr_id":cdr_id,"subscriber_id":"SUB1","call_type":"VOICE MO",
            "start_timestamp":event_time,"end_timestamp":event_time,"duration_seconds":10,
            "estimated_charge_pence":1.25,"event_time":event_time,"source_sequence":1}

def test_no_duplicate_keys_in_silver(tmp_path, monkeypatch):
    stream, incoming, bronze, db, checkpoint = setup_env(tmp_path, monkeypatch)
    rows = [event("CDR1","2026-10-29T10:00:00+00:00","e1"),
            event("CDR1","2026-10-29T10:00:00+00:00","e1dup"),
            event("CDR2","2026-10-29T10:01:00+00:00","e2")]
    incoming.write_text("".join(json.dumps(x)+"\n" for x in rows))
    assert stream.process_available() == 3
    import sqlite3
    with sqlite3.connect(db) as con:
        count, distinct_count = con.execute("SELECT COUNT(*), COUNT(DISTINCT cdr_id) FROM silver_cdr").fetchone()
    assert count == distinct_count == 2

def test_reconciliation_counts_are_queryable(tmp_path, monkeypatch):
    stream, incoming, bronze, db, checkpoint = setup_env(tmp_path, monkeypatch)
    rows = [event("CDR1","2026-10-29T10:00:00+00:00","e1"),
            event("CDR2","2026-10-29T10:01:00+00:00","e2")]
    incoming.write_text("".join(json.dumps(x)+"\n" for x in rows))
    stream.process_available()
    import sqlite3
    with sqlite3.connect(db) as con:
        silver = con.execute("SELECT COUNT(*) FROM silver_cdr").fetchone()[0]
    bronze_count = sum(1 for _ in bronze.open())
    sent_count = sum(1 for _ in incoming.open())
    assert sent_count == bronze_count == silver == 2

def test_checkpoint_restart_does_not_reingest(tmp_path, monkeypatch):
    stream, incoming, bronze, db, checkpoint = setup_env(tmp_path, monkeypatch)
    rows = [event("CDR1","2026-10-29T10:00:00+00:00","e1")]
    incoming.write_text("".join(json.dumps(x)+"\n" for x in rows))
    assert stream.process_available() == 1
    assert stream.process_available() == 0
    assert sum(1 for _ in bronze.open()) == 1
