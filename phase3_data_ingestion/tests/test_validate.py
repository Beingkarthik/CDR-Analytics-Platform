import pandas as pd
from phase3_data_ingestion.pipeline.validate import validate_data

def test_negative_duration_is_quarantined():
    df = pd.DataFrame({
        "cdr_id": [1, 2],
        "duration_seconds": [30, -5]
    })
    good, bad = validate_data(df)
    assert len(good) == 1
    assert len(bad) == 1
    assert bad.iloc[0]["error_type"] == "negative_duration"
