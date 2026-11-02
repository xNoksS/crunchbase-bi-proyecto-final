CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.offices AS
SELECT
    CAST(id AS INTEGER)        AS id,
    object_id,
    CAST(office_id AS INTEGER) AS office_id,
    description,
    region,
    address1,
    address2,
    city,
    zip_code,
    state_code,
    country_code,
    CAST(latitude AS DOUBLE)   AS latitude,
    CAST(longitude AS DOUBLE)  AS longitude,
    created_at,                -- en esta tabla el diccionario las trae como texto; se conservan así
    updated_at
FROM raw.offices;