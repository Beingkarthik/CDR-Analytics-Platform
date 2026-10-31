from pathlib import Path
import pandas as pd

def extract_data(file_path: Path) -> pd.DataFrame:
    file_path = Path(file_path)
    if not file_path.exists():
        raise FileNotFoundError(f"Input file not found: {file_path}")
    df = pd.read_csv(file_path)
    print(f"Extracted {len(df)} rows from {file_path}")
    return df
