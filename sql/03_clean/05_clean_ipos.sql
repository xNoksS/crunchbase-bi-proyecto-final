CREATE SCHEMA IF NOT EXISTS clean;

-- Se excluyen las 5 filas sin object_id.
CREATE OR REPLACE TABLE clean.ipos AS
SELECT
    i.*,
    CASE WHEN valuation_currency_code = 'USD' THEN NULLIF(valuation_amount, 0) END AS valuation_amount_usd,
    CASE WHEN raised_currency_code = 'USD'    THEN NULLIF(raised_amount, 0)    END AS raised_amount_usd
FROM staging.ipos i
WHERE object_id IS NOT NULL;