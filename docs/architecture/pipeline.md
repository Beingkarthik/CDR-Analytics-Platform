# CDR Pipeline Architecture

```text
Raw CDR CSV
    |
    v
Phase 3 - Ingestion
    |
    +--> Validation
    |       |
    |       +--> Quarantine
    |
    v
Phase 4 - Transformation
    |
    v
Cleansed Parquet
    |
    v
Phase 5 - Data Warehouse
    |
    +--> Dimensions / SCD Type 2
    |
    +--> Fact Tables
    |
    v
Phase 6 - Airflow
    |
    +--> Reconciliation
    |
    +--> Notification
```
