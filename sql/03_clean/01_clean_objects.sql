-- CAPA CLEAN: objects.
-- Decisión (bitácora fila 9): las llaves usadas por otras tablas que no existen en objects
-- se agregan como registros de reemplazo (es_registro_faltante = TRUE), con el tipo
-- derivado del prefijo (c: Company, f: FinancialOrg, p: Person, r: Product).
-- Así los joins funcionan sin borrar rondas, inversiones ni adquisiciones.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.objects AS
WITH llaves AS (
    SELECT parent_id AS k FROM staging.objects WHERE parent_id IS NOT NULL
    UNION SELECT object_id FROM staging.funding_rounds
    UNION SELECT funded_object_id FROM staging.investments
    UNION SELECT investor_object_id FROM staging.investments
    UNION SELECT acquiring_object_id FROM staging.acquisitions
    UNION SELECT acquired_object_id FROM staging.acquisitions WHERE acquired_object_id IS NOT NULL
    UNION SELECT object_id FROM staging.ipos WHERE object_id IS NOT NULL
    UNION SELECT object_id FROM staging.funds
    UNION SELECT object_id FROM staging.people
    UNION SELECT relationship_object_id FROM staging.relationships
        WHERE person_object_id IN (SELECT object_id FROM staging.people)
    UNION SELECT object_id FROM staging.milestones
    UNION SELECT object_id FROM staging.offices
),
faltantes AS (
    SELECT l.k AS id
    FROM llaves l
    LEFT JOIN staging.objects o ON l.k = o.id
    WHERE o.id IS NULL
)
SELECT o.*, FALSE AS es_registro_faltante
FROM staging.objects o
UNION ALL BY NAME
SELECT
    id,
    CASE split_part(id, ':', 1)
        WHEN 'c' THEN 'Company'
        WHEN 'f' THEN 'FinancialOrg'
        WHEN 'p' THEN 'Person'
        WHEN 'r' THEN 'Product'
    END                                   AS entity_type,
    CAST(split_part(id, ':', 2) AS INTEGER) AS entity_id,
    TRUE                                  AS es_registro_faltante
FROM faltantes;