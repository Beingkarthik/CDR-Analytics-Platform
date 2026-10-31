select *
from {{ ref('stg_cdr_events') }}
