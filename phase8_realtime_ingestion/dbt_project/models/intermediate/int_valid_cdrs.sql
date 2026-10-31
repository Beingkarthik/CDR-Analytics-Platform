select *
from {{ ref('stg_cdr_events') }}
where cdr_id is not null
  and duration_seconds >= 0