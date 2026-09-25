
SELECT 
*
FROM {{ ref('silver_btc') }}
WHERE is_coinbase = false