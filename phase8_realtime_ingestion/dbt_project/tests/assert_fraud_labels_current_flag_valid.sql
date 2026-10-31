select fraud_id
from {{ ref('dim_fraud_labels') }}
where scd_current_flag is null
