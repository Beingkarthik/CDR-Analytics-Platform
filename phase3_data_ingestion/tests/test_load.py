import pandas as pd

def test_load_input_shape():
    df = pd.DataFrame({"cdr_id": [1], "duration_seconds": [10]})
    assert len(df) == 1
    assert list(df.columns) == ["cdr_id", "duration_seconds"]
