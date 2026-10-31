from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def extract_data():
    source = ROOT / "data" / "raw" / "cdr_records.csv"
    df = pd.read_csv(source)
    print(f"Records extracted: {len(df)}")
