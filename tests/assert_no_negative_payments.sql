-- A negative payment would flow straight through to customer lifetime value.
-- Refunds are modelled as returned orders with a zero amount, so a negative
-- figure means the source data changed shape.

select
    payment_id,
    order_id,
    amount

from {{ ref('stg_payments') }}
where amount < 0
