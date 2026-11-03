-- CAPA CLEAN: people.
-- Sin cambios de filas: la PK (object_id) no tiene nulos ni duplicados (checks/duplicados.py).
-- La unica persona sin registro padre (p:268597) queda cubierta por un registro de reemplazo
-- en clean.objects, asi que people -> objects ya no tiene huerfanos.
CREATE SCHEMA IF NOT EXISTS clean;

CREATE OR REPLACE TABLE clean.people AS
SELECT *
FROM staging.people;