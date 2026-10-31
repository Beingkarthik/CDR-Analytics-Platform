-- Phase 8 supplied reconciliation.sql identifies fact_cdr_events as the Gold target.
-- Compare the dbt Gold model with the Phase 5 fact_cdr_events table.
-- Replace the database/schema qualifiers with the actual Phase 5 location.
-- Run in both directions; each EXCEPT query must return zero rows.

select * from {{ ref('fact_cdr_events') }}
except
select * from PHASE5_DATABASE.PHASE5_SCHEMA.fact_cdr_events;

select * from PHASE5_DATABASE.PHASE5_SCHEMA.fact_cdr_events
except
select * from {{ ref('fact_cdr_events') }};

-- Basic target count, matching the supplied reconciliation.sql:
select count(*) as target_count
from {{ ref('fact_cdr_events') }};

-- SCD2 audit checks, matching the supplied audit_checks.sql:
select count(*) as current_scd_rows
from {{ ref('dim_fraud_labels') }}
where scd_current_flag = true;

select fraud_id, count(*) as versions
from {{ ref('dim_fraud_labels') }}
group by fraud_id
having count(*) > 1
order by versions desc;
