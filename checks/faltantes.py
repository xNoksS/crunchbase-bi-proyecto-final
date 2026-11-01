import duckdb

con = duckdb.connect('data/crunchbase.duckdb', read_only=True)

filas = con.execute("""
    WITH llaves AS (
        SELECT parent_id AS k FROM staging.objects WHERE parent_id IS NOT NULL
        UNION SELECT object_id FROM staging.funding_rounds
        UNION SELECT funded_object_id FROM staging.investments
        UNION SELECT investor_object_id FROM staging.investments
        UNION SELECT acquiring_object_id FROM staging.acquisitions
        UNION SELECT acquired_object_id FROM staging.acquisitions WHERE acquired_object_id IS NOT NULL
        UNION SELECT object_id FROM staging.ipos WHERE object_id IS NOT NULL
        UNION SELECT object_id FROM staging.funds
        UNION SELECT object_id FROM staging.people
        UNION SELECT relationship_object_id FROM staging.relationships
        UNION SELECT object_id FROM staging.milestones
        UNION SELECT object_id FROM staging.offices
    )
    SELECT split_part(l.k, ':', 1) AS prefijo, count(*) AS llaves_faltantes
    FROM llaves l
    LEFT JOIN staging.objects o ON l.k = o.id
    WHERE o.id IS NULL
    GROUP BY 1
    ORDER BY 2 DESC
""").fetchall()

print(filas)