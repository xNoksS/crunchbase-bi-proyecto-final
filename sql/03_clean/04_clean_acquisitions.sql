CREATE SCHEMA IF NOT EXISTS clean;

-- Se excluye la fila sin acquired_object_id (FK nula, no se puede relacionar).
-- Un solo monedero: price_amount_usd solo cuando la moneda original es USD.
CREATE OR REPLACE TABLE clean.acquisitions AS
SELECT
    a.*,
    CASE WHEN price_currency_code = 'USD' THEN NULLIF(price_amount, 0) END AS price_amount_usd
FROM staging.acquisitions a
WHERE acquired_object_id IS NOT NULL;