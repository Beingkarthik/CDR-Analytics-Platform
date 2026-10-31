from .config import WATERMARK_FILE

def get_watermark():
    if not WATERMARK_FILE.exists():
        return "1970-01-01"
    return WATERMARK_FILE.read_text(encoding="utf-8").strip()

def update_watermark(value):
    WATERMARK_FILE.parent.mkdir(parents=True, exist_ok=True)
    WATERMARK_FILE.write_text(str(value), encoding="utf-8")
