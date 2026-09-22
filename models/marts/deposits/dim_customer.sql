select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name
        as customer_name,
    date_of_birth,
    state_code,
    customer_segment,
    kyc_status,
    aml_risk_level,
    fico_score,
    annual_income,
    employment_status,
    occupation,
    relationship_start_date,
    customer_status,
    preferred_channel,
    record_updated_at
from {{ ref('slvr_customers') }}