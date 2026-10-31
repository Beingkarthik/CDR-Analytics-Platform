"""Restartable local reference consumer. Bronze preserves raw fields plus ingest_time only."""
import json, os, sqlite3, time
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INCOMING = Path(os.getenv("CDR_INPUT_FILE", ROOT / "data/incoming/events.jsonl"))
BRONZE = Path(os.getenv("CDR_BRONZE_FILE", ROOT / "data/bronze/events.jsonl"))
DB = Path(os.getenv("CDR_DB", ROOT / "data/cdr_stream.db"))
CHECKPOINT = Path(os.getenv("CDR_CHECKPOINT", ROOT / "data/checkpoint.offset"))

def utc_now():
    return datetime.now(timezone.utc).isoformat()

def init_db():
    DB.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DB) as con:
        con.execute("""CREATE TABLE IF NOT EXISTS silver_cdr (
            cdr_id TEXT PRIMARY KEY, event_id TEXT, subscriber_id TEXT, call_type TEXT,
            start_timestamp TEXT, end_timestamp TEXT, duration_seconds INTEGER,
            estimated_charge_pence REAL, event_time TEXT, source_sequence INTEGER,
            ingest_time TEXT, updated_at TEXT
        )""")
        con.execute("""CREATE TABLE IF NOT EXISTS stream_audit (
            event_id TEXT, cdr_id TEXT, ingest_time TEXT, outcome TEXT, reason TEXT
        )""")

def apply_silver(event, ingest_time):
    # Business key is cdr_id. Newest event_time wins; older/out-of-order records never overwrite it.
    with sqlite3.connect(DB) as con:
        current = con.execute("SELECT event_time FROM silver_cdr WHERE cdr_id=?", (event["cdr_id"],)).fetchone()
        event_time = event.get("event_time") or ""
        late = False
        try:
            from datetime import datetime, timezone, timedelta
            parsed_event = datetime.fromisoformat(event_time.replace("Z", "+00:00"))
            parsed_ingest = datetime.fromisoformat(ingest_time.replace("Z", "+00:00"))
            late = parsed_ingest - parsed_event > timedelta(hours=1)
        except (ValueError, TypeError):
            pass
        if current and (current[0] or "") >= event_time:
            reason = "late_and_older" if late else "duplicate_or_older"
            con.execute("INSERT INTO stream_audit VALUES (?,?,?,?,?)",
                        (event.get("event_id"), event["cdr_id"], ingest_time, "ignored", reason))
            return "ignored"
        con.execute("""INSERT INTO silver_cdr
            (cdr_id,event_id,subscriber_id,call_type,start_timestamp,end_timestamp,duration_seconds,
             estimated_charge_pence,event_time,source_sequence,ingest_time,updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
            ON CONFLICT(cdr_id) DO UPDATE SET
              event_id=excluded.event_id, subscriber_id=excluded.subscriber_id,
              call_type=excluded.call_type, start_timestamp=excluded.start_timestamp,
              end_timestamp=excluded.end_timestamp, duration_seconds=excluded.duration_seconds,
              estimated_charge_pence=excluded.estimated_charge_pence, event_time=excluded.event_time,
              source_sequence=excluded.source_sequence, ingest_time=excluded.ingest_time,
              updated_at=excluded.updated_at
        """, (event["cdr_id"], event.get("event_id"), event.get("subscriber_id"), event.get("call_type"),
              event.get("start_timestamp"), event.get("end_timestamp"), event.get("duration_seconds"),
              event.get("estimated_charge_pence"), event.get("event_time"), event.get("source_sequence"),
              ingest_time, utc_now()))
        reason = "late_newest_event_review" if late else "newest_event"
        con.execute("INSERT INTO stream_audit VALUES (?,?,?,?,?)",
                    (event.get("event_id"), event["cdr_id"], ingest_time, "merged", reason))
    return "merged"

def process_available():
    init_db()
    if not INCOMING.exists():
        print(f"Waiting for input file: {INCOMING}")
        return 0
    BRONZE.parent.mkdir(parents=True, exist_ok=True)
    offset = int(CHECKPOINT.read_text().strip()) if CHECKPOINT.exists() else 0
    processed = 0
    with INCOMING.open("r", encoding="utf-8") as src:
        src.seek(offset)
        with BRONZE.open("a", encoding="utf-8") as bronze:
            while True:
                line_start = src.tell()
                line = src.readline()
                if not line:
                    break
                try:
                    event = json.loads(line)
                    ingest_time = utc_now()
                    # Bronze adds only ingest_time; all original fields are retained unchanged.
                    raw_plus_ingest = dict(event)
                    raw_plus_ingest["ingest_time"] = ingest_time
                    bronze.write(json.dumps(raw_plus_ingest) + "\n"); bronze.flush()
                    apply_silver(event, ingest_time)
                    offset = src.tell()
                    CHECKPOINT.parent.mkdir(parents=True, exist_ok=True)
                    CHECKPOINT.write_text(str(offset), encoding="utf-8")
                    processed += 1
                except (json.JSONDecodeError, KeyError) as exc:
                    print(f"Bad event at byte offset {line_start}: {exc}; left for manual review")
                    # Do not advance checkpoint past malformed event.
                    break
    return processed

def main():
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--poll-seconds", type=float, default=1.0)
    ap.add_argument("--once", action="store_true")
    args = ap.parse_args()
    while True:
        n = process_available()
        if n: print(f"Processed {n} event(s); checkpoint={CHECKPOINT}")
        if args.once: break
        time.sleep(max(0.1, args.poll_seconds))
if __name__ == "__main__":
    main()
