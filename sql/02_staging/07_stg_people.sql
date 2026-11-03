CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.people AS
SELECT
    CAST(id AS INTEGER) AS id,
    object_id,
    first_name,
    last_name,
    birthplace,
    affiliation_name
FROM raw.people;