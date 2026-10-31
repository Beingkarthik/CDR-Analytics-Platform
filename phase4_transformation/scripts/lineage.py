from datetime import datetime
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parents[2]
LOG_FILE = ROOT_DIR / "logs" / "transformation_log.txt"

def write_lineage(source_name, records_read, records_written):
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as file:
        file.write(
            f"{datetime.now().isoformat()} | Source={source_name} | "
            f"Read={records_read} | Written={records_written}\n"
        )
