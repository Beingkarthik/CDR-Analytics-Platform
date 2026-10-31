"""Configurable CDR event simulator. Writes JSONL events to data/incoming/events.jsonl."""
import argparse, json, os, random, time, uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path

def utc_now():
    return datetime.now(timezone.utc)

def build_event(seq, late=False):
    now = utc_now()
    event_time = now - timedelta(hours=2) if late else now
    return {
        "event_id": str(uuid.uuid4()),
        "cdr_id": f"CDR{seq:010d}",
        "subscriber_id": f"SUB{(seq % 5000) + 1:05d}",
        "call_type": ["VOICE MO", "VOICE MT", "DATA SESSION"][seq % 3],
        "start_timestamp": event_time.isoformat(),
        "end_timestamp": (event_time + timedelta(seconds=(seq % 300) + 1)).isoformat(),
        "duration_seconds": (seq % 300) + 1,
        "estimated_charge_pence": round((seq % 200) * 0.75, 2),
        "source_sequence": seq,
        "event_time": event_time.isoformat(),
        "producer_time": now.isoformat()
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rate", type=float, default=2.0, help="base events per second")
    ap.add_argument("--seconds", type=int, default=0, help="duration; 0 means run until Ctrl+C")
    ap.add_argument("--duplicate-every", type=int, default=0, help="repeat every Nth event once")
    ap.add_argument("--late-every", type=int, default=0, help="make every Nth event two hours late")
    ap.add_argument("--output", default="data/incoming/events.jsonl")
    args = ap.parse_args()
    if args.rate <= 0: ap.error("--rate must be > 0")
    path = Path(args.output); path.parent.mkdir(parents=True, exist_ok=True)
    started = time.monotonic(); seq = 0
    try:
        with path.open("a", encoding="utf-8") as f:
            while not args.seconds or time.monotonic() - started < args.seconds:
                seq += 1
                event = build_event(seq, bool(args.late_every and seq % args.late_every == 0))
                f.write(json.dumps(event) + "\n"); f.flush()
                if args.duplicate_every and seq % args.duplicate_every == 0:
                    f.write(json.dumps(event) + "\n"); f.flush()
                time.sleep(1.0 / args.rate)
    except KeyboardInterrupt:
        pass
    print(f"Producer stopped. Unique generated sequence count={seq}; output={path}")
if __name__ == "__main__":
    main()
