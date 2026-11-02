CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.funds AS
SELECT
    f.*,
    CASE WHEN raised_currency_code = 'USD' THEN NULLIF(raised_amount, 0) END AS raised_amount_usd
FROM staging.funds f;