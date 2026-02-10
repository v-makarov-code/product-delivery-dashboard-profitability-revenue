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
revenue AS (
  SELECT
    date,
    SUM(price) as revenue
  FROM
    products_prices
  GROUP BY
    date
),
new_users AS (
  SELECT
    user_id,
    DATE_TRUNC('day', MIN(time)) as date
  FROM
    user_actions
  GROUP BY
    user_id
),
orders_cost AS (
  SELECT
    order_id,
    SUM(price) order_cost
  FROM
    products_prices
  GROUP BY
    order_id
),
history_users AS (
  SELECT
    date,
    user_id,
    SUM(order_cost) order_value
  FROM
    (
      SELECT
        u.time :: date as date,
        u.user_id,
        oc.order_id,
        oc.order_cost
      FROM
        user_actions u
        JOIN orders_cost oc USING(order_id)
    ) t1
  GROUP BY
    date,
    user_id
),
new_revenue AS (
  SELECT
    hu.date,
    SUM(hu.order_value) as new_users_revenue
  FROM
    history_users hu
    JOIN new_users nu ON hu.date = nu.date
    AND hu.user_id = nu.user_id
  GROUP BY
    hu.date
)
SELECT
  r.date,
  r.revenue,
  nr.new_users_revenue,
  ROUND(nr.new_users_revenue / r.revenue * 100, 2) new_users_revenue_share,
  100 - ROUND(nr.new_users_revenue / r.revenue * 100, 2) old_users_revenue_share
FROM
  revenue r
  JOIN new_revenue nr USING(date)
ORDER BY
  r.date