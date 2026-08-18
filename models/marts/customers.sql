{{
    config(
        materialized = 'table'
    )
}}

with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('orders') }}

),

customer_orders as (

    select
        customer_id,
        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders,

        -- Returned orders carry a zero payment, so they count towards order
        -- volume but not towards lifetime value. That is intentional.
        sum(amount) as customer_lifetime_value

    from orders
    group by customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        coalesce(customer_orders.number_of_orders, 0) as number_of_orders,
        coalesce(customer_orders.customer_lifetime_value, 0) as customer_lifetime_value

    from customers
    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

)

select * from final
