with source as (

    select * from {{ ref('raw_payments') }}

),

renamed as (

    select
        id as payment_id,
        order_id,
        payment_method,

        -- Amounts are stored in cents upstream. Converting once here means no
        -- downstream model has to remember the unit.
        amount / 100.0 as amount

    from source

)

select * from renamed
