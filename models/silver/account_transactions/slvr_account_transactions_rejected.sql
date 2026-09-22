with staged as (
    select * 
    from {{ ref('stg_account_transactions')}}
),

deduplicated as (
    select *,
    row_number() over (
        partition by transaction_id
        order by 
            ingestion_ts desc nulls last,
            record_created_at desc nulls last
    ) as record_rank
    from staged
),

latest_records as (
    select * 
    from deduplicated
    where record_rank = 1
),

account_check as (
    select l.*,
    a.customer_id as account_customer_id
    from latest_records l
    left join {{ ref('slvr_accounts') }} a 
    on l.account_id = a.account_id
),

quality_checked as (
    select *,
    case 
        when transaction_id is null
            then 'INVALID_TRANSACTION_ID'

        when account_id is null
            then 'INVALID_ACCOUNT_ID'

        when account_customer_id is null
            then 'ACCOUNT_NOT_IN_SILVER'

        when customer_id <> account_customer_id
            then 'CUSTOMER_MISMATCH'

        when transaction_direction not in (
            'DEBIT',
            'CREDIT'
        )
        or transaction_direction is null
            then 'INVALID_DIRECTION'

        when transaction_type not in (
            'ACH',
            'WIRE',
            'ATM',
            'CHECK',
            'TRANSFER',
            'FEE',
            'INTEREST',
            'DIRECT_DEPOSIT',
            'DEBIT_CARD'
        )
        or transaction_type is null
            then 'INVALID_TRANSACTION_TYPE'

        when transaction_status not in (
            'POSTED',
            'PENDING',
            'REVERSED'
        )
        or transaction_status is null
            then 'INVALID_TRANSACTION_STATUS'

        when amount <= 0
        or amount is null
            then 'INVALID_AMOUNT'

        when currency_code <> 'USD'
        or currency_code is null
            then 'INVALID_CURRENCY'

        when transaction_ts is null
            then 'INVALID_TRANSACTION_DATE'

        when transaction_ts > ingestion_ts
            then 'FUTURE_TRANSACTION_DATE'

        else null

    end as rejection_reason

from account_check
)

select

    transaction_id,
    account_id,
    customer_id,
    transaction_ts,
    posting_date,
    transaction_type,
    transaction_direction,
    channel,
    description,
    amount,
    currency_code,
    running_balance,
    merchant_name,
    counterparty_account,
    transaction_status,
    record_created_at,
    ingestion_ts,

    rejection_reason,

    current_timestamp() as rejected_at
    from quality_checked
    where rejection_reason is not null