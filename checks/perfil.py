import duckdb, glob, os

con = duckdb.connect()
for f in sorted(glob.glob("data/raw/*.csv")):
    t = os.path.basename(f)[:-4]
    src = f"read_csv_auto('{f}', sample_size=-1)"
    n = con.execute(f"SELECT count(*) FROM {src}").fetchone()[0]
    print(f"\n== {t}: {n} filas")
    cols = con.execute(f"DESCRIBE SELECT * FROM {src}").fetchall()
    for c in cols:
        nulos = con.execute(f'SELECT count(*) FROM {src} WHERE "{c[0]}" IS NULL').fetchone()[0]
        print(f"   {c[0]:30} {c[1]:12} nulos={nulos}")

