{{ config(
    materialized='incremental',
    unique_key='cdr_id',
    incremental_strategy='merge',
    on_schema_change='fail',
    contract={'enforced': true}
) }}

select
    cdr_id,
    duration_seconds,
    estimated_charge_pence
from {{ ref('int_valid_cdrs') }}
