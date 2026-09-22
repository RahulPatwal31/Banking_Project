WITH staged as (
    SELECT * FROM {{ ref("stg_customers") }}
),

ranked as (
    SELECT *, 
    row_number() over (
        partition by customer_id
        order by record_updated_at desc nulls last,
        ingestion_ts desc nulls last
    ) as record_rank
    FROM staged
),

quality_checked as (
    SELECT *,
    case 
    when customer_id is null
    then 'INVALID_CUSTOMER_ID'

    when state_code not in (
                        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
                        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
                        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
                        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
                        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC'        
    )
    or state_code is null
    then 'INVALID_STATE'

    when fico_score not between 300 and 850
    or fico_score is null
    then 'INVALID_FICO'

    when kyc_status not in (
        'VERIFIED',
        'PENDING',
        'EXPIRED'
    )
    or kyc_status is null
    then 'INVALID_KYC_STATUS'

    when customer_status not in (
        'ACTIVE',
        'INACTIVE',
        'DECEASED'
    ) or customer_status is null
    then 'INVALID_CUSTOMER_STATUS'

    else null
end as rejection_reason
FROM ranked
)

select 
customer_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    email,
    phone_number,
    ssn_masked,
    address_line1,
    city,
    state_code,
    zip_code,
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
    record_updated_at,
    ingestion_ts,
    rejection_reason,
    current_timestamp() as rejected_at

from quality_checked
where record_rank = 1
and rejection_reason is not null