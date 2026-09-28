

{% macro convert_to_usd(col_name)%}

{{col_name}} * (SELECT price
    FROM {{ ref('gold_btc_latest_price_ephemeral') }})

{% endmacro %}





