CREATE SCHEMA IF NOT EXISTS marts;

-- puente_ronda_inversionista
-- Grano: una fila por par (ronda, inversionista). Resuelve la relacion
-- muchos-a-muchos entre fact_rondas y dim_inversionista.
--
-- Como evita el doble conteo:
--   * El puente NO guarda el monto de la ronda; el monto vive solo en fact_rondas.
--   * peso = 1 / n_inversionistas de la ronda, de modo que los pesos de cada ronda
--     suman 1.
--   * Monto atribuido a un inversionista = fact_rondas.monto_usd * peso.
--     Sumado sobre todos los inversionistas de una ronda devuelve exactamente
--     el monto de la ronda, no monto x n_inversionistas.
--   * Para CONTAR participacion (en cuantas rondas entro un inversionista) se usa
--     COUNT(DISTINCT ronda_id), sin peso.
-- Supuesto: reparto igualitario; Crunchbase no reporta cuanto puso cada inversionista.
CREATE OR REPLACE TABLE marts.puente_ronda_inversionista AS
WITH pares AS (
    SELECT DISTINCT
        funding_round_id   AS ronda_id,
        investor_object_id AS inversionista_id
    FROM clean.investments
    WHERE funding_round_id IS NOT NULL
      AND investor_object_id IS NOT NULL
)
SELECT
    p.ronda_id,
    p.inversionista_id,
    CAST(1.0 / COUNT(*) OVER (PARTITION BY p.ronda_id) AS DOUBLE) AS peso
FROM pares p;