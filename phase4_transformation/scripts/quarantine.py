from pathlib import Path

def write_quarantine(errors_df):
    root = Path(__file__).resolve().parents[2]
    output = root / "data" / "quarantine" / "phase4_rejects.csv"
    output.parent.mkdir(parents=True, exist_ok=True)
    errors_df.to_csv(output, index=False)
    return output
