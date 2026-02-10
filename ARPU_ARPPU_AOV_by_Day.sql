WITH products_prices AS (
  SELECT
    uo.date,
    uo.order_id,
    p.product_id,
    p.price
  FROM
    (
      SELECT
        order_id,
        unnest(product_ids) as product_id,
        creation_time :: date AS date
      FROM
        orders
      WHERE
        order_id NOT IN (
          SELECT
            order_id
          FROM
            user_actions
          WHERE
            action = 'cancel_order'
        )
    ) uo
    JOIN products p ON uo.product_id = p.product_id
),
revenue_table AS (
  SELECT
    date,
    SUM(price) as revenue
  FROM
    products_prices
  GROUP BY
    date
),
paying_users_table AS(
  SELECT
    time :: date as date,
    COUNT(DISTINCT user_id) as paying_users
  FROM
    user_actions
  WHERE
    order_id NOT IN (
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    time :: date
),
overall_users AS (
  SELECT
    time :: date as date,
    COUNT(DISTINCT user_id) as count_users
  FROM
    user_actions
  GROUP BY
    time :: date
),
orders_count_table AS(
  SELECT
    creation_time :: date as date,
    COUNT(order_id) as order_count
  FROM
    orders
  WHERE
    order_id NOT IN (
      SELECT
        order_id
      FROM
        user_actions
      WHERE
        action = 'cancel_order'
    )
  GROUP BY
    creation_time :: date
)
SELECT
  rt.date as date,
  ROUND(rt.revenue / ou.count_users, 2) as arpu,
  ROUND(rt.revenue / pu.paying_users, 2) as arppu,
  ROUND(rt.revenue / oc.order_count, 2) as aov
FROM
  revenue_table rt
  JOIN overall_users ou USING(date)
  JOIN paying_users_table pu USING(date)
  JOIN orders_count_table oc USING(date)
ORDER BY
  date