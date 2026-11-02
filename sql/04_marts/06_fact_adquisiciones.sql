CREATE SCHEMA IF NOT EXISTS marts;

-- fact_adquisiciones
-- Grano: una fila por adquisicion (clean.acquisitions.acquisition_id).
-- dim_empresa se usa dos veces (dimension de rol): empresa_adquirida_id y
-- empresa_adquirente_id.
-- precio_usd solo tiene valor si la moneda original era USD; NULL = desconocido.
-- Una empresa puede aparecer adquirida mas de una vez; la definicion de
-- "exito" (primera salida, etc.) se resuelve en el diccionario de metricas.
CREATE OR REPLACE TABLE marts.fact_adquisiciones AS
SELECT
    a.acquisition_id         AS adquisicion_id,
    a.acquired_object_id     AS empresa_adquirida_id,
    a.acquiring_object_id    AS empresa_adquirente_id,
    a.acquired_at            AS fecha,
    a.term_code              AS forma_pago,
    a.price_amount_usd       AS precio_usd
FROM clean.acquisitions a;