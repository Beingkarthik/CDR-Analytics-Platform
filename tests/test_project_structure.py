from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

def test_required_directories_exist():
    required = [
        "data/raw",
        "data/cleansed",
        "data/quarantine",
        "phase2_data_modeling",
        "phase3_data_ingestion/pipeline",
        "phase4_transformation/scripts",
        "phase5_data_warehouse/etl_scripts",
        "phase6_airflow/dags",
    ]
    for item in required:
        assert (ROOT / item).exists(), item
