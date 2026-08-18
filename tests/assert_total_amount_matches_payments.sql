-- Singular test: the pivoted per-method columns in the orders mart must sum
-- back to the order total. A pivot that silently drops a payment method is the
-- kind of error schema tests cannot see, because every individual column
-- remains valid.

with orders as (

    select * from {{ ref('orders') }}

),

discrepancies as (

    select
        order_id,
        amount as reported_total,
        {% for payment_method in var('payment_methods') -%}
        {{ payment_method }}_amount{{ " + " if not loop.last }}
        {%- endfor %} as summed_methods

    from orders

)

select *
from discrepancies
where abs(reported_total - summed_methods) > 0.001
