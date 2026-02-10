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
running_revenue_table AS (
  SELECT
    DISTINCT date,
    SUM(price) OVER(
      ORDER BY
        date
    ) as running_revenue
  FROM
    products_prices
),
running_users_table AS (
  SELECT
    date,
    SUM(new_users) OVER(
      ORDER BY
        date
    ) as running_users
  FROM
    (
      SELECT
        first_day :: date as date,
        COUNT(user_id) as new_users
      FROM
        (
          SELECT
            user_id,
            DATE_TRUNC('day', MIN(time)) as first_day
          FROM
            user_actions
          GROUP BY
            user_id
        ) min_day
      GROUP BY
        first_day
    ) t1
),
running_paying_users_table AS (
  SELECT
    date,
    SUM(new_users) OVER(
      ORDER BY
        date
    ) as running_paying_users
  FROM
    (
      SELECT
        first_day :: date as date,
        COUNT(user_id) as new_users
      FROM
        (
          SELECT
            user_id,
            DATE_TRUNC('day', MIN(time)) as first_day
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
            user_id
        ) min_day
      GROUP BY
        first_day
    ) t1
),
running_orders_count_table AS (
  SELECT
    date,
    SUM(order_count) OVER(
      ORDER BY
        date
    ) as running_order_count
  FROM
    (
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
    ) t1
)
SELECT
  date,
  ROUND(r.running_revenue / ou.running_users, 2) as running_arpu,
  ROUND(r.running_revenue / pu.running_paying_users, 2) as running_arppu,
  ROUND(r.running_revenue / o.running_order_count, 2) as running_aov
FROM
  running_revenue_table r
  JOIN running_users_table ou USING(date)
  JOIN running_paying_users_table pu USING(date)
  JOIN running_orders_count_table o USING(date)
ORDER BY
  date