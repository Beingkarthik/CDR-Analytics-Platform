from getpass import getpass
from pathlib import Path
import csv
import snowflake.connector

ACCOUNT = "FCPIYVJ-IB86672"
USER = "NANAVATHKARTHIK"

ROOT_DIR = Path(__file__).resolve().parent
CSV_FILE = ROOT_DIR / "data" / "raw" / "cdr_records.csv"

password = getpass("Enter your Snowflake password: ")

connection = None
cursor = None

try:
    connection = snowflake.connector.connect(
        account=ACCOUNT,
        user=USER,
        password=password,
        warehouse="COMPUTE_WH",
        database="CDR_ANALYTICS",
        schema="RAW",
        role="ACCOUNTADMIN"
    )

    cursor = connection.cursor()

    insert_sql = """
        INSERT INTO CDR_ANALYTICS.RAW.CDR_RECORDS
        (CDR_ID, DURATION_SECONDS, ESTIMATED_CHARGE_PENCE)
        SELECT %s, %s, %s
        WHERE NOT EXISTS (
            SELECT 1
            FROM CDR_ANALYTICS.RAW.CDR_RECORDS
            WHERE CDR_ID = %s
        )
    """

    inserted = 0

    with open(CSV_FILE, "r", newline="", encoding="utf-8") as file:
        reader = csv.DictReader(file)

        for row in reader:
            cdr_id = int(row["cdr_id"])
            duration = int(row["duration_seconds"])
            charge = int(row["estimated_charge_pence"])

            cursor.execute(
                insert_sql,
                (cdr_id, duration, charge, cdr_id)
            )
            inserted += cursor.rowcount

    connection.commit()

    cursor.execute(
        "SELECT COUNT(*) FROM CDR_ANALYTICS.RAW.CDR_RECORDS"
    )
    total = cursor.fetchone()[0]

    print("Upload completed successfully.")
    print("New records inserted:", inserted)
    print("Total records in Snowflake:", total)

except Exception as error:
    if connection:
        connection.rollback()
    print("Upload failed:", error)

finally:
    if cursor:
        cursor.close()
    if connection:
        connection.close()