from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def load_facts():
    source = ROOT / "data" / "cleansed" / "cleansed_cdr_records.parquet"
    df = pd.read_parquet(source)
    print(f"Fact loading task prepared {len(df)} rows.")
