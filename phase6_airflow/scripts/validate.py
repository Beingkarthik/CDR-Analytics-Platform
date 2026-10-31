from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]

def validate_data():
    source = ROOT / "data" / "raw" / "cdr_records.csv"
    quarantine = ROOT / "data" / "quarantine"
    quarantine.mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(source)

    bad_duration = df[pd.to_numeric(df["duration_seconds"], errors="coerce") < 0]
    duplicates = df[df.duplicated(subset=["cdr_id"], keep=False)]

    bad_duration.to_csv(quarantine / "airflow_negative_duration.csv", index=False)
    duplicates.to_csv(quarantine / "airflow_duplicates.csv", index=False)

    print("Airflow validation completed.")
