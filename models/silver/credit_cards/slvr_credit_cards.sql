with staged as (
    select *
    from {{ ref('stg_credit_cards') }}
),

ranked as (
    select
        *,
        row_number() over (
            partition by card_id
            order by
                record_updated_at desc nulls last,
                ingestion_ts desc nulls last
        ) as record_rank
    from staged
),

latest_records as (
    select *
    from ranked
    where record_rank = 1
),

customer_check as (
    select
        c.*,
        case
            when sc.customer_id is not null
            then true
            else false
        end as customer_exists_in_silver
    from latest_records c
    left join {{ ref('slvr_customers') }} sc
        on c.customer_id = sc.customer_id
),

valid_records as (

    select *

    from customer_check

    where card_id is not null

      and customer_exists_in_silver = true

      and network in (
          'VISA',
          'MASTERCARD'
      )

      and card_status in (
          'ACTIVE',
          'BLOCKED',
          'CLOSED',
          'EXPIRED'
      )

      and credit_limit >= 0

      and current_balance >= 0

      and available_credit >= 0

      and apr between 0 and 40

      and cash_advance_limit >= 0

      and autopay_enabled in (
          'Y',
          'N'
      )

)

select

    card_id,
    card_number_masked,
    customer_id,
    linked_account_id,
    card_product,
    network,
    issue_date,
    expiry_date,
    card_status,
    credit_limit,
    current_balance,
    available_credit,
    apr,
    cash_advance_limit,
    autopay_enabled,
    record_updated_at,
    ingestion_ts

from valid_records