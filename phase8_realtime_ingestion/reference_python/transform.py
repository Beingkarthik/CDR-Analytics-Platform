from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def transform_data():
    source = ROOT / "data" / "raw" / "cdr_records.csv"
    output = ROOT / "data" / "cleansed" / "cleansed_cdr_records.parquet"

    df = pd.read_csv(source)
    df = df.drop_duplicates(subset=["cdr_id"])
    df["duration_seconds"] = pd.to_numeric(df["duration_seconds"], errors="coerce")
    df = df[df["duration_seconds"].fillna(-1) >= 0]

    df.to_parquet(output, index=False)
    print("Airflow transformation completed.")
