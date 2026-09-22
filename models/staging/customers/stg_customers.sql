with initial_customers as (
    select * from {{ source('banking_raw','customers')}}
),

incremental_customers as (
    select * from {{ source('banking_raw','customers_delta')}}
),

source as (
    select * from initial_customers
    union all 
    select * from incremental_customers
),

standardized as (
    select 
    trim(customer_id) as customer_id,
    trim(first_name) as first_name,
    trim(last_name) as last_name,
    try_to_date(trim(date_of_birth)) as date_of_birth,
    upper(trim(gender)) as gender,
    trim(email) as email,
    nullif(trim(phone_number), '') as phone_number,
    nullif(trim(ssn_masked),'') as ssn_masked,
    trim(address_line1) as address_line1,
    trim(city) as city,
    upper(trim(state_code)) as state_code,
    trim(zip_code) as zip_code,
    upper(trim(customer_segment)) as customer_segment,
    upper(trim(kyc_status)) as kyc_status,
    upper(trim(aml_risk_level)) as aml_risk_level,
    try_to_number(fico_score) as fico_score,
    try_to_number(annual_income) as annual_income,
    upper(trim(employment_status)) as employment_status,
    trim(occupation) as occupation,
    try_to_date(relationship_start_date) as relationship_start_date,
    upper(trim(customer_status)) as customer_status,
    upper(trim(preferred_channel)) as preferred_channel,
    try_to_timestamp_ntz(trim(record_updated_at)) as record_updated_at,
    try_to_timestamp_ntz(trim(ingestion_ts)) as ingestion_ts
from source
)

select * from standardized