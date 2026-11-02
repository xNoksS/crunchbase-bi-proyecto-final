-- CAPA CLEAN: degrees.
-- Decision (bitacora): se excluyen las filas cuyo object_id no existe en people (554 filas),
-- porque no se pueden unir a ninguna persona. graduated_at fuera de [1800-01-01, 2013-12-31]
-- (los datos terminan en dic. 2013) se pone en NULL; no se borra la fila.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.degrees AS
SELECT
    id,
    object_id,
    degree_type,
    subject,
    institution,
    CASE WHEN graduated_at BETWEEN DATE '1800-01-01' AND DATE '2013-12-31'
         THEN graduated_at END AS graduated_at,
    created_at,
    updated_at
FROM staging.degrees
WHERE object_id IN (SELECT object_id FROM clean.people);