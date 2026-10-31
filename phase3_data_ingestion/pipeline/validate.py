import pandas as pd

def validate_data(df: pd.DataFrame):
    required = {"cdr_id", "duration_seconds"}
    missing = required - set(df.columns)
    if missing:
        raise ValueError(f"Missing required columns: {sorted(missing)}")

    work = df.copy()
    work["duration_seconds"] = pd.to_numeric(work["duration_seconds"], errors="coerce")

    invalid = work["duration_seconds"].isna() | (work["duration_seconds"] < 0)
    bad_rows = work.loc[invalid].copy()
    bad_rows["error_type"] = bad_rows["duration_seconds"].apply(
        lambda x: "missing_duration" if pd.isna(x) else "negative_duration"
    )

    good_rows = work.loc[~invalid].copy()
    return good_rows, bad_rows
