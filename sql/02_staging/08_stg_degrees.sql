CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.degrees AS
SELECT
    CAST(id AS INTEGER)           AS id,
    object_id,
    degree_type,
    subject,
    institution,
    CAST(graduated_at AS DATE)    AS graduated_at,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(updated_at AS TIMESTAMP) AS updated_at
FROM raw.degrees;