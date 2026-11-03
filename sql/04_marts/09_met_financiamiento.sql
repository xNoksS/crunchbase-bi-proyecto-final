CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- METRICA: FINANCIAMIENTO TOTAL  (Hugo - analista de startups e industrias)
-- Ficha completa en docs/diccionario_metricas.md
--
-- Definicion:  suma de marts.fact_rondas.monto_usd sobre las rondas del grupo.
-- Moneda:      una sola, USD. monto_usd solo trae valor cuando el dato venia en
--              USD; las rondas en otra moneda quedaron en NULL porque no hay
--              tabla de tipos de cambio (bitacora de calidad, filas 8 y 11).
-- Nulos:       NULL = monto desconocido, NO cero. Se excluyen de la suma y
--              SIEMPRE se publica al lado n_rondas_con_monto y cobertura_monto,
--              para que nadie lea un total como si fuera el mercado completo.
-- No usar el puente ronda-inversionista para sumar montos: el monto vive solo
-- en fact_rondas (ver 05_puente_ronda_inversionista.sql).
-- =====================================================================

-- ---------------------------------------------------------------------
-- met_financiamiento_empresa
-- Grano: una fila por empresa con al menos una ronda registrada.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.met_financiamiento_empresa AS
WITH r AS (
    SELECT
        empresa_id,
        COUNT(*)                                        AS n_rondas,
        COUNT(monto_usd)                                AS n_rondas_con_monto,
        CAST(SUM(monto_usd) AS DOUBLE)                  AS financiamiento_total_usd,
        MIN(fecha)                                      AS fecha_primera_ronda,
        MAX(fecha)                                      AS fecha_ultima_ronda,
        arg_min(tipo_ronda, fecha)                      AS tipo_primera_ronda
    FROM marts.fact_rondas
    WHERE fecha IS NOT NULL          -- 248 rondas sin fecha no se pueden ubicar
    GROUP BY empresa_id
)
SELECT
    e.empresa_id,
    e.nombre,
    e.industria,
    e.pais,
    e.etapa,
    e.anio_fundacion,
    r.fecha_primera_ronda,
    year(r.fecha_primera_ronda)                         AS cohorte_primera_ronda,
    r.fecha_ultima_ronda,
    r.tipo_primera_ronda,
    r.n_rondas,
    r.n_rondas_con_monto,
    r.financiamiento_total_usd,
    CAST(r.n_rondas_con_monto AS DOUBLE) / r.n_rondas   AS cobertura_monto,
    e.es_registro_faltante
FROM r
JOIN marts.dim_empresa e ON e.empresa_id = r.empresa_id;

-- ---------------------------------------------------------------------
-- met_financiamiento_mensual
-- Grano: una fila por mes calendario con al menos una ronda.
-- Es la serie que alimenta el analisis (b) de ciclos de mercado y la pagina
-- de startups del dashboard.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.met_financiamiento_mensual AS
SELECT
    CAST(date_trunc('month', fecha) AS DATE)            AS anio_mes,
    COUNT(*)                                            AS n_rondas,
    COUNT(monto_usd)                                    AS n_rondas_con_monto,
    COUNT(DISTINCT empresa_id)                          AS n_empresas,
    CAST(SUM(monto_usd) AS DOUBLE)                      AS monto_total_usd,
    CAST(MEDIAN(monto_usd) AS DOUBLE)                   AS monto_mediano_usd,
    CAST(COUNT(monto_usd) AS DOUBLE) / COUNT(*)         AS cobertura_monto
FROM marts.fact_rondas
WHERE fecha IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- ---------------------------------------------------------------------
-- met_financiamiento_industria_anio
-- Grano: una fila por (industria, anio de la ronda).
-- Para el explorador de startups e industrias del dashboard.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.met_financiamiento_industria_anio AS
SELECT
    e.industria,
    year(f.fecha)                                       AS anio,
    COUNT(*)                                            AS n_rondas,
    COUNT(f.monto_usd)                                  AS n_rondas_con_monto,
    COUNT(DISTINCT f.empresa_id)                        AS n_empresas,
    CAST(SUM(f.monto_usd) AS DOUBLE)                    AS monto_total_usd,
    CAST(MEDIAN(f.monto_usd) AS DOUBLE)                 AS monto_mediano_usd,
    CAST(COUNT(f.monto_usd) AS DOUBLE) / COUNT(*)       AS cobertura_monto
FROM marts.fact_rondas f
JOIN marts.dim_empresa e ON e.empresa_id = f.empresa_id
WHERE f.fecha IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;
