from pathlib import Path
from .config import RAW_DIR, CLEANSED_DIR, QUARANTINE_DIR, LOAD_TO_POSTGRES
from .extract import extract_data
from .validate import validate_data
from .load import load_data
from .watermark import update_watermark
from .logger import log_run

def run_pipeline():
    source = RAW_DIR / "cdr_records.csv"

    print("=" * 60)
    print("PHASE 3 - CDR DATA INGESTION")
    print("=" * 60)

    df = extract_data(source)
    rows_read = len(df)

    good_rows, bad_rows = validate_data(df)

    CLEANSED_DIR.mkdir(parents=True, exist_ok=True)
    QUARANTINE_DIR.mkdir(parents=True, exist_ok=True)

    clean_file = CLEANSED_DIR / "ingested_cdr_records.csv"
    reject_file = QUARANTINE_DIR / "cdr_rejects.csv"

    good_rows.to_csv(clean_file, index=False)
    bad_rows.to_csv(reject_file, index=False)

    if LOAD_TO_POSTGRES:
        load_data(good_rows, "stg_cdr_records")
    else:
        print("PostgreSQL loading skipped (LOAD_TO_POSTGRES=false).")

    rows_written = len(good_rows)
    quarantined = len(bad_rows)

    update_watermark("latest_successful_run")

    log_run("SUCCESS", rows_read, rows_written, quarantined)

    print(f"Valid rows: {rows_written}")
    print(f"Rejected rows: {quarantined}")
    print(f"Clean file: {clean_file}")
    print(f"Reject file: {reject_file}")
    print("Phase 3 completed successfully.")

if __name__ == "__main__":
    run_pipeline()
