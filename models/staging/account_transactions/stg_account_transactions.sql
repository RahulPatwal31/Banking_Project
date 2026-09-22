
with initial_transactions as (
    select *
    from {{source('banking_raw', 'account_transactions')}}
),

incremental_transactions as (
    select *
    from {{source('banking_raw', 'account_transactions_delta')}}
),

source as (
    select * from initial_transactions
    union all
    select * from incremental_transactions
),

standardized as (
    select 
    trim(transaction_id) as transaction_id,
    trim(account_id) as account_id,
    trim(customer_id) as customer_id,
    try_to_timestamp_ntz(transaction_ts) as transaction_ts,
    try_to_date(posting_date)
            as posting_date,
    upper(trim(transaction_type))
            as transaction_type,
    upper(trim(transaction_direction))
            as transaction_direction,
    upper(trim(channel))
            as channel,
    nullif(trim(description), '')
            as description,
    try_to_decimal(amount, 18, 2)
            as amount,
    upper(trim(currency_code))
            as currency_code,
    try_to_decimal(running_balance, 18, 2)
            as running_balance,
    nullif(trim(merchant_name), '')
            as merchant_name,
    nullif(trim(counterparty_account), '')
            as counterparty_account,
    upper(trim(transaction_status))
            as transaction_status,
    try_to_timestamp_ntz(record_created_at)
            as record_created_at,
    try_to_timestamp_ntz(ingestion_ts)
            as ingestion_ts

    from source
)

select * from standardized