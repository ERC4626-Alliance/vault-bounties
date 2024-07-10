-- Prices https://dune.com/queries/3907436
WITH
  latest_prices AS (
    SELECT
      contract_address,
      price,
      ROW_NUMBER() OVER (
        PARTITION BY
          contract_address
        ORDER BY
          minute DESC
      ) as row_num
    FROM
      prices.usd
    WHERE
      blockchain = 'ethereum'
      AND minute >= NOW() - INTERVAL '1' DAY
  )
SELECT
  contract_address,
  price
FROM
  latest_prices
WHERE
  row_num = 1;
