"""Reconcile producer lines, Bronze rows, Silver keys and optional batch count."""
import argparse, json, sqlite3
from pathlib import Path

def count_lines(p):
    p=Path(p)
    return sum(1 for _ in p.open(encoding="utf-8")) if p.exists() else 0

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--sent", default="data/incoming/events.jsonl")
    ap.add_argument("--bronze", default="data/bronze/events.jsonl")
    ap.add_argument("--db", default="data/cdr_stream.db")
    ap.add_argument("--batch-count", type=int, default=None, help="Actual batch target row count; omit if not available")
    args=ap.parse_args()
    sent=count_lines(args.sent); bronze=count_lines(args.bronze)
    silver=0
    if Path(args.db).exists():
        with sqlite3.connect(args.db) as con:
            try: silver=con.execute("SELECT COUNT(*) FROM silver_cdr").fetchone()[0]
            except sqlite3.OperationalError: pass
    print("Layer,count,explanation")
    print(f"Sent,{sent},Producer JSONL event lines")
    print(f"Bronze,{bronze},Raw events retained including duplicates")
    print(f"Silver,{silver},Unique cdr_id keys after newest-event merge")
    print(f"Batch,{args.batch_count if args.batch_count is not None else 'NOT_PROVIDED'},Supply actual Phase 6/5 batch target count")
    print(f"Sent_minus_Bronze,{sent-bronze},Expected 0 after consumer catches up")
    print(f"Bronze_minus_Silver,{bronze-silver},Includes duplicate keys and multiple versions; explain with audit counts")
if __name__=="__main__": main()
