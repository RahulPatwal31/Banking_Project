with
    staged as (select * from {{ ref("stg_customers") }}),

    ranked as (
        select
            *,
            row_number() over (
                partition by customer_id order by record_updated_at desc nulls last,
                ingestion_ts desc nulls last
            ) as record_rank
        from staged
    ),

    quality_checked as (
        select
            *,
            case
                when customer_id is not null then true else false
            end as is_valid_customer_id,

            case
                when
                    state_code in (
                        'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA',
                        'HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
                        'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ',
                        'NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
                        'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC'
                    )
                then true
                else false
            end as is_valid_state,

            case
                when fico_score between 300 and 850 then true else false
            end as is_valid_fico,

            case
                when kyc_status in ('VERIFIED', 'PENDING', 'EXPIRED')
                then true
                else false
            end as is_valid_kyc_status,

            case
                when customer_status in ('ACTIVE', 'INACTIVE', 'DECEASED')
                then true
                else false
            end as is_valid_customer_status,

            case when email is null then true else false end as dq_warning_missing_mail,

            case
                when
                    phone_number is null
                    or not regexp_like(phone_number, '^\\+1-555-[0-9]{3}-[0-9]{4}$')
                then true
                else false
            end as dq_warning_invalid_phone

        from ranked
    ),

    validated as (
        select
            *,
            case
                when
                    is_valid_customer_id
                    and is_valid_state
                    and is_valid_fico
                    and is_valid_kyc_status
                    and is_valid_customer_status
                then true
                else false
            end as is_valid_record

        from quality_checked
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
    dq_warning_invalid_phone,
    dq_warning_missing_mail
from validated
where record_rank = 1 and is_valid_record = true
