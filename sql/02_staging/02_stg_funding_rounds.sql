-- CAPA STAGING: funding_rounds.
-- Nombres y tipos estandarizados, sin limpiar: los NULL y los ceros se conservan tal como vienen.
-- Se usa CAST (falla ruidosamente si un valor no convierte).
CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE TABLE staging.funding_rounds AS
SELECT
    -- llaves
    CAST(id AS INTEGER)                              AS id,
    CAST(funding_round_id AS INTEGER)                AS funding_round_id,
    object_id,                                       -- FK a objects.id (texto con prefijo)
    -- ronda
    CAST(funded_at AS DATE)                          AS funded_at,
    funding_round_type,
    funding_round_code,
    -- montos levantados
    CAST(raised_amount_usd AS DECIMAL(18,2))         AS raised_amount_usd,
    CAST(raised_amount AS DECIMAL(18,2))             AS raised_amount,
    raised_currency_code,
    -- valoraciones
    CAST(pre_money_valuation_usd AS DECIMAL(18,2))   AS pre_money_valuation_usd,
    CAST(pre_money_valuation AS DECIMAL(18,2))       AS pre_money_valuation,
    pre_money_currency_code,
    CAST(post_money_valuation_usd AS DECIMAL(18,2))  AS post_money_valuation_usd,
    CAST(post_money_valuation AS DECIMAL(18,2))      AS post_money_valuation,
    post_money_currency_code,
    -- participantes y banderas
    CAST(participants AS INTEGER)                    AS participants,
    CAST(is_first_round AS INTEGER)                  AS is_first_round,
    CAST(is_last_round AS INTEGER)                   AS is_last_round,
    -- fuente y auditoría
    source_url,
    source_description,
    created_by,
    CAST(created_at AS TIMESTAMP)                    AS created_at,
    CAST(updated_at AS TIMESTAMP)                    AS updated_at
FROM raw.funding_rounds;