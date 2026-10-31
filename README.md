# Call Detail Records (CDR) Analytics Platform

A modular Data Engineering project for ingesting, validating, transforming, warehousing,
orchestrating, reconciling and observing telecom Call Detail Records.

## Project phases

1. Project Kickoff & Requirements
2. Data Modeling & Schema Design
3. Data Ingestion Pipeline
4. Data Transformation & Cleansing
5. Data Warehouse Loading & SCD Type 2
6. Pipeline Orchestration & Automation
7. Data Lineage & Observability
8. Production Readiness & Review

## Technology stack

- Python
- Pandas
- PostgreSQL
- SQL
- SQLAlchemy
- Apache Airflow
- PyArrow
- Pytest
- Git/GitHub

## Repository structure

```text
CDR-Analytics-Platform/
├── data/
├── phase2_data_modeling/
├── phase3_data_ingestion/
├── phase4_transformation/
├── phase5_data_warehouse/
├── phase6_airflow/
├── tests/
└── docs/
```

## Setup on Windows / VS Code

```powershell
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
```

Edit `.env` with your PostgreSQL credentials.

## Phase 3

From the repository root:

```powershell
python -m phase3_data_ingestion.pipeline.main
```

The ingestion pipeline:
- reads the raw CDR CSV
- validates records
- writes rejected records to `data/quarantine/`
- writes a clean staging dataset to `data/cleansed/`
- optionally loads the staging data into PostgreSQL
- updates a watermark
- writes a run log

To load into PostgreSQL, set:

```text
LOAD_TO_POSTGRES=true
```

in `.env`.

## Phase 4

```powershell
python -m phase4_transformation.scripts.main
```

The script processes datasets when they exist in `data/raw/`. Missing optional datasets
are reported instead of causing the whole pipeline to crash.

## Phase 5

Run the Phase 2 warehouse DDL first:

```text
phase2_data_modeling/schema_ddl.sql
```

Then use the Phase 5 ETL scripts for staging, SCD Type 2 processing and fact loading.

## Phase 6

The Airflow DAG is:

```text
phase6_airflow/dags/cdr_pipeline_dag.py
```

Airflow should be installed/configured separately according to the operating system.

## Tests

```powershell
pytest
```

## GitHub

```powershell
git init
git add .
git commit -m "Initial CDR analytics platform"
git branch -M main
git remote add origin YOUR_GITHUB_REPOSITORY_URL
git push -u origin main
```

Never commit `.env`, `.venv`, passwords, database dumps or generated logs.
