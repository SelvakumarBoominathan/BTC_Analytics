# Bitcoin Analytics with dbt and Snowflake

This project transforms raw Bitcoin transaction records in Snowflake into address-level whale activity analytics with dbt. It demonstrates layered modeling, seed data, reusable macros, package tests, model contracts and versions, a Looker Studio exposure, and GitHub Actions CI.

## Lineage

![dbt lineage from BTC_RAW through bronze_btc and silver_btc to gold_whale_alert and the dashboard exposure](png%20file/Project_Lineage.png)

The pipeline begins with `BTC.BTC_SCHEMA.BTC_RAW`, stages transaction records in `bronze_btc`, flattens transaction outputs in `silver_btc`, and builds the gold whale-alert model. The BTC/USD seed feeds the latest-price ephemeral model used by the v1 USD conversion.

## Models and Transformations

| Layer          | Model or resource                 | What it does                                                                                                                                                                                                                        |
| -------------- | --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Source         | `BTC_STAGE.BTC_RAW`               | Raw Bitcoin transaction data in Snowflake, declared in `models/sources/sources.yml`.                                                                                                                                                |
| Bronze         | `bronze_btc`                      | View over the raw transaction source. The model properties include unique and not-null tests for `HASY_KEY`, plus a `dbt_utils.equal_rowcount` test against the source.                                                             |
| Seed           | `btc_usd_max`                     | BTC/USD historical price data loaded from `seeds/btc_usd_max.csv`.                                                                                                                                                                  |
| Silver         | `silver_btc`                      | Incremental model that flattens the raw `OUTPUTS` array into output address and BTC value rows, retaining records with a non-null address. Incremental runs filter for timestamps newer than the current model's maximum timestamp. |
| Gold ephemeral | `gold_btc_ephemeral`              | Excludes coinbase records from `silver_btc`.                                                                                                                                                                                        |
| Gold ephemeral | `gold_btc_latest_price_ephemeral` | Selects a BTC/USD price from the `btc_usd_max` seed for USD conversion. **Current implementation note:** its SQL filters on the fixed date `2026-09-25`; it does not yet calculate the latest date dynamically.                     |
| Gold v1        | `gold_whale_alert` version 1      | Keeps outputs greater than 10 BTC, aggregates BTC and output count by address, and calculates USD from each address's aggregated BTC total using the `convert_to_usd` macro.                                                        |
| Gold v2        | `gold_whale_alert` version 2      | Keeps the address, aggregated BTC total, and output count; this version removes `TOTAL_SENT_USD` from v1's schema.                                                                                                                  |

The whale filter is applied to each flattened output (`output_value > 10`) before aggregation. The resulting `total_sent_btc` is therefore the sum of qualifying outputs per address, not a separate USD valuation for every original transaction.

The `convert_to_usd` macro is defined in `macros/usd_conversion.sql`. It multiplies a supplied BTC amount by the selected price from `gold_btc_latest_price_ephemeral`.

## dbt Features

- **Development and production targets:** separate `dev` and `prod` targets are used for Snowflake. Credentials and connection settings belong in the local `~/.dbt/profiles.yml`; do not commit secrets. GitHub Actions receives the CI profile and private key through repository/environment secrets.
- **dbt-utils:** `packages.yml` declares `dbt-labs/dbt_utils` version `1.4.1`. Install the package with `dbt deps`. The project uses `dbt_utils.equal_rowcount` in `models/bronze/bronze_properties.yml`.
- **Model contract:** the `gold_whale_alert` table has an enforced contract declared in `models/gold/gold_properties.yml`; its version column definitions specify the expected output schema.
- **Model versioning:** `gold_whale_alert` sets `latest_version: 2`. Version 1 is disabled and includes `TOTAL_SENT_USD`; version 2 is enabled and omits that column. The properties file also declares the `gold_whale_alert_current` latest-version pointer alias.
- **Dashboard exposure:** `btc_whale_alert_exposure` is a dashboard exposure for the Looker Studio Bitcoin Whale Alert report. It declares the report URL, owner, and dependency on `gold_whale_alert` version 2. The dashboard screenshot below links to the report.
- **GitHub Actions CI:** `.github/workflows/dbt-ci.yml` runs for pull requests targeting `master`. It installs dbt Core and the Snowflake adapter at version `1.9.4`, configures credentials from secrets, installs packages, runs `dbt debug`, and runs `dbt run`.

## Run Locally

Use Python 3.11 and install the dbt versions used by CI:

```bash
python -m pip install dbt-core==1.9.4 dbt-snowflake==1.9.4
```

Configure a `BTC_ANS` profile with the appropriate Snowflake `dev` or `prod` target in `~/.dbt/profiles.yml`. Then, from this project directory:

```bash
dbt debug
dbt deps
dbt seed --select btc_usd_max
dbt run
dbt test
dbt docs generate
```

Choose the target explicitly when needed, for example `dbt run --target dev` or `dbt run --target prod`. Avoid running production commands unless your profile and intended changes are confirmed.

## Project Screenshots

The screenshots below document the dashboard, Snowflake setup, and project checks. They are stored in the `png file` folder beside this README.

### Exposure Dashboard

[![Bitcoin Whale Alert Looker Studio dashboard showing BTC sent, transaction count, and address totals](png%20file/exposure%20dashboard.png)](https://datastudio.google.com/reporting/ba8c85cf-fd00-41de-9878-4cfba4381b47/page/MOx9F)

### Snowflake Setup

![Snowflake database creation](png%20file/Create%20DB.png)

![Snowflake schema creation](png%20file/Create%20Schema.png)

![Snowflake warehouse creation and configuration](png%20file/warehouse%20creation%20and%20config.png)

![Snowflake folder structure](png%20file/snowflake%20folder%20structure.png)

![Snowflake table creation](png%20file/Create%20table.png)

![Snowflake stage creation and verification](png%20file/create%20stage%20and%20verification.png)

![Snowflake task and insert statement](png%20file/task%20and%20insert%20into.png)

### Data Checks

![Data verification](png%20file/verify%20the%20data.png)
