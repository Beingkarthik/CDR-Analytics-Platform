from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def load_staging_file():
    source = ROOT / "data" / "cleansed" / "cleansed_cdr_records.parquet"
    if not source.exists():
        raise FileNotFoundError("Run Phase 4 before Phase 5 fact loading.")

    df = pd.read_parquet(source)
    print(f"Prepared {len(df)} rows for warehouse loading.")
    return df

if __name__ == "__main__":
    load_staging_file()
