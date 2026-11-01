CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.relationships AS
SELECT
    CAST(id AS INTEGER)              AS id,
    CAST(relationship_id AS INTEGER) AS relationship_id,
    person_object_id,
    relationship_object_id,
    CAST(start_at AS DATE)           AS start_at,
    CAST(end_at AS DATE)             AS end_at,
    CAST(is_past AS INTEGER)         AS is_past,
    CAST(sequence AS INTEGER)        AS sequence,
    title,
    CAST(created_at AS TIMESTAMP)    AS created_at,
    CAST(updated_at AS TIMESTAMP)    AS updated_at
FROM raw.relationships;