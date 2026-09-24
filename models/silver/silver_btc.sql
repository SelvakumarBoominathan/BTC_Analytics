SELECT 
* 
FROM {{ref('bronze_btc')}}

{% if is_incremental() %}
where BLOCK_TIMESTAMP > (select max(BLOCK_TIMESTAMP) from {{ this }} )

{% endif %}