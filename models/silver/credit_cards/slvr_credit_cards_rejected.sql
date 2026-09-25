with staged as (
    select *
    from {{ ref('stg_credit_cards') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by card_id
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
    select
        c.*,
        case
            when sc.customer_id is not null
            then true
            else false
        end as customer_exists_in_silver
    from latest_records c
    left join {{ ref('slvr_customers') }} sc
        on c.customer_id = sc.customer_id
),

quality_checked as (
    select
        *,
        case
            when card_id is null
                then 'INVALID_CARD_ID'
            when customer_id is null
                then 'INVALID_CUSTOMER_ID'
            when customer_exists_in_silver = false
                then 'CUSTOMER_NOT_IN_SILVER'
            when network not in ('VISA','MASTERCARD')
              or network is null
                then 'INVALID_NETWORK'
            when card_status not in (
                'ACTIVE',
                'BLOCKED',
                'CLOSED',
                'EXPIRED'
            )
            or card_status is null
                then 'INVALID_CARD_STATUS'
            when credit_limit < 0
              or credit_limit is null
                then 'INVALID_CREDIT_LIMIT'
            when current_balance < 0
              or current_balance is null
                then 'INVALID_CURRENT_BALANCE'
            when available_credit < 0
              or available_credit is null
                then 'INVALID_AVAILABLE_CREDIT'
            when apr < 0
              or apr > 40
              or apr is null
                then 'INVALID_APR'
            when autopay_enabled not in ('Y','N')
              or autopay_enabled is null
                then 'INVALID_AUTOPAY_FLAG'
            else null
        end as rejection_reason
    from customer_check
)

select
    card_id,
    card_number_masked,
    customer_id,
    linked_account_id,
    card_product,
    network,
    issue_date,
    expiry_date,
    card_status,
    credit_limit,
    current_balance,
    available_credit,
    apr,
    cash_advance_limit,
    autopay_enabled,
    record_updated_at,
    ingestion_ts,

    rejection_reason,
    current_timestamp() as rejected_at
from quality_checked
where rejection_reason is not null