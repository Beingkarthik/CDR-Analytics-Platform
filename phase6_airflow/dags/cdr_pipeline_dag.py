import sys
from pathlib import Path
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.python import PythonOperator

PROJECT_ROOT = Path(__file__).resolve().parents[2]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from phase6_airflow.scripts.extract import extract_data
from phase6_airflow.scripts.validate import validate_data
from phase6_airflow.scripts.transform import transform_data
from phase6_airflow.scripts.load_dimensions import load_dimensions
from phase6_airflow.scripts.load_facts import load_facts
from phase6_airflow.scripts.reconciliation import run_reconciliation
from phase6_airflow.scripts.notification import send_success_notification

default_args = {
    "owner": "cdr_team",
    "depends_on_past": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="cdr_analytics_pipeline",
    default_args=default_args,
    description="CDR Analytics ETL Pipeline",
    start_date=datetime(2026, 6, 1),
    schedule="@daily",
    catchup=False,
    tags=["cdr", "data-engineering"],
) as dag:

    extract_task = PythonOperator(
        task_id="extract_data",
        python_callable=extract_data,
    )

    validate_task = PythonOperator(
        task_id="validate_data",
        python_callable=validate_data,
    )

    transform_task = PythonOperator(
        task_id="transform_data",
        python_callable=transform_data,
    )

    dimensions_task = PythonOperator(
        task_id="load_dimensions",
        python_callable=load_dimensions,
    )

    facts_task = PythonOperator(
        task_id="load_facts",
        python_callable=load_facts,
    )

    reconciliation_task = PythonOperator(
        task_id="reconciliation",
        python_callable=run_reconciliation,
    )

    notification_task = PythonOperator(
        task_id="success_notification",
        python_callable=send_success_notification,
    )

    (
        extract_task
        >> validate_task
        >> transform_task
        >> dimensions_task
        >> facts_task
        >> reconciliation_task
        >> notification_task
    )
