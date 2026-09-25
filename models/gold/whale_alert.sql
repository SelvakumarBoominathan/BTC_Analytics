-- depends_on: {{ ref('gold_btc_latest_price_ephemeral') }}

WITH calculated_btc_table AS (
SELECT 
    btc.output_address,
    SUM(btc.output_value) AS total_sent_btc,
    COUNT(*) AS tx_count
FROM {{ ref('gold_btc_ephemeral') }} AS btc
WHERE btc.output_value > 10
GROUP BY btc.output_address

)
SELECT 
    output_address,
    total_sent_btc,
    tx_count,
    {{ convert_to_usd('total_sent_btc')}} AS total_sent_usd
FROM calculated_btc_table
ORDER BY total_sent_usd DESC