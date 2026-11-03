CREATE SCHEMA IF NOT EXISTS marts;

-- dim_empresa
-- Grano: una fila por empresa (objects con entity_type = 'Company').
-- Incluye los registros de reemplazo (es_registro_faltante = TRUE) para que
-- ninguna ronda, adquisicion o IPO quede huerfana; los analisis pueden filtrarlos.
-- Se omiten textos largos (description, overview, logos) para caber en Neon (0.5 GB).
-- etapa = tipo de la ultima ronda de la empresa; 'sin_rondas' si nunca levanto capital.
CREATE OR REPLACE TABLE marts.dim_empresa AS
WITH rondas AS (
    SELECT
        object_id,
        MIN(funded_at)                            AS fecha_primera_ronda,
        arg_max(funding_round_type, funded_at)    AS etapa
    FROM clean.funding_rounds
    WHERE funded_at IS NOT NULL
    GROUP BY object_id
)
SELECT
    o.id                                    AS empresa_id,
    o.name                                  AS nombre,
    COALESCE(o.category_code, 'sin_dato')   AS industria,
    COALESCE(o.country_code,  'sin_dato')   AS pais,
    o.region,
    o.status                                AS estatus,
    o.founded_at                            AS fecha_fundacion,
    year(o.founded_at)                      AS anio_fundacion,
    r.fecha_primera_ronda,
    year(r.fecha_primera_ronda)             AS anio_primera_ronda,
    COALESCE(r.etapa, 'sin_rondas')         AS etapa,
    o.es_registro_faltante
FROM clean.objects o
LEFT JOIN rondas r ON r.object_id = o.id
WHERE o.entity_type = 'Company';