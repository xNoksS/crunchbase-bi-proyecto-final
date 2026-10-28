-- CAPA RAW: archivos tal como llegan, sin modificar (todo como texto).
-- Ajusta los nombres de archivo en data/raw/ si no coinciden.
CREATE SCHEMA IF NOT EXISTS raw;

CREATE OR REPLACE TABLE raw.objects       AS SELECT * FROM read_csv('data/raw/objects.csv',       header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.funding_rounds AS SELECT * FROM read_csv('data/raw/funding_rounds.csv', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.investments   AS SELECT * FROM read_csv('data/raw/investments.csv',   header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.acquisitions  AS SELECT * FROM read_csv('data/raw/acquisitions.csv',  header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.ipos          AS SELECT * FROM read_csv('data/raw/ipos.csv',          header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.funds         AS SELECT * FROM read_csv('data/raw/funds.csv',         header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.relationships AS SELECT * FROM read_csv('data/raw/relationships.csv', header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.people        AS SELECT * FROM read_csv('data/raw/people.csv',        header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.degrees       AS SELECT * FROM read_csv('data/raw/degrees.csv',       header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.milestones    AS SELECT * FROM read_csv('data/raw/milestones.csv',    header=true, all_varchar=true);
CREATE OR REPLACE TABLE raw.offices       AS SELECT * FROM read_csv('data/raw/offices.csv',       header=true, all_varchar=true);
