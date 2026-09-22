with valid_accounts as (
    select count(*) as valid_account_count
    from {{ ref('slvr_accounts')}}
),

rejected_accounts as (
    select rejection_reason, count(*) as rejected_account_count
    from {{ ref("slvr_accounts_rejected")}}
    group by rejection_reason
)

select rejection_reason, rejected_account_count,
(
    select valid_account_count
    from valid_accounts
) as valid_account_count,

current_timestamp() as calculated_at
from rejected_accounts