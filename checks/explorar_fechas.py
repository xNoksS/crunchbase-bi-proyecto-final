import duckdb

c = duckdb.connect("data/crunchbase.duckdb", read_only=True)
casos = [
    ("clean", "objects", "founded_at"), ("clean", "objects", "closed_at"),
    ("clean", "funds", "funded_at"), ("staging", "degrees", "graduated_at"),
    ("staging", "relationships", "start_at"), ("staging", "relationships", "end_at"),
    ("staging", "milestones", "milestone_at"),
]
for s, t, col in casos:
    r = c.execute(
        f"SELECT min({col}), max({col}), "
        f"count(*) FILTER (WHERE {col} < DATE '1800-01-01'), "
        f"count(*) FILTER (WHERE {col} > DATE '2013-12-31') "
        f"FROM {s}.{t} WHERE {col} < DATE '1800-01-01' OR {col} > DATE '2013-12-31'"
    ).fetchone()
    print(f"{s}.{t}.{col}: min={r[0]}, max={r[1]}, antes de 1800={r[2]}, despues de 2013={r[3]}")

r = c.execute(
    "SELECT count(*), count(DISTINCT h.object_id), "
    "count(*) FILTER (WHERE o.founded_at - h.funded_at > 365) "
    "FROM clean.funding_rounds h JOIN clean.objects o ON h.object_id = o.id "
    "WHERE h.funded_at < o.founded_at"
).fetchone()
print(f"\nRondas antes de la fundacion: {r[0]} filas, {r[1]} empresas, {r[2]} con mas de 1 año de diferencia")