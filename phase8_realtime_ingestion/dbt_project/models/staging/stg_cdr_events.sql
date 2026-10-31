select *
from {{ source('raw', 'cdr_records') }}
