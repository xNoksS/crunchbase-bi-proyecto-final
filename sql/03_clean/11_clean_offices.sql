-- CAPA CLEAN: offices.
-- Sin exclusion de filas. Coordenadas (0, 0) son un valor de relleno (punto en el oceano, frente a
-- Africa occidental), no una oficina real: se ponen en NULL. Un cero suelto en solo una de las dos
-- coordenadas es valido (ecuador o meridiano de Greenwich) y se conserva.
-- created_at / updated_at se conservan como texto, como quedaron en staging.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.offices AS
SELECT
    id,
    object_id,
    office_id,
    description,
    region,
    address1,
    address2,
    city,
    zip_code,
    state_code,
    country_code,
    CASE WHEN latitude = 0 AND longitude = 0 THEN NULL ELSE latitude END AS latitude,
    CASE WHEN latitude = 0 AND longitude = 0 THEN NULL ELSE longitude END AS longitude,
    created_at,
    updated_at
FROM staging.offices;