CREATE SCHEMA IF NOT EXISTS staging;
CREATE OR REPLACE TABLE staging.milestones AS
SELECT
    CAST(id AS INTEGER)           AS id,
    object_id,
    CAST(milestone_at AS DATE)    AS milestone_at,
    milestone_code,
    description,
    source_url,
    source_description,
    CAST(created_at AS TIMESTAMP) AS created_at,
    CAST(updated_at AS TIMESTAMP) AS updated_at
FROM raw.milestones;