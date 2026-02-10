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
)
SELECT
  date,
  revenue,
  SUM(revenue) OVER(
    ORDER BY
      date
  ) as total_revenue,
  ROUND(
    (
      revenue - LAG(revenue) OVER(
        ORDER BY
          date
      )
    ) / LAG(revenue) OVER(
      ORDER BY
        date
    ) * 100,
    2
  ) as revenue_change
FROM
  (
    SELECT
      date,
      SUM(price) as revenue
    FROM
      products_prices
    GROUP BY
      date
  ) t1
ORDER BY
  date