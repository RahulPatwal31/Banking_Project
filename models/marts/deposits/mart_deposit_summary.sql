with accounts as (
    select *
    from {{ ref('slvr_accounts') }}
),

transactions as (
    select *
    from {{ ref('slvr_account_transactions') }}
),

transaction_summary as (
    select
        account_id,
        count(*) as transaction_count,
        sum(
            case
                when transaction_direction = 'CREDIT'
                then amount
                else 0
            end
        ) as total_credit_amount,
        sum(
            case
                when transaction_direction = 'DEBIT'
                then amount
                else 0
            end
        ) as total_debit_amount,
        max(transaction_ts)
            as last_transaction_ts
    from transactions
    group by account_id
)

select
    a.account_id,
    a.customer_id,
    a.account_type,
    a.account_status,
    a.current_balance,
    a.available_balance,
    coalesce(t.transaction_count, 0)
        as transaction_count,
    coalesce(t.total_credit_amount, 0)
        as total_credit_amount,
    coalesce(t.total_debit_amount, 0)
        as total_debit_amount,
    coalesce(t.total_credit_amount, 0)
      - coalesce(t.total_debit_amount, 0)
        as net_transaction_amount,
    t.last_transaction_ts
from accounts a
left join transaction_summary t
    on a.account_id = t.account_id