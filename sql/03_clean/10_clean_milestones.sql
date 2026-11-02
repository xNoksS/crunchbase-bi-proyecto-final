-- CAPA CLEAN: milestones.
-- Sin exclusion de filas (no hay huerfanos contra clean.objects).
-- milestone_at fuera de [1800-01-01, 2013-12-31] se pone en NULL; no se borra la fila.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.milestones AS
SELECT
    id,
    object_id,
    CASE WHEN milestone_at BETWEEN DATE '1800-01-01' AND DATE '2013-12-31'
         THEN milestone_at END AS milestone_at,
    milestone_code,
    description,
    source_url,
    source_description,
    created_at,
    updated_at
FROM staging.milestones;