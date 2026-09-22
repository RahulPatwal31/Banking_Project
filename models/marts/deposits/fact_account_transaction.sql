select
    transaction_id,
    account_id,
    customer_id,
    transaction_ts,
    posting_date,
    transaction_type,
    transaction_direction,
    channel,
    amount,
    currency_code,
    running_balance,
    merchant_name,
    transaction_status,
    ingestion_ts
from {{ ref('slvr_account_transactions') }}