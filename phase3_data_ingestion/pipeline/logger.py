from datetime import datetime
from .config import LOG_DIR

LOG_FILE = LOG_DIR / "ingestion_log.txt"

def log_run(status, rows_read, rows_written, quarantined):
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a", encoding="utf-8") as f:
        f.write(
            f"{datetime.now().isoformat()} | "
            f"Status={status} | Read={rows_read} | "
            f"Written={rows_written} | Quarantined={quarantined}\n"
        )
