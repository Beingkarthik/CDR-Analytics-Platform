select cdr_id
from {{ ref('fact_cdr_events') }}
group by cdr_id
having count(*) > 1
