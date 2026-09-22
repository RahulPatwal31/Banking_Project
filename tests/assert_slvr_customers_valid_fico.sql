select *
from {{ ref('slvr_customers') }}
where fico_score < 300
   or fico_score > 850
   or fico_score is null