CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- RESULTADO: ANALISIS 1 - CURVAS DE SALIDA POR COHORTE  (obligatorio)
--            (Hugo - analista de startups e industrias)
--
-- Pregunta: por anio de primera ronda, que porcentaje de empresas tuvo una
--           adquisicion o IPO dentro de 1, 3 y 5 anos.
--
-- Cohorte = anio de la PRIMERA RONDA (no de fundacion): founded_at falta en el
-- 54% de las empresas (bitacora, fila 2).
--
-- EL PUNTO FINO: cohortes cuyo plazo aun no se cumple.
--   Los datos cortan el 2013-12-31. Una empresa cuya primera ronda fue en
--   2012-05 todavia no completa 3 anos de observacion dentro del dataset: que no
--   se le vea salida NO significa que fracaso. Contarla como fracaso inventa una
--   caida de las tasas en los anios recientes.
--   Tratamiento, en dos niveles:
--     1) Por empresa: se le llama OBSERVABLE a horizonte H solo si
--        fecha_primera_ronda + H anios <= 2013-12-31. Las no observables se
--        EXCLUYEN del denominador (no del numerador: si ya salio, igual cuenta).
--     2) Por cohorte: cohorte_completa = TRUE solo si TODAS sus empresas son
--        observables a ese horizonte, o sea cohorte + H <= 2013. Las cohortes
--        incompletas se publican igual pero MARCADAS: no se grafican ni se
--        citan como tasa final.
--   pct_observable deja ver cuanto de la cohorte se pudo mirar.
-- =====================================================================

CREATE OR REPLACE TABLE marts.res_curvas_salida AS
WITH horizontes(horizonte_anios) AS (
    SELECT * FROM (VALUES (1), (3), (5))
),
base AS (
    SELECT
        s.empresa_id,
        s.cohorte_primera_ronda          AS cohorte,
        s.fecha_primera_ronda,
        s.fecha_primera_salida
    FROM marts.met_salida_empresa s
    WHERE s.fecha_primera_ronda IS NOT NULL
),
cruce AS (
    SELECT
        b.cohorte,
        h.horizonte_anios,
        -- la empresa completo el plazo dentro del periodo de los datos
        (b.fecha_primera_ronda + to_years(h.horizonte_anios) <= DATE '2013-12-31')
                                                                    AS observable,
        -- salio dentro del horizonte
        (b.fecha_primera_salida IS NOT NULL
         AND b.fecha_primera_salida <= b.fecha_primera_ronda + to_years(h.horizonte_anios))
                                                                    AS salio_en_horizonte
    FROM base b
    CROSS JOIN horizontes h
)
SELECT
    cohorte,
    horizonte_anios,
    COUNT(*)                                                        AS empresas_cohorte,
    SUM(CASE WHEN observable THEN 1 ELSE 0 END)                     AS empresas_observables,
    SUM(CASE WHEN observable AND salio_en_horizonte THEN 1 ELSE 0 END) AS salidas_en_horizonte,
    -- tasa sobre el denominador observable; NULL si no hay nada que observar
    CASE WHEN SUM(CASE WHEN observable THEN 1 ELSE 0 END) > 0
         THEN CAST(SUM(CASE WHEN observable AND salio_en_horizonte THEN 1 ELSE 0 END) AS DOUBLE)
              / SUM(CASE WHEN observable THEN 1 ELSE 0 END)
    END                                                             AS tasa_salida,
    CAST(SUM(CASE WHEN observable THEN 1 ELSE 0 END) AS DOUBLE) / COUNT(*) AS pct_observable,
    -- la cohorte entera cumplio el plazo dentro del periodo de los datos
    (cohorte + horizonte_anios <= 2013)                             AS cohorte_completa
FROM cruce
GROUP BY cohorte, horizonte_anios
ORDER BY cohorte, horizonte_anios;
