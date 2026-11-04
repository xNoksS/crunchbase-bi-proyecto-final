CREATE SCHEMA IF NOT EXISTS clean;

-- Se excluye la fila sin acquired_object_id (FK nula, no se puede relacionar).
-- Un solo monedero: price_amount_usd solo cuando la moneda original es USD,
-- el monto es mayor que 0 y no supera US$ 100 mil millones (error de captura).
-- price_amount (original) se conserva sin cambios para trazabilidad.
CREATE OR REPLACE TABLE clean.acquisitions AS
SELECT
    a.*,
    CASE WHEN price_currency_code = 'USD'
              AND price_amount > 0
              AND price_amount <= 100000000000
         THEN price_amount END AS price_amount_usd,
    COALESCE(price_currency_code = 'USD' AND price_amount > 100000000000, FALSE) AS is_price_outlier
FROM staging.acquisitions a
WHERE acquired_object_id IS NOT NULL;