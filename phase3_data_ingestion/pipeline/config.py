from pathlib import Path
import os
from dotenv import load_dotenv

ROOT_DIR = Path(__file__).resolve().parents[2]
load_dotenv(ROOT_DIR / ".env")

DATA_DIR = ROOT_DIR / "data"
RAW_DIR = DATA_DIR / "raw"
CLEANSED_DIR = DATA_DIR / "cleansed"
QUARANTINE_DIR = DATA_DIR / "quarantine"
LOG_DIR = ROOT_DIR / "logs"

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "cdr_analytics")
DB_USER = os.getenv("DB_USER", "postgres")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
LOAD_TO_POSTGRES = os.getenv("LOAD_TO_POSTGRES", "false").lower() == "true"

WATERMARK_FILE = ROOT_DIR / "phase3_data_ingestion" / "pipeline" / "watermark.txt"
