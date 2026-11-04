"""Imprime las cifras necesarias para completar docs/bitacora_calidad.md (solo lectura)."""
import duckdb

c = duckdb.connect("data/crunchbase.duckdb", read_only=True)


def q(titulo, sql):
    try:
        print(f"{titulo}: {c.execute(sql).fetchone()}")
    except Exception as e:  # una columna distinta no debe frenar el resto
        print(f"{titulo}: ERROR {str(e).splitlines()[0]}")


print("== Fila 2: objects.founded_at (filas, con valor)")
q("staging", "SELECT count(*), count(founded_at) FROM staging.objects")
q("clean  ", "SELECT count(*), count(founded_at) FROM clean.objects")

print("\n== Fila 7: funding_rounds.funded_at (filas, nulos)")
q("staging", "SELECT count(*), count(*) FILTER (WHERE funded_at IS NULL) FROM staging.funding_rounds")
q("clean  ", "SELECT count(*), count(*) FILTER (WHERE funded_at IS NULL) FROM clean.funding_rounds")

print("\n== Fila 8: funding_rounds clean (ceros / nulos)")
q("raised_amount_usd (ceros, nulos)", "SELECT count(*) FILTER (WHERE raised_amount_usd = 0), count(*) FILTER (WHERE raised_amount_usd IS NULL) FROM clean.funding_rounds")
q("raised_amount (ceros, nulos)", "SELECT count(*) FILTER (WHERE raised_amount = 0), count(*) FILTER (WHERE raised_amount IS NULL) FROM clean.funding_rounds")
q("pre_money_valuation_usd (ceros, con valor)", "SELECT count(*) FILTER (WHERE pre_money_valuation_usd = 0), count(pre_money_valuation_usd) FROM clean.funding_rounds")
q("post_money_valuation_usd (ceros, con valor)", "SELECT count(*) FILTER (WHERE post_money_valuation_usd = 0), count(post_money_valuation_usd) FROM clean.funding_rounds")
q("monto original > 0 y USD nulo o 0", "SELECT count(*) FROM clean.funding_rounds WHERE raised_amount > 0 AND coalesce(raised_amount_usd, 0) = 0")

print("\n== Fila 17: fechas > 2013-12-31 en filas que SI pasan a clean (staging) y en clean")
q("degrees.graduated_at staging", "SELECT count(*) FROM staging.degrees WHERE graduated_at > DATE '2013-12-31' AND object_id IN (SELECT object_id FROM staging.people)")
q("relationships.start_at staging", "SELECT count(*) FROM staging.relationships WHERE start_at > DATE '2013-12-31' AND person_object_id IN (SELECT object_id FROM staging.people)")
q("relationships.end_at staging", "SELECT count(*) FROM staging.relationships WHERE end_at > DATE '2013-12-31' AND person_object_id IN (SELECT object_id FROM staging.people)")
q("milestones.milestone_at staging", "SELECT count(*) FROM staging.milestones WHERE milestone_at > DATE '2013-12-31'")
q("clean (las 4 columnas, debe ser 0,0,0,0)", "SELECT (SELECT count(*) FROM clean.degrees WHERE graduated_at > DATE '2013-12-31'), (SELECT count(*) FROM clean.relationships WHERE start_at > DATE '2013-12-31'), (SELECT count(*) FROM clean.relationships WHERE end_at > DATE '2013-12-31'), (SELECT count(*) FROM clean.milestones WHERE milestone_at > DATE '2013-12-31')")

print("\n== Fila 18: offices (ambas coordenadas en 0, alguna en 0)")
q("staging", "SELECT count(*) FILTER (WHERE latitude = 0 AND longitude = 0), count(*) FILTER (WHERE latitude = 0 OR longitude = 0) FROM staging.offices")
q("clean  ", "SELECT count(*) FILTER (WHERE latitude = 0 AND longitude = 0), count(*) FILTER (WHERE latitude = 0 OR longitude = 0) FROM clean.offices")