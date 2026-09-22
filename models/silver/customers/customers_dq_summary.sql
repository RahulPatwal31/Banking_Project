with valid_records as (
    select count(*) as valid_customer_count from {{ ref('slvr_customers')}}
),

rejected_records as(
    select rejection_reason,
    count(*) as rejected_count from {{ ref('slvr_customers_rejected')}}
    group by rejection_reason
)

select rejection_reason, rejected_count,
(select valid_customer_count from valid_records) as valid_customer_count,
current_timestamp() as calculated_at
from rejected_records