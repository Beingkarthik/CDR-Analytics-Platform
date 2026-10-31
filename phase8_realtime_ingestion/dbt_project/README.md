# dbt CDR Analytics project — Phase 8

## Scope
This dbt implementation converts the supplied Python ETL logic into a layered dbt project:
- staging: source typing and renaming
- intermediate: valid CDR filtering
- marts: subscriber dimension, call-type dimension, incremental call fact
- snapshot: subscriber history using dbt snapshot check strategy (SCD Type 2)

The supplied Python scripts establish `cdr_id`, `subscriber_id`, `call_type`, `start_timestamp`,
`end_timestamp`, and `duration_seconds`. The Phase 7 stream schema additionally documents
`event_id`, `estimated_charge_pence`, `event_time`, and `source_sequence`. Confirm these columns
exist in the Phase 5 source before running.

## Install and configure
```bash
python -m venv .venv
# Windows
.venv\Scripts\activate
pip install dbt-snowflake
copy profiles.example.yml %USERPROFILE%\.dbt\profiles.yml
```
Edit `profiles.yml` with your Snowflake account values. Never commit the real profile.

## Run order
```bash
dbt debug --profiles-dir .
dbt build
dbt snapshot
dbt test
dbt docs generate
dbt docs serve
```
Run `dbt build` a second time to verify the incremental fact model does not create duplicate `cdr_id` rows.

## Source setup
Create `CDR_ANALYTICS.RAW.CDR_RECORDS` and load the Phase 5/preceding-phase raw CDR data.
The `sources.yml` file points to this source.

## Contract failure demonstration
Temporarily change/remove a contracted column in the upstream source or model, run
`dbt build`, capture the expected failure, restore the column, and run `dbt build` again.
Capture both runs for the report. Do not use fabricated screenshots as execution evidence.

## Phase 5 reconciliation
Edit `reconcile_phase5.sql` to use exact Phase 5 Gold table identifiers and matching column lists.
Run every Gold-vs-Phase-5 EXCEPT query in both directions. Both result sets must return zero rows.
The exact Phase 5 table names/schema were not included with the supplied Phase 8 Python scripts,
so the reconciliation SQL is a clearly marked template until those identifiers are supplied.

## Supplied Python pipeline mapping
- extract.py: reads `data/raw/cdr_records.csv`
- validate.py: quarantines negative durations and duplicate `cdr_id` records
- transform.py: removes duplicate `cdr_id`, converts duration, filters negative duration
- load_dimensions.py / load_facts.py: placeholders to be implemented
- reconciliation.py: compares raw CSV and cleansed Parquet row counts
