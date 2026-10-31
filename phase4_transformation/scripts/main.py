from pathlib import Path
from .extract import load_csv
from .validate import validate_cdr_records
from .quarantine import write_quarantine
from .transform_cdr import transform_cdr
from .transform_rated_cdrs import transform_rated_cdrs
from .transform_fraud import transform_fraud
from .transform_plans import transform_plans
from .lineage import write_lineage

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "data" / "raw"
CLEAN = ROOT / "data" / "cleansed"
CLEAN.mkdir(parents=True, exist_ok=True)

def save_parquet(df, filename):
    path = CLEAN / filename
    df.to_parquet(path, index=False)
    return path

def process_cdr():
    df = load_csv(RAW / "cdr_records.csv")
    if df is None:
        print("cdr_records.csv not found - skipped.")
        return

    errors = validate_cdr_records(df)
    write_quarantine(errors)

    clean = transform_cdr(df)
    path = save_parquet(clean, "cleansed_cdr_records.parquet")
    write_lineage("cdr_records.csv", len(df), len(clean))
    print(f"CDR transformed: {path}")

def process_optional(filename, transformer, output):
    df = load_csv(RAW / filename)
    if df is None:
        print(f"{filename} not found - skipped.")
        return

    clean = transformer(df)
    path = save_parquet(clean, output)
    write_lineage(filename, len(df), len(clean))
    print(f"{filename} transformed: {path}")

if __name__ == "__main__":
    print("=" * 60)
    print("PHASE 4 - DATA TRANSFORMATION & CLEANSING")
    print("=" * 60)

    process_cdr()
    process_optional("rated_cdrs.csv", transform_rated_cdrs, "cleansed_rated_cdrs.parquet")
    process_optional("fraud_labels.csv", transform_fraud, "cleansed_fraud_labels.parquet")
    process_optional("subscriber_plans.csv", transform_plans, "cleansed_subscriber_plans.parquet")

    print("Phase 4 completed successfully.")
