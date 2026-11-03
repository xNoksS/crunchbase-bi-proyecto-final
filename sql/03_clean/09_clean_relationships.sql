-- CAPA CLEAN: relationships.
-- Decision (bitacora): se excluyen las filas cuyo person_object_id no existe en people (920 filas).
-- clean.objects ya asume esta exclusion: no crea registros de reemplazo para las llaves
-- relationship_object_id que solo aparecen en esas filas.
-- start_at / end_at fuera de [1800-01-01, 2013-12-31] se ponen en NULL; no se borra la fila.
-- is_past es una bandera (0/1) y sequence un orden: sus ceros son validos y no se tocan.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.relationships AS
SELECT
    id,
    relationship_id,
    person_object_id,
    relationship_object_id,
    CASE WHEN start_at BETWEEN DATE '1800-01-01' AND DATE '2013-12-31'
         THEN start_at END AS start_at,
    CASE WHEN end_at BETWEEN DATE '1800-01-01' AND DATE '2013-12-31'
         THEN end_at END AS end_at,
    is_past,
    sequence,
    title,
    created_at,
    updated_at
FROM staging.relationships
WHERE person_object_id IN (SELECT object_id FROM clean.people);