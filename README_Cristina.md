## Modelo dimensional (Cristina Pineda — Modelado de datos)

Esquema en estrella en `sql/04_marts/`, construido sobre `clean.*`. `python run_all.py` lo reconstruye junto con el resto del pipeline.

| Archivo | Tabla | Grano (una fila es) |
|---|---|---|
| `01_dim_fecha.sql` | `marts.dim_fecha` | un día (1901-01-01 a 2013-12-31) |
| `02_dim_empresa.sql` | `marts.dim_empresa` | una empresa |
| `03_dim_inversionista.sql` | `marts.dim_inversionista` | un inversionista con al menos una ronda |
| `04_fact_rondas.sql` | `marts.fact_rondas` | una ronda de financiamiento |
| `05_puente_ronda_inversionista.sql` | `marts.puente_ronda_inversionista` | un par (ronda, inversionista) |
| `06_fact_adquisiciones.sql` | `marts.fact_adquisiciones` | una adquisición |
| `07_fact_ipos.sql` | `marts.fact_ipos` | una IPO |

La serie externa `marts.serie_externa_mensual` (FRED, `08_…`, de Hugo) se une por `dim_fecha.anio_mes`.

**Sin doble conteo:** el monto vive solo en `fact_rondas`. El puente lleva `peso = 1 / n_inversionistas`, así que el monto por inversionista es `monto_usd * peso`. Verificado: US$306.4 mil millones por ambos caminos; sin peso saldrían US$938.5 mil millones.

**Documentación:** `docs/diccionario_modelo.md` (tablas y columnas), `docs/diagrama_modelo.md` (diagrama) y `docs/justificacion_modelo.md` (decisiones, alternativas descartadas y limitaciones).
