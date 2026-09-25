SELECT 
output_address,
sum(output_value) AS total_sent,
count(*) AS tx_count

FROM {{ ref('gold_btc_ephemeral') }}
WHERE output_value > 10
GROUP BY output_address
ORDER BY total_sent DESC