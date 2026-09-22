with source as (

    select *
    from {{ source('banking_raw', 'accounts') }}

),

standardized as (

    select

        trim(account_id) as account_id,

        trim(account_number) as account_number,

        trim(customer_id) as customer_id,

        trim(branch_id) as branch_id,

        upper(trim(product_code)) as product_code,

        upper(trim(account_type)) as account_type,

        try_to_date(open_date) as open_date,

        try_to_date(close_date) as close_date,

        upper(trim(account_status)) as account_status,

        upper(trim(currency_code)) as currency_code,

        try_to_decimal(current_balance, 18, 2)
            as current_balance,

        try_to_decimal(available_balance, 18, 2)
            as available_balance,

        try_to_decimal(interest_rate, 10, 3)
            as interest_rate,

        try_to_decimal(overdraft_limit, 18, 2)
            as overdraft_limit,

        upper(trim(is_joint_account))
            as is_joint_account,

        try_to_timestamp_ntz(record_updated_at)
            as record_updated_at,

        try_to_timestamp_ntz(ingestion_ts)
            as ingestion_ts

    from source

)

select *
from standardized