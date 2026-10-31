# Phase 8 — CDR Analytics dbt Code Package

## Confirmed from the supplied Phase 8 SQL
- Gold fact object: `fact_cdr_events`.
- SCD Type 2 dimension: `dim_fraud_labels`.
- Current SCD row flag: `scd_current_flag`.
- SCD business key: `fraud_id`.
- SCD audit checks: current-row count and multiple versions per `fraud_id`.
- Reconciliation compares the Gold fact count with the cleansed Phase 4 source count; the supplied SQL names `fact_cdr_events` as the target.

## Project structure
- `dbt_project/models/staging/`: source-to-staging model.
- `dbt_project/models/intermediate/`: reusable intermediate event model.
- `dbt_project/models/marts/`: `fact_cdr_events` incremental model and `dim_fraud_labels` model.
- `dbt_project/snapshots/`: `snap_dim_fraud_labels` SCD Type 2 snapshot.
- `dbt_project/tests/`: custom uniqueness and SCD current-flag tests.
- `dbt_project/reconcile_phase5.sql`: two-way EXCEPT and SCD audit queries.
- `reference_python/`: original Python scripts supplied for Phase 8 context.
- `reference_sql/`: exact SQL files supplied for reconciliation and SCD checks.

## Configure
Install the Snowflake adapter:
```bash
pip install dbt-snowflake
```
Copy `dbt_project/profiles.example.yml` to `~/.dbt/profiles.yml` and enter your own Snowflake account, user, role, warehouse and password locally. Never put real credentials in this ZIP.

## Run order
```bash
cd dbt_project
dbt debug --profiles-dir .
dbt build
dbt snapshot
dbt test
dbt docs generate
dbt docs serve
```
Run `dbt build` again to check incremental behavior. Query `dim_fraud_labels` for `scd_current_flag` and compare versions by `fraud_id`.

## Important schema alignment before execution
The supplied Phase 8 SQL confirms the object names and SCD key/flag, but it does not provide the complete Phase 5 fact column list, exact database/schema names, or all `dim_fraud_labels` attributes. The models therefore preserve source columns with `select *`; the enforced contract needs the actual Phase 5 column definitions added once the Phase 5 schema/ERD is available. The Phase 5 database/schema placeholders in `reconcile_phase5.sql` must be replaced with the real location. Do not treat a template query as a successful zero-row reconciliation.

The source declaration assumes `CDR_ANALYTICS.RAW.CDR_RECORDS`; adjust it to the actual raw landing relation if your environment uses a different name.
