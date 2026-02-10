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
revenue_per_week AS (
  SELECT
    TO_CHAR(date, 'Day') weekday,
    DATE_PART('isodow', date) weekday_number,
    SUM(price) as revenue
  FROM
    products_prices
  WHERE
    date >= '2022-08-26'
    AND date <= '2022-09-8'
  GROUP BY
    TO_CHAR(date, 'Day'),
    DATE_PART('isodow', date)
),
users_per_week AS (
  SELECT
    TO_CHAR(time :: date, 'Day') weekday,
    DATE_PART('isodow', time :: date) weekday_number,
    COUNT(DISTINCT user_id) as count_users
  FROM
    user_actions
  WHERE
    time :: date >= '2022-08-26'
    AND time :: date <= '2022-09-8'
  GROUP BY
    TO_CHAR(time :: date, 'Day'),
    DATE_PART('isodow', time :: date)
),
paying_users_per_week AS (
  SELECT
    TO_CHAR(time :: date, 'Day') weekday,
    DATE_PART('isodow', time :: date) weekday_number,
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
    AND time :: date >= '2022-08-26'
    AND time :: date <= '2022-09-8'
  GROUP BY
    TO_CHAR(time :: date, 'Day'),
    DATE_PART('isodow', time :: date)
),
orders_per_week AS(
  SELECT
    TO_CHAR(creation_time :: date, 'Day') weekday,
    DATE_PART('isodow', creation_time :: date) weekday_number,
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
    AND creation_time :: date >= '2022-08-26'
    AND creation_time :: date <= '2022-09-8'
  GROUP BY
    TO_CHAR(creation_time :: date, 'Day'),
    DATE_PART('isodow', creation_time :: date)
)
SELECT
  r.weekday,
  r.weekday_number,
  ROUND(r.revenue / uw.count_users, 2) arpu,
  ROUND(r.revenue / puw.paying_users, 2) arppu,
  ROUND(r.revenue / ow.order_count, 2) aov
FROM
  revenue_per_week r
  JOIN users_per_week uw USING(weekday_number)
  JOIN paying_users_per_week puw USING(weekday_number)
  JOIN orders_per_week ow USING(weekday_number)
ORDER BY
  r.weekday_number