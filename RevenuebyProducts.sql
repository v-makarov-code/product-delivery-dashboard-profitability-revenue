WITH products_prices AS (
  SELECT
    uo.date,
    uo.order_id,
    p.product_id,
    p.name,
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
revenue_per_product AS (
  SELECT
    name product_name,
    SUM(price) as revenue,
    ROUND(SUM(price) / SUM(SUM(price)) OVER() * 100, 2) share_in_revenue
  FROM
    products_prices
  GROUP BY
    name
)
SELECT
  CASE
    WHEN share_in_revenue < 0.5 THEN 'ДРУГОЕ'
    ELSE product_name
  END AS product_name,
  SUM(revenue) AS revenue,
  SUM(share_in_revenue) AS share_in_revenue
FROM
  revenue_per_product
GROUP BY
  CASE
    WHEN share_in_revenue < 0.5 THEN 'ДРУГОЕ'
    ELSE product_name
  END
ORDER BY
  revenue DESC;