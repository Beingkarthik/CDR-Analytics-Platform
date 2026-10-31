from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def run_reconciliation():
    source = pd.read_csv(ROOT / "data" / "raw" / "cdr_records.csv")
    target = pd.read_parquet(ROOT / "data" / "cleansed" / "cleansed_cdr_records.parquet")

    print(f"Source Count: {len(source)}")
    print(f"Target Count: {len(target)}")
    print("Reconciliation completed.")
