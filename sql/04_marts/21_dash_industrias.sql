CREATE SCHEMA IF NOT EXISTS marts;

-- =====================================================================
-- TABLAS DEL DASHBOARD: RESUMEN EJECUTIVO y EXPLORADOR (paginas 1 y 3)
--   (Jose - BI y storytelling)
--
-- Responde la pregunta del fondo: en que industrias y etapas concentrar la
-- proxima tesis. Usa las metricas del diccionario:
--   * Exito de una startup  : salida (adquisicion o IPO), ficha de Hugo.
--   * Financiamiento total  : suma de fact_rondas.monto_usd, NULL = desconocido.
--   * Etapa de entrada      : tipo de la PRIMERA ronda de la empresa.
--
-- Reglas que se aplican aqui (iguales a las de las curvas de salida):
--   * Solo cohortes de primera ronda 2005+ (antes de 2005 Crunchbase casi no
--     registra; docs/limitaciones.md, punto 1).
--   * Una empresa entra al denominador de un horizonte H solo si su primera
--     ronda + H anios <= 2013-12-31 (plazo cumplido). Las demas no son fracasos.
--   * La salida cuenta solo si ocurre EN o DESPUES de la primera ronda: 202
--     empresas tienen su primera salida antes de su primera ronda registrada
--     (rondas post-IPO o registradas tarde) y no son una salida de esa inversion.
--   * Se publican conteos (numerador y denominador), no solo tasas, para que el
--     dashboard pueda agregar con DAX sin promediar promedios.
-- =====================================================================

-- ---------------------------------------------------------------------
-- dash_industria_etapa
-- Grano: una fila por (industria, pais, etapa de entrada, cohorte de primera ronda).
-- Las celdas son chicas a proposito: el dashboard suma numeradores y
-- denominadores con DAX segun los filtros, y nunca promedia tasas.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TABLE marts.dash_industria_etapa AS
WITH base AS (
    SELECT
        f.empresa_id,
        f.industria,
        f.pais,
        f.tipo_primera_ronda                                   AS etapa_entrada,
        f.cohorte_primera_ronda                                AS cohorte,
        f.fecha_primera_ronda,
        f.n_rondas,
        f.n_rondas_con_monto,
        f.financiamiento_total_usd,
        s.fecha_primera_salida,
        (s.fecha_primera_salida IS NOT NULL
         AND s.fecha_primera_salida >= f.fecha_primera_ronda)  AS salida_valida,
        s.tuvo_salida_con_monto
    FROM marts.met_financiamiento_empresa f
    JOIN marts.met_salida_empresa s ON s.empresa_id = f.empresa_id
    WHERE f.cohorte_primera_ronda BETWEEN 2005 AND 2013
      AND NOT f.es_registro_faltante                          -- sin industria ni pais
)
SELECT
    industria,
    pais,
    etapa_entrada,
    CAST(cohorte AS INTEGER)                                              AS cohorte,
    CAST(COUNT(*) AS INTEGER)                                             AS empresas,
    CAST(SUM(n_rondas) AS INTEGER)                                        AS rondas,
    CAST(SUM(n_rondas_con_monto) AS INTEGER)                              AS rondas_con_monto,
    CAST(SUM(financiamiento_total_usd) AS DOUBLE)                         AS financiamiento_usd,
    -- horizonte 1 anio
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 1 YEAR <= DATE '2013-12-31')
         AS INTEGER)                                                      AS observables_1a,
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 1 YEAR <= DATE '2013-12-31'
                            AND salida_valida
                            AND fecha_primera_salida <= fecha_primera_ronda + INTERVAL 1 YEAR)
         AS INTEGER)                                                      AS salidas_1a,
    -- horizonte 3 anios
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 3 YEAR <= DATE '2013-12-31')
         AS INTEGER)                                                      AS observables_3a,
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 3 YEAR <= DATE '2013-12-31'
                            AND salida_valida
                            AND fecha_primera_salida <= fecha_primera_ronda + INTERVAL 3 YEAR)
         AS INTEGER)                                                      AS salidas_3a,
    -- horizonte 5 anios
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 5 YEAR <= DATE '2013-12-31')
         AS INTEGER)                                                      AS observables_5a,
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 5 YEAR <= DATE '2013-12-31'
                            AND salida_valida
                            AND fecha_primera_salida <= fecha_primera_ronda + INTERVAL 5 YEAR)
         AS INTEGER)                                                      AS salidas_5a,
    -- definicion alternativa de exito (sensibilidad): la salida trae monto en USD
    CAST(COUNT(*) FILTER (WHERE fecha_primera_ronda + INTERVAL 5 YEAR <= DATE '2013-12-31'
                            AND salida_valida AND tuvo_salida_con_monto
                            AND fecha_primera_salida <= fecha_primera_ronda + INTERVAL 5 YEAR)
         AS INTEGER)                                                      AS salidas_5a_con_monto,
    -- traccion: levanto una segunda ronda (sirve tambien para cohortes recientes)
    CAST(COUNT(*) FILTER (WHERE n_rondas >= 2) AS INTEGER)                AS con_segunda_ronda
FROM base
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 3, 4;
