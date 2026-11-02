import duckdb

con = duckdb.connect('data/crunchbase.duckdb', read_only=True)

# (tabla, columna que debe ser llave primaria), según el diccionario de datos
PKS = [
    ('objects', 'id'),
    ('funding_rounds', 'funding_round_id'),
    ('investments', 'id'),
    ('acquisitions', 'acquisition_id'),
    ('ipos', 'ipo_id'),
    ('funds', 'fund_id'),
    ('people', 'object_id'),
    ('degrees', 'id'),
    ('relationships', 'relationship_id'),
    ('milestones', 'id'),
    ('offices', 'office_id'),
]

for tabla, pk in PKS:
    filas, distintas, nulas = con.execute(f"""
        SELECT count(*), count(DISTINCT {pk}), count(*) FILTER (WHERE {pk} IS NULL)
        FROM staging.{tabla}
    """).fetchone()
    duplicadas = (filas - nulas) - distintas
    print(f"{tabla}.{pk}: filas={filas}, nulas={nulas}, filas repetidas={duplicadas}")