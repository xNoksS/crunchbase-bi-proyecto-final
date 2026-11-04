CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- DIMENSIONES CHICAS DEL DASHBOARD  (Jose - BI y storytelling)
-- Una sola lista de industrias, etapas, paises y cohortes para que los
-- filtros de Power BI filtren a la vez rondas, portafolios y tasas de salida.
-- Se crean en SQL (y no con DAX) para que la agrupacion quede versionada.
-- =====================================================================

-- dash_dim_industria. Grano: una fila por industria (category_code).
-- grupo: "Software e internet" vs "Intensivas en capital". La regla es la
-- que usa el memo; cambiarla aqui cambia todas las vistas.
CREATE OR REPLACE TABLE marts.dash_dim_industria AS
SELECT
    industria,
    CASE
        WHEN industria IN ('software', 'web', 'mobile', 'enterprise', 'advertising',
                           'games_video', 'network_hosting', 'semiconductor')
            THEN 'Software e internet'
        WHEN industria IN ('biotech', 'cleantech', 'hardware')
            THEN 'Intensivas en capital'
        ELSE 'Otras'
    END AS grupo
FROM (
    SELECT industria FROM marts.dim_empresa
    UNION
    SELECT industria FROM marts.dash_portafolio
    UNION
    SELECT industria FROM marts.dash_industria_etapa
) t
ORDER BY industria;

-- dash_dim_etapa. Grano: una fila por tipo de ronda. orden = madurez, para
-- ordenar los ejes de menor a mayor etapa.
CREATE OR REPLACE TABLE marts.dash_dim_etapa AS
SELECT
    etapa,
    CAST(CASE etapa
        WHEN 'angel'          THEN 1
        WHEN 'crowdfunding'   THEN 2
        WHEN 'venture'        THEN 3
        WHEN 'series-a'       THEN 4
        WHEN 'series-b'       THEN 5
        WHEN 'series-c+'      THEN 6
        WHEN 'private-equity' THEN 7
        WHEN 'post-ipo'       THEN 8
        ELSE 9
    END AS INTEGER) AS orden
FROM (
    SELECT tipo_ronda AS etapa FROM marts.fact_rondas
    UNION
    SELECT etapa_entrada FROM marts.dash_portafolio
    UNION
    SELECT etapa_entrada FROM marts.dash_industria_etapa
) t
WHERE etapa IS NOT NULL
ORDER BY orden;

-- dash_dim_pais. Grano: una fila por codigo de pais.
CREATE OR REPLACE TABLE marts.dash_dim_pais AS
SELECT pais
FROM (
    SELECT pais FROM marts.dim_empresa
    UNION
    SELECT pais FROM marts.dash_industria_etapa
) t
ORDER BY pais;

-- dash_dim_cohorte. Grano: una fila por anio de primera ronda que se analiza.
-- 2005 en adelante: antes Crunchbase casi no registra (docs/limitaciones.md).
CREATE OR REPLACE TABLE marts.dash_dim_cohorte AS
SELECT CAST(c AS INTEGER) AS cohorte,
       (c + 5 <= 2013)    AS plazo_5a_cumplido,
       (c + 3 <= 2013)    AS plazo_3a_cumplido
FROM range(2005, 2014) t(c);
