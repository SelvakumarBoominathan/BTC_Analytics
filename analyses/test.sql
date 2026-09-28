

SELECT COUNT(*) FROM {{ source('BTC_STAGE', 'BTC_RAW')}}