CREATE SCHEMA IF NOT EXISTS marts;

-- serie_externa_mensual
-- Grano: una fila por mes calendario (primer dia del mes).
-- Fuente: FRED (Federal Reserve Bank of St. Louis). Ver data/external/README.md
-- para fuente, frecuencia original, periodo y metodo de agregacion de cada serie.
--   nasdaqcom : NASDAQ Composite, diaria -> promedio del mes (indice)
--   fedfunds  : Federal Funds Effective Rate, mensual (% anual)
--   unrate    : tasa de desempleo de EE.UU., mensual (%)
-- Periodo: 1990-01 a 2013-12. Cubre el periodo de Crunchbase (corte 2013-12-31)
-- con 12 meses de margen al inicio para construir rezagos.
--
-- Se une con dim_fecha por anio_mes. El archivo se lee con ruta relativa a la
-- raiz del proyecto: run_all.py debe ejecutarse desde la raiz (como dice el README).
CREATE OR REPLACE TABLE marts.serie_externa_mensual AS
SELECT
    CAST(anio_mes AS DATE)   AS anio_mes,
    CAST(nasdaqcom AS DOUBLE) AS nasdaqcom,
    CAST(fedfunds  AS DOUBLE) AS fedfunds,
    CAST(unrate    AS DOUBLE) AS unrate
FROM read_csv('data/external/fred_mensual.csv',
              header = true,
              columns = {'anio_mes': 'DATE',
                         'nasdaqcom': 'DOUBLE',
                         'fedfunds': 'DOUBLE',
                         'unrate': 'DOUBLE'})
ORDER BY anio_mes;
