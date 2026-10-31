"""Compute p50/p95 producer-to-ingest latency and throughput per minute from Bronze JSONL."""
import argparse, csv, json
from collections import defaultdict
from datetime import datetime
from pathlib import Path

def dt(s):
    return datetime.fromisoformat(s.replace("Z","+00:00"))

def percentile(values, p):
    if not values: return None
    values=sorted(values); k=(len(values)-1)*p
    lo=int(k); hi=min(lo+1,len(values)-1)
    return values[lo] + (values[hi]-values[lo])*(k-lo)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--bronze", default="data/bronze/events.jsonl")
    ap.add_argument("--report", default="data/stream_metrics_report.csv")
    args=ap.parse_args()
    counts=defaultdict(int); minute_latencies=defaultdict(list); all_latencies=[]
    path=Path(args.bronze)
    if not path.exists(): raise SystemExit(f"Bronze file not found: {path}")
    for line in path.open(encoding="utf-8"):
        e=json.loads(line); ing=dt(e["ingest_time"])
        producer=dt(e.get("producer_time", e["event_time"]))
        latency=max(0.0,(ing-producer).total_seconds())
        minute=ing.strftime("%Y-%m-%d %H:%M")
        counts[minute]+=1; minute_latencies[minute].append(latency); all_latencies.append(latency)
    out=Path(args.report); out.parent.mkdir(parents=True,exist_ok=True)
    with out.open("w",newline="",encoding="utf-8") as f:
        w=csv.writer(f); w.writerow(["minute","events_ingested","throughput_events_per_minute","latency_p50_seconds","latency_p95_seconds"])
        for minute,n in sorted(counts.items()):
            w.writerow([minute,n,n,round(percentile(minute_latencies[minute],.50),3),
                        round(percentile(minute_latencies[minute],.95),3)])
    print(f"Rows={sum(counts.values())}; overall_latency_p50_s={percentile(all_latencies,.50)}; "
          f"overall_latency_p95_s={percentile(all_latencies,.95)}; minutes={len(counts)}; report={out}")
if __name__=="__main__": main()
