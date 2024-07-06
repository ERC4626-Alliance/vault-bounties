-- See https://dune.com/queries/3901350/6557469/
WITH
  EventEmitters AS (
    SELECT
      contract_address,
      COUNT(*) AS event_count
    FROM
      ethereum.logs
    WHERE
      -- deposit event 
      topic0 = 0xdcbc1c05240f31ff3ad067ef1ee35ce4997762752e3a095284754544f4c709d7
      AND block_time >= ( NOW() - interval '3' month )
    GROUP BY
      contract_address
    ORDER BY
      event_count DESC
  )
  
SELECT DISTINCT
  contract_address,
  event_count
FROM
  EventEmitters
ORDER BY
  event_count DESC
LIMIT
  1000
