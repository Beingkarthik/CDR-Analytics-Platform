import pandas as pd

CALL_TYPE_MAPPING = {
    "voice_mo": "VOICE MO",
    "Voice-MO": "VOICE MO",
    "VOICE MT": "VOICE MT",
    "data session": "DATA SESSION",
    "Data": "DATA SESSION",
}

def transform_cdr(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()

    if "cdr_id" in df.columns:
        df = df.drop_duplicates(subset=["cdr_id"])

    if "duration_seconds" in df.columns:
        df["duration_seconds"] = pd.to_numeric(df["duration_seconds"], errors="coerce")
        df = df[df["duration_seconds"].fillna(-1) >= 0]

    if "start_timestamp" in df.columns:
        start = pd.to_datetime(df["start_timestamp"], errors="coerce")
        df = df[start.notna()].copy()
        df["event_date"] = start.loc[df.index].dt.date
        df["event_hour"] = start.loc[df.index].dt.hour

        if "end_timestamp" in df.columns:
            end = pd.to_datetime(df["end_timestamp"], errors="coerce")
            valid_end = end.loc[df.index].isna() | (end.loc[df.index] >= start.loc[df.index])
            df = df.loc[valid_end].copy()

    if "call_type" in df.columns:
        df["call_type"] = (
            df["call_type"].replace(CALL_TYPE_MAPPING).astype("string").str.upper().str.strip()
        )

    if "duration_seconds" in df.columns:
        df["call_duration_minutes"] = df["duration_seconds"] / 60

    return df.reset_index(drop=True)
