-- Staging table used before loading the final warehouse fact table.
-- The final fact tables are defined by Phase 2 schema_ddl.sql.

CREATE TABLE IF NOT EXISTS stg_cdr_records (
    cdr_id VARCHAR(50) NOT NULL,
    duration_seconds INTEGER,
    estimated_charge_pence NUMERIC(10,2)
);
