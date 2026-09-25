

{% macro convert_to_usd(col_name)%}

{{col_name}} * (SELECT price
    FROM {{ ref('gold_btc_latest_price_ephemeral') }})

{% endmacro %}




{# 
{% macro convert_to_usd(col_name)%}

{{col_name}} * (
  
  SELECT 
    CLOSE_PRICE_USD AS price
  FROM {{ ref('btc_usd_max') }}
 WHERE TRY_TO_TIMESTAMP_TZ(
  REPLACE(EVENT_DATE, ' UTC', ' +00:00'),
  'YYYY-MM-DD HH24:MI:SS TZH:TZM'
)::DATE = DATEADD(day, -1, CURRENT_DATE()))

{% endmacro %} #}




