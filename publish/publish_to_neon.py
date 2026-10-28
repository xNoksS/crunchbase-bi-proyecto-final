#!/usr/bin/env python3
"""Publica el esquema marts de DuckDB al esquema marts de Neon (Postgres).

Lee credenciales de .env (NEON_HOST, NEON_DB, NEON_USER, NEON_PASSWORD).
TODO (Noel + Cristina): definir PK e índices en las FK después de cargar,
y revisar que pg_database_size quede bajo 0.5 GB.
"""
import os
import pathlib

import duckdb
from dotenv import load_dotenv

ROOT = pathlib.Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")

dsn = (
    f"host={os.environ['NEON_HOST']} dbname={os.environ['NEON_DB']} "
    f"user={os.environ['NEON_USER']} password={os.environ['NEON_PASSWORD']} "
    f"sslmode={os.environ.get('NEON_SSLMODE', 'require')}"
)

con = duckdb.connect(str(ROOT / "data" / "crunchbase.duckdb"), read_only=True)
con.execute("INSTALL postgres; LOAD postgres;")
con.execute(f"ATTACH '{dsn}' AS neon (TYPE postgres)")
con.execute("CREATE SCHEMA IF NOT EXISTS neon.marts")

tables = [r[0] for r in con.execute(
    "SELECT table_name FROM information_schema.tables WHERE table_schema = 'marts'").fetchall()]
for t in tables:
    print(f"Publicando marts.{t}")
    con.execute(f"DROP TABLE IF EXISTS neon.marts.{t}")
    con.execute(f"CREATE TABLE neon.marts.{t} AS SELECT * FROM marts.{t}")

size = con.execute("SELECT * FROM postgres_query('neon', 'SELECT pg_size_pretty(pg_database_size(current_database()))')").fetchone()
print("Tamaño de la base en Neon:", size[0])
