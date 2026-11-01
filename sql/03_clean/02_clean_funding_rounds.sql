CREATE SCHEMA IF NOT EXISTS clean;

-- Los ceros en montos y valoraciones significan "desconocido", no "cero dólares".
CREATE OR REPLACE TABLE clean.funding_rounds AS
SELECT * REPLACE (
    NULLIF(raised_amount_usd, 0)        AS raised_amount_usd,
    NULLIF(raised_amount, 0)            AS raised_amount,
    NULLIF(pre_money_valuation_usd, 0)  AS pre_money_valuation_usd,
    NULLIF(post_money_valuation_usd, 0) AS post_money_valuation_usd
)
FROM staging.funding_rounds;