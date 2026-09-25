WITH flatten_outputs AS (
  SELECT 
sd.hasy_key,
sd.block_number,
sd.block_timestamp,
sd.is_coinbase,
f.value:address::STRING AS output_address,
f.value:value::FLOAT AS output_value
FROM {{ref('bronze_btc')}} sd,
{# Using Lateral flattent to explode an array of objects #}
LATERAL FLATTEN(input => OUTPUTS) f

WHERE f.value:address is not null

{% if is_incremental() %}
AND sd.block_timestamp > (select max(block_timestamp) from {{ this }} )
{% endif %}
)

SELECT 
hasy_key,
block_number,
block_timestamp,
is_coinbase,
output_address,
output_value
FROM flatten_outputs