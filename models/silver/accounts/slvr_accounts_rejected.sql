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

customer_check as (
    select a.*,
    case 
        when c.customer_id is null 
        then false
        else true
    end as  customer_exists_in_silver
    from latest_records as a
    left join {{ ref('slvr_customers')}} as c
    on a.customer_id = c.customer_id
),

quality_checked as (
    select
        *,
        case
            when account_id is null
                then 'INVALID_ACCOUNT_ID'
            when customer_id is null
                then 'INVALID_CUSTOMER_ID'
            when customer_exists_in_silver = false
                then 'CUSTOMER_NOT_IN_SILVER'
            when account_status not in (
                'ACTIVE',
                'CLOSED',
                'DORMANT'
            )
            or account_status is null
                then 'INVALID_ACCOUNT_STATUS'

            when currency_code <> 'USD'
            or currency_code is null
                then 'INVALID_CURRENCY'

            when current_balance < 0
            or current_balance is null
                then 'INVALID_CURRENT_BALANCE'

            when product_code is null
            or product_code = 'BAD_PRODUCT'
                then 'INVALID_PRODUCT'

            else null

        end as rejection_reason

    from customer_check

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
    ingestion_ts,

    rejection_reason,
    current_timestamp() as rejected_at
from quality_checked
where rejection_reason is not null