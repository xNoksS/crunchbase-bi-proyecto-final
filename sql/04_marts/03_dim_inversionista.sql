CREATE SCHEMA IF NOT EXISTS marts;

-- dim_inversionista
-- Grano: una fila por inversionista que participa en al menos una ronda
-- (ids distintos de clean.investments.investor_object_id).
-- Un inversionista puede ser organizacion financiera (f:), empresa (c:) o persona (p:);
-- tipo_inversionista permite segmentar por esa diferencia.
-- Solo atributos descriptivos: las metricas (actividad, exito) viven en el
-- diccionario de metricas para que todos las calculen igual.
CREATE OR REPLACE TABLE marts.dim_inversionista AS
WITH ids AS (
    SELECT DISTINCT investor_object_id AS inversionista_id
    FROM clean.investments
    WHERE investor_object_id IS NOT NULL
)
SELECT
    i.inversionista_id,
    o.name                                   AS nombre,
    CASE o.entity_type
        WHEN 'FinancialOrg' THEN 'organizacion_financiera'
        WHEN 'Company'      THEN 'corporativo'
        WHEN 'Person'       THEN 'persona'
        ELSE 'sin_dato'
    END                                      AS tipo_inversionista,
    COALESCE(o.country_code,  'sin_dato')    AS pais,
    COALESCE(o.category_code, 'sin_dato')    AS industria,
    COALESCE(o.es_registro_faltante, TRUE)   AS es_registro_faltante
FROM ids i
LEFT JOIN clean.objects o ON o.id = i.inversionista_id;