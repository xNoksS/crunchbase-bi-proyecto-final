CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.investments AS
SELECT
    CAST(id AS INTEGER)                 AS id,
    CAST(funding_round_id AS INTEGER)   AS funding_round_id,
    funded_object_id,
    investor_object_id,
    CAST(created_at AS TIMESTAMP)       AS created_at,
    CAST(updated_at AS TIMESTAMP)       AS updated_at
FROM raw.investments;