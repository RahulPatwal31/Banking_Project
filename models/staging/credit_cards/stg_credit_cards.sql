with source as (
    select * from 
    {{source('banking_raw','credit_cards')}}
),

standardized as (
    select 
        trim(card_id) as card_id,

        trim(card_number_masked) as card_number_masked,

        trim(customer_id) as customer_id,

        trim(linked_account_id) as linked_account_id,

        upper(trim(card_product)) as card_product,

        upper(trim(network)) as network,

        try_to_date(issue_date) as issue_date,

        try_to_date(expiry_date) as expiry_date,

        upper(trim(card_status)) as card_status,

        try_to_decimal(credit_limit,18,2)
            as credit_limit,

        try_to_decimal(current_balance,18,2)
            as current_balance,

        try_to_decimal(available_credit,18,2)
            as available_credit,

        try_to_decimal(apr,10,2)
            as apr,

        try_to_decimal(cash_advance_limit,18,2)
            as cash_advance_limit,

        upper(trim(autopay_enabled))
            as autopay_enabled,

        try_to_timestamp_ntz(record_updated_at)
            as record_updated_at,

        try_to_timestamp_ntz(ingestion_ts)
            as ingestion_ts

    from source
)

select *
from standardized