import pandas as pd
from sqlalchemy import create_engine
from .config import DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASSWORD

def load_data(df: pd.DataFrame, table_name: str = "stg_cdr_records"):
    if df.empty:
        print("No valid rows to load.")
        return

    if not DB_PASSWORD:
        raise RuntimeError("DB_PASSWORD is empty. Set it in .env before database loading.")

    url = (
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
        f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    engine = create_engine(url, pool_pre_ping=True)

    df.to_sql(table_name, engine, if_exists="append", index=False, method="multi")
    print(f"Loaded {len(df)} rows into {table_name}")
