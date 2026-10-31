from pathlib import Path
from phase3_data_ingestion.pipeline.extract import extract_data

def test_extract_sample():
    path = Path("data/raw/cdr_records.csv")
    df = extract_data(path)
    assert len(df) > 0
    assert "cdr_id" in df.columns
