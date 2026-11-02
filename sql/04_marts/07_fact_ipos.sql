CREATE SCHEMA IF NOT EXISTS marts;

-- fact_ipos
-- Grano: una fila por oferta publica inicial (clean.ipos.ipo_id).
-- Los montos en USD estan casi vacios (la mayoria de IPOs se reportan en otra
-- moneda; ver bitacora): usar esta tabla para conteo y fecha de salida,
-- no para montos.
CREATE OR REPLACE TABLE marts.fact_ipos AS
SELECT
    i.ipo_id                    AS ipo_id,
    i.object_id                 AS empresa_id,
    i.public_at                 AS fecha,
    i.stock_symbol              AS simbolo_bursatil,
    i.raised_amount_usd         AS monto_levantado_usd,
    i.valuation_amount_usd      AS valuacion_usd
FROM clean.ipos i;