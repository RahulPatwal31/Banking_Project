{{
    config(
        materialized = 'incremental',
        unique_key = 'transaction_id',
        incremental_strategy = 'merge'
    )
}}


with staged as (
    select * 
    from {{ ref('stg_account_transactions')}}

    {% if is_incremental() %}

        where ingestion_ts >= (
            select coalesce(
                max(ingestion_ts),
                '1900-01-01'::timestamp_ntz
            )
            from {{ this }}
        )

    {% endif %}
),

deduplicated as (
    select *,
    row_number() over (
        partition by transaction_id
        order by ingestion_ts desc nulls last,
        record_created_at desc nulls last
    ) as record_rank
    from staged
),

account_validated as (
    select d.*, 
    a.customer_id as account_customer_id
    from deduplicated d
    left join {{ ref('slvr_accounts')}} a
    on d.account_id = a.account_id
    where d.record_rank = 1
),

quality_checked as (
    select *,
     case
            when transaction_id is not null
             and account_id is not null
             and account_customer_id is not null
             and customer_id = account_customer_id
             and transaction_direction in (
                 'DEBIT',
                 'CREDIT'
             )
             and transaction_type in (
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
             and transaction_status in (
                 'POSTED',
                 'PENDING',
                 'REVERSED'
             )
             and currency_code = 'USD'
             and amount > 0
             and transaction_ts is not null
             and transaction_ts <= ingestion_ts
                
        then true
        else false
    end as is_valid_record
from account_validated
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
    ingestion_ts

from quality_checked
where is_valid_record = true