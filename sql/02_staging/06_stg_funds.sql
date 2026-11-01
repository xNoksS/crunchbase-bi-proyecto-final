CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.funds AS
SELECT
    CAST(id AS INTEGER)                  AS id,
    CAST(fund_id AS INTEGER)             AS fund_id,
    object_id,
    name,
    CAST(funded_at AS DATE)              AS funded_at,
    CAST(raised_amount AS DECIMAL(18,2)) AS raised_amount,
    raised_currency_code,
    source_url,
    source_description,
    CAST(created_at AS TIMESTAMP)        AS created_at,
    CAST(updated_at AS TIMESTAMP)        AS updated_at
FROM raw.funds;