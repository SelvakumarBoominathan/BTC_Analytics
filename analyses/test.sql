SELECT 
sd.hasy_key,
sd.block_number,
sd.block_timestamp,
sd.is_coinbase,
f.value
FROM {{ref('bronze_btc')}} sd,
LATERAL FLATTEN(input => OUTPUTS) f

WHERE sd.hasy_key = '1efc66741d8cb40abdae25c1e8105f662839cbd5a268eeef12a63f1197886c6e'