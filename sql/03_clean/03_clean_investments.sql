CREATE SCHEMA IF NOT EXISTS clean;

-- Sin duplicados y sin huérfanos (las llaves faltantes ya están en clean.objects).
CREATE OR REPLACE TABLE clean.investments AS
SELECT * FROM staging.investments;