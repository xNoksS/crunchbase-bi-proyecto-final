CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.ipos AS
SELECT
    CAST(id AS INTEGER)                     AS id,
    CAST(ipo_id AS INTEGER)                 AS ipo_id,
    object_id,
    CAST(valuation_amount AS DECIMAL(18,2)) AS valuation_amount,
    valuation_currency_code,
    CAST(raised_amount AS DECIMAL(18,2))    AS raised_amount,
    raised_currency_code,
    CAST(public_at AS DATE)                 AS public_at,
    stock_symbol,
    source_url,
    source_description,
    CAST(created_at AS TIMESTAMP)           AS created_at,
    CAST(updated_at AS TIMESTAMP)           AS updated_at
FROM raw.ipos;