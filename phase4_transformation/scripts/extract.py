from pathlib import Path
import pandas as pd

def load_csv(file_path):
    path = Path(file_path)
    if not path.exists():
        return None
    return pd.read_csv(path)
