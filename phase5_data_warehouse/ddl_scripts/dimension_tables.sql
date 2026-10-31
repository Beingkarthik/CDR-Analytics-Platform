-- Phase 5 uses the complete dimensional model created in Phase 2.
-- Run phase2_data_modeling/schema_ddl.sql first.
--
-- This table records SCD operations for auditability.

CREATE TABLE IF NOT EXISTS dw_scd_audit_log (
    audit_id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    business_key VARCHAR(100) NOT NULL,
    operation VARCHAR(30) NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details TEXT
);
