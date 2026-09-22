select
    account_id,
    account_number,
    customer_id,
    branch_id,
    product_code,
    account_type,
    open_date,
    close_date,
    account_status,
    currency_code,
    interest_rate,
    overdraft_limit,
    is_joint_account,
    record_updated_at
from {{ ref('slvr_accounts') }}