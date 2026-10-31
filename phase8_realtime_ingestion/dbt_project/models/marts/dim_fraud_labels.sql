code models\marts\dim_fraud_labels.sql{{ config(materialized='table') }}

select
    cdr_id,
    duration_seconds,
    estimated_charge_pence
from {{ ref('int_valid_cdrs') }}