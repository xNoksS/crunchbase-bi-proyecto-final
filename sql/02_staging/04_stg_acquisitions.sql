CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.acquisitions AS
SELECT
    CAST(id AS INTEGER)                 AS id,
    CAST(acquisition_id AS INTEGER)     AS acquisition_id,
    acquiring_object_id,
    acquired_object_id,
    term_code,
    CAST(price_amount AS DECIMAL(18,2)) AS price_amount,
    price_currency_code,
    CAST(acquired_at AS DATE)           AS acquired_at,
    source_url,
    source_description,
    CAST(created_at AS TIMESTAMP)       AS created_at,
    CAST(updated_at AS TIMESTAMP)       AS updated_at
FROM raw.acquisitions;