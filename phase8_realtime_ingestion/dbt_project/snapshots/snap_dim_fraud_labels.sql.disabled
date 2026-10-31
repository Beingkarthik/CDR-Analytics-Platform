{% snapshot snap_dim_fraud_labels %}

{{
    config(
        target_schema='SNAPSHOTS',
        unique_key='fraud_id',
        strategy='check',
        check_cols='all',
        invalidate_hard_deletes=True
    )
}}

select *
from {{ ref('dim_fraud_labels') }}

{% endsnapshot %}