import pandas as pd

def prepare_fact_columns(df):
    result = df.copy()

    if "duration_seconds" in result.columns:
        result["duration_seconds"] = pd.to_numeric(
            result["duration_seconds"], errors="coerce"
        ).fillna(0).astype(int)

    if "estimated_charge_pence" in result.columns:
        result["estimated_charge_pence"] = pd.to_numeric(
            result["estimated_charge_pence"], errors="coerce"
        ).fillna(0)

    return result

if __name__ == "__main__":
    print("Use prepare_fact_columns() from the warehouse loading workflow.")
