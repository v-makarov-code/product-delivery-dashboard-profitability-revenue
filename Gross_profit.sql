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
revenue AS (
  SELECT
    date,
    SUM(price) as revenue
  FROM
    products_prices
  GROUP BY
    date
),
created_orders AS (
  SELECT
    creation_time :: date as date,
    COUNT(1) created_orders
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
),
delivered_orders AS (
  SELECT
    time :: date date,
    COUNT(order_id) delivered_orders
  FROM
    courier_actions
  WHERE
    action = 'deliver_order'
    AND order_id NOT IN (
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
more_than_five AS (
  SELECT
    date,
    COUNT(courier_id) more_than_five_orders
  FROM
    (
      SELECT
        time :: date as date,
        courier_id,
        COUNT(order_id)
      FROM
        courier_actions
      WHERE
        action = 'deliver_order'
        AND order_id NOT IN (
          SELECT
            order_id
          FROM
            user_actions
          WHERE
            action = 'cancel_order'
        )
      GROUP BY
        time :: date,
        courier_id
      HAVING
        COUNT(order_id) >= 5
    ) t1
  GROUP BY
    date
),
expenses AS (
  SELECT
    co.date AS date,
    CASE
      WHEN DATE_TRUNC('month', co.date) = '2022-08-01' THEN 120000 + 140 * co.created_orders + 150 * d.delivered_orders + 400 * COALESCE(mtf.more_than_five_orders, 0)
      WHEN DATE_TRUNC('month', co.date) = '2022-09-01' THEN 150000 + 115 * co.created_orders + 150 * d.delivered_orders + 500 * COALESCE(mtf.more_than_five_orders, 0)
    END AS costs
  FROM
    created_orders co
    JOIN delivered_orders d USING(date)
    LEFT JOIN more_than_five mtf USING(date)
),
taxes AS (
  SELECT
    date,
    SUM(tax) AS tax
  FROM
    (
      SELECT
        date,
        name,
        price,
        CASE
          WHEN name IN(
            'сахар',
            'сухарики',
            'сушки',
            'семечки',
            'масло льняное',
            'виноград',
            'масло оливковое',
            'арбуз',
            'батон',
            'йогурт',
            'сливки',
            'гречка',
            'овсянка',
            'макароны',
            'баранина',
            'апельсины',
            'бублики',
            'хлеб',
            'горох',
            'сметана',
            'рыба копченая',
            'мука',
            'шпроты',
            'сосиски',
            'свинина',
            'рис',
            'масло кунжутное',
            'сгущенка',
            'ананас',
            'говядина',
            'соль',
            'рыба вяленая',
            'масло подсолнечное',
            'яблоки',
            'груши',
            'лепешка',
            'молоко',
            'курица',
            'лаваш',
            'вафли',
            'мандарины'
          ) THEN ROUND(price / 110 * 10, 2)
          ELSE ROUND(price / 120 * 20, 2)
        END AS tax
      FROM
        products_prices
    ) t1
  GROUP BY
    date
)
SELECT
  r.date,
  r.revenue,
  e.costs,
  t.tax,
  r.revenue - e.costs - t.tax AS gross_profit,
  SUM(r.revenue) OVER w AS total_revenue,
  SUM(e.costs) OVER w AS total_costs,
  SUM(t.tax) OVER w AS total_tax,
  SUM(r.revenue) OVER w - SUM(e.costs) OVER w - SUM(t.tax) OVER w AS total_gross_profit,
  ROUND((r.revenue - e.costs - t.tax) / r.revenue * 100, 2) AS gross_profit_ratio,
  ROUND(
    (
      SUM(r.revenue) OVER w - SUM(e.costs) OVER w - SUM(t.tax) OVER w
    ) /(SUM(r.revenue) OVER w) * 100,
    2
  ) AS total_gross_profit_ratio
FROM
  revenue r
  JOIN expenses e USING(date)
  JOIN taxes t USING(date) WINDOW w AS (
    ORDER BY
      r.date
  )
ORDER BY
  r.date