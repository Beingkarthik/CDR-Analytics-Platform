from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def extract_cdr():
    path = ROOT / "data" / "cleansed" / "cleansed_cdr_records.parquet"
    if not path.exists():
        raise FileNotFoundError(f"Run Phase 4 first: {path}")
    return pd.read_parquet(path)

if __name__ == "__main__":
    df = extract_cdr()
    print(f"Extracted {len(df)} cleansed CDR rows.")
