from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOG_FILE = ROOT / "logs" / "airflow_pipeline.log"

def write_log(task_name, status):
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(
            f"{datetime.now().isoformat()} | Task={task_name} | Status={status}\n"
        )
