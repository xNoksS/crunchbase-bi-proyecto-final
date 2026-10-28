#!/usr/bin/env python3
"""Reconstruye el pipeline desde cero: raw -> staging -> clean -> marts -> checks.

Uso:  python run_all.py [--skip-checks]
Cada capa es un esquema de DuckDB; cada transformación es un .sql en sql/<capa>/,
ejecutado en orden alfabético (prefijo numérico: 01_, 02_, ...).
"""
import pathlib
import subprocess
import sys

import duckdb

ROOT = pathlib.Path(__file__).resolve().parent
DB = ROOT / "data" / "crunchbase.duckdb"
LAYERS = ["01_raw", "02_staging", "03_clean", "04_marts"]


def main() -> int:
    DB.parent.mkdir(exist_ok=True)
    if DB.exists():
        DB.unlink()  # siempre desde cero
    con = duckdb.connect(str(DB))
    for layer in LAYERS:
        files = sorted((ROOT / "sql" / layer).glob("*.sql"))
        if not files:
            print(f"[{layer}] (sin archivos .sql todavía)")
        for f in files:
            print(f"[{layer}] {f.name}")
            con.execute(f.read_text(encoding="utf-8"))
    con.close()

    if "--skip-checks" in sys.argv:
        print("Checks omitidos (--skip-checks). No uses esto para entregar.")
        return 0
    return subprocess.run([sys.executable, str(ROOT / "checks" / "run_checks.py")]).returncode


if __name__ == "__main__":
    sys.exit(main())
