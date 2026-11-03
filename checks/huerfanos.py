import duckdb

con = duckdb.connect('data/crunchbase.duckdb', read_only=True)

# (tabla hija, columna FK, tabla padre, columna PK), según el diccionario de datos
RELACIONES = [
    ('objects', 'parent_id', 'objects', 'id'),
    ('funding_rounds', 'object_id', 'objects', 'id'),
    ('investments', 'funding_round_id', 'funding_rounds', 'funding_round_id'),
    ('investments', 'funded_object_id', 'objects', 'id'),
    ('investments', 'investor_object_id', 'objects', 'id'),
    ('acquisitions', 'acquiring_object_id', 'objects', 'id'),
    ('acquisitions', 'acquired_object_id', 'objects', 'id'),
    ('ipos', 'object_id', 'objects', 'id'),
    ('funds', 'object_id', 'objects', 'id'),
    ('people', 'object_id', 'objects', 'id'),
    ('degrees', 'object_id', 'people', 'object_id'),
    ('relationships', 'person_object_id', 'people', 'object_id'),
    ('relationships', 'relationship_object_id', 'objects', 'id'),
    ('milestones', 'object_id', 'objects', 'id'),
    ('offices', 'object_id', 'objects', 'id'),
]

for hijo, fk, padre, pk in RELACIONES:
    huerfanos, distintas = con.execute(f"""
        SELECT count(*), count(DISTINCT h.{fk})
        FROM staging.{hijo} h
        LEFT JOIN {'clean' if padre == 'objects' else 'staging'}.{padre} p ON h.{fk} = p.{pk}
        WHERE h.{fk} IS NOT NULL AND p.{pk} IS NULL
    """).fetchone()
    nulas = con.execute(f"SELECT count(*) FROM staging.{hijo} WHERE {fk} IS NULL").fetchone()[0]
    print(f"{hijo}.{fk} -> {padre}.{pk}: huerfanos={huerfanos} (llaves distintas={distintas}), FK nulas={nulas}")