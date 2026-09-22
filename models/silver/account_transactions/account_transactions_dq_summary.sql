with valid_transactions as (

    select
        count(*) as valid_transaction_count
    from {{ ref('slvr_account_transactions') }}

),

rejected_transactions as (

    select
        rejection_reason,
        count(*) as rejected_transaction_count

    from {{ ref('slvr_account_transactions_rejected') }}

    group by rejection_reason

)

select

    rejection_reason,
    rejected_transaction_count,

    (
        select valid_transaction_count
        from valid_transactions
    ) as valid_transaction_count,

    current_timestamp() as calculated_at

from rejected_transactions