CREATE SCHEMA IF NOT EXISTS marts;

-- dim_fecha
-- Grano: una fila por dia calendario.
-- Rango: 1 de enero del anio de la fecha mas antigua en empresas, rondas,
-- adquisiciones e IPOs, hasta 2013-12-31 (corte de los datos de Crunchbase).
-- anio_mes (primer dia del mes) permite unir con series mensuales como FRED.
CREATE OR REPLACE TABLE marts.dim_fecha AS
WITH limites AS (
    SELECT date_trunc('year', LEAST(
        (SELECT MIN(founded_at)  FROM clean.objects WHERE entity_type = 'Company'),
        (SELECT MIN(funded_at)   FROM clean.funding_rounds),
        (SELECT MIN(acquired_at) FROM clean.acquisitions),
        (SELECT MIN(public_at)   FROM clean.ipos)
    )) AS inicio
),
dias AS (
    SELECT CAST(t.d AS DATE) AS fecha
    FROM limites,
         generate_series(CAST(limites.inicio AS TIMESTAMP),
                         TIMESTAMP '2013-12-31',
                         INTERVAL 1 DAY) AS t(d)
)
SELECT
    fecha,
    CAST(year(fecha)    AS SMALLINT)        AS anio,
    CAST(quarter(fecha) AS SMALLINT)        AS trimestre,
    CAST(month(fecha)   AS SMALLINT)        AS mes,
    CAST(date_trunc('month', fecha) AS DATE) AS anio_mes,
    strftime(fecha, '%Y-%m')                AS etiqueta_mes
FROM dias;