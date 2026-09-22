with staged as (
    select *
    from {{ ref('stg_accounts') }}

),

ranked as (
    select
        *,
        row_number() over (
            partition by account_id
            order by
                record_updated_at desc nulls last,
                ingestion_ts desc nulls last
        ) as record_rank
    from staged
),

latest_records as (
    select * 
    from ranked
    where record_rank = 1
),


valid_accounts as (
    select a.*
    from latest_records a
    inner join 
    {{ref('slvr_customers')}} c
    on a.customer_id = c.customer_id
    where a.account_id is not null
    and a.customer_id is not null
    and a.account_status in (
        'ACTIVE',
        'CLOSED',
        'DORMAT'
    )
   
      and a.currency_code = 'USD'
      and a.current_balance >= 0
      and a.product_code is not null
      and a.product_code <> 'BAD_PRODUCT'
)

select
     account_id,
    account_number,
    customer_id,
    branch_id,
    product_code,
    account_type,
    open_date,
    close_date,
    account_status,
    currency_code,
    current_balance,
    available_balance,
    interest_rate,
    overdraft_limit,
    is_joint_account,
    record_updated_at,
    ingestion_ts
from valid_accounts