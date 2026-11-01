-- CAPA STAGING: una tabla por archivo, nombres y tipos estandarizados.
-- Aquí NO se limpia nada: los NULL se conservan y se usa CAST (falla ruidosamente
-- si un valor no convierte, en vez de volverlo NULL en silencio).
CREATE SCHEMA IF NOT EXISTS staging;

CREATE OR REPLACE TABLE staging.objects AS
SELECT
    -- llaves: texto con prefijo (c:, f:, p:, r:); no se convierten a número
    id,
    entity_type,
    CAST(entity_id AS INTEGER)                  AS entity_id,
    parent_id,
    -- identificación y descripción
    name,
    normalized_name,
    permalink,
    category_code,
    status,
    -- fechas de vida de la entidad
    CAST(founded_at AS DATE)                    AS founded_at,
    CAST(closed_at AS DATE)                     AS closed_at,
    -- presencia web (texto)
    domain,
    homepage_url,
    twitter_username,
    logo_url,
    CAST(logo_width AS INTEGER)                 AS logo_width,
    CAST(logo_height AS INTEGER)                AS logo_height,
    -- textos descriptivos
    short_description,
    description,
    overview,
    tag_list,
    -- ubicación
    country_code,
    state_code,
    city,
    region,
    -- actividad como inversionista
    CAST(first_investment_at AS DATE)           AS first_investment_at,
    CAST(last_investment_at AS DATE)            AS last_investment_at,
    CAST(investment_rounds AS INTEGER)          AS investment_rounds,
    CAST(invested_companies AS INTEGER)         AS invested_companies,
    -- financiamiento recibido
    CAST(first_funding_at AS DATE)              AS first_funding_at,
    CAST(last_funding_at AS DATE)               AS last_funding_at,
    CAST(funding_rounds AS INTEGER)             AS funding_rounds,
    CAST(funding_total_usd AS DECIMAL(18,2))    AS funding_total_usd,
    -- hitos y relaciones
    CAST(first_milestone_at AS DATE)            AS first_milestone_at,
    CAST(last_milestone_at AS DATE)             AS last_milestone_at,
    CAST(milestones AS INTEGER)                 AS milestones,
    CAST(relationships AS INTEGER)              AS relationships,
    -- auditoría del registro
    created_by,
    CAST(created_at AS TIMESTAMP)               AS created_at,
    CAST(updated_at AS TIMESTAMP)               AS updated_at
FROM raw.objects;