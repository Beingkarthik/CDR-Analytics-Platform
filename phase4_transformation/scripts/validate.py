import pandas as pd

def validate_cdr_records(df):
    errors = []
    if df is None or df.empty:
        return pd.DataFrame(errors)

    if "cdr_id" in df.columns and "duration_seconds" in df.columns:
        negative = pd.to_numeric(df["duration_seconds"], errors="coerce") < 0
        for _, row in df.loc[negative].iterrows():
            errors.append({"cdr_id": row["cdr_id"], "error_type": "negative_duration"})

    if {"cdr_id", "start_timestamp", "end_timestamp"}.issubset(df.columns):
        start = pd.to_datetime(df["start_timestamp"], errors="coerce")
        end = pd.to_datetime(df["end_timestamp"], errors="coerce")
        invalid = end < start
        for _, row in df.loc[invalid].iterrows():
            errors.append({"cdr_id": row["cdr_id"], "error_type": "invalid_timestamp"})

    return pd.DataFrame(errors)
