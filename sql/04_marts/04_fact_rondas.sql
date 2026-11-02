CREATE SCHEMA IF NOT EXISTS marts;

-- fact_rondas
-- Grano: una fila por ronda de financiamiento (clean.funding_rounds.funding_round_id).
-- Es la UNICA tabla donde vive el monto de la ronda: el total del mercado se suma
-- aqui, nunca a traves del puente, para no contar doble.
-- monto_usd solo tiene valor si la moneda original era USD (ver bitacora de calidad);
-- NULL significa monto desconocido, no cero.
-- n_inversionistas = inversionistas registrados en clean.investments para la ronda;
-- puede diferir de participantes (dato reportado por Crunchbase).
CREATE OR REPLACE TABLE marts.fact_rondas AS
WITH conteo AS (
    SELECT funding_round_id, COUNT(DISTINCT investor_object_id) AS n_inversionistas
    FROM clean.investments
    GROUP BY funding_round_id
)
SELECT
    fr.funding_round_id                         AS ronda_id,
    fr.object_id                                AS empresa_id,
    fr.funded_at                                AS fecha,
    fr.funding_round_type                       AS tipo_ronda,
    fr.funding_round_code                       AS codigo_ronda,
    fr.raised_amount_usd                        AS monto_usd,
    fr.pre_money_valuation_usd                  AS valuacion_pre_usd,
    fr.post_money_valuation_usd                 AS valuacion_post_usd,
    fr.participants                             AS participantes_reportados,
    COALESCE(c.n_inversionistas, 0)             AS n_inversionistas,
    CAST(fr.is_first_round AS BOOLEAN)          AS es_primera_ronda,
    CAST(fr.is_last_round  AS BOOLEAN)          AS es_ultima_ronda
FROM clean.funding_rounds fr
LEFT JOIN conteo c ON c.funding_round_id = fr.funding_round_id;