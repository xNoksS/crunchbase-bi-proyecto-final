#!/usr/bin/env python3
"""Checks automatizados. Falla (exit 1) si cualquier check encuentra violaciones.

Cada check es (nombre, SQL que devuelve el NÚMERO de filas que violan la regla).
Mínimo exigido por el proyecto:
  - llaves primarias duplicadas o nulas
  - llaves foráneas huérfanas
  - conteos de filas que no reconcilian entre capas (sin explicación documentada)
  - montos negativos o fechas imposibles (p. ej. ronda anterior a la fundación)
"""
import pathlib
import sys

import duckdb

DB = pathlib.Path(__file__).resolve().parents[1] / "data" / "crunchbase.duckdb"

CHECKS: list[tuple[str, str]] = [
    # Ejemplos para que Olga los adapte cuando exista la capa clean:
    # ("PK duplicada: clean.objects.id",
    #  "SELECT count(*) FROM (SELECT id FROM clean.objects GROUP BY id HAVING count(*) > 1)"),
    # ("FK huérfana: clean.funding_rounds.object_id -> clean.objects.id",
    #  "SELECT count(*) FROM clean.funding_rounds f LEFT JOIN clean.objects o ON f.object_id = o.id WHERE o.id IS NULL"),
]


def main() -> int:
    if not CHECKS:
        print("ERROR: no hay checks definidos todavía.")
        return 1
    con = duckdb.connect(str(DB), read_only=True)
    failed = 0
    for name, sql in CHECKS:
        n = con.execute(sql).fetchone()[0]
        status = "OK  " if n == 0 else "FAIL"
        print(f"{status} {name} -> {n}")
        failed += n != 0
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
