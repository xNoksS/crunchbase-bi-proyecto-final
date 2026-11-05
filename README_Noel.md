# Contribución individual y uso de IA — Noel Sánchez

Proyecto Final 2026 · Financiamiento de Startups (Crunchbase) · Business Intelligence · Universidad del Istmo

## 1. Rol en el equipo

Líder del equipo e ingeniería de datos. Me encargué de la base técnica sobre la que trabajó el resto: el esqueleto del repositorio, la carga de datos, las capas `staging` y `clean`, las reglas de calidad, la publicación en Neon y la revisión de los pull requests de los demás.

## 2. Qué hice

### Repositorio y flujo de trabajo
- Esqueleto del proyecto: estructura de carpetas, `run_all.py` (reconstruye todo el pipeline en orden), `requirements.txt`, `.gitignore`, `.env.example` y plantilla de pull request.
- Flujo de trabajo: una rama por tarea, pull request y revisión de otra persona antes de entrar a `main`. Las credenciales viven solo en `.env`, que Git ignora.
- Revisé y fusioné los PR de las demás partes: modelo dimensional (Cristina), checks (Olga), bitácora (Olga), análisis de ciclos de mercado y FRED (Hugo), análisis de inversionistas (Ximena) y dashboard (Jose). Cuando la rama de Jose había borrado el `README.md` de la raíz, pedí restaurarlo antes de fusionar.

### Capa raw y staging
- Carga de los CSV de Crunchbase (`sql/01_raw/01_load_raw.sql`) y perfilado de los datos crudos (`docs/perfil_raw.txt`).
- Las 11 tablas de `staging` (`sql/02_staging/`): `objects`, `funding_rounds`, `investments`, `acquisitions`, `ipos`, `funds`, `people`, `degrees`, `relationships`, `milestones` y `offices`. Aquí solo se tipifica (fechas y números), sin cambiar el contenido.

### Capa clean y reglas de calidad (`sql/03_clean/`)
| Decisión | Por qué |
|---|---|
| Montos y valuaciones en 0 pasan a NULL | Un 0 casi siempre significa "monto desconocido", no "se levantó cero". Si se deja, sesga promedios y sumas. |
| Las columnas `*_usd` solo se llenan si la moneda original es USD | No hay tabla de tipos de cambio. Mezclar monedas daría cifras falsas. |
| 1,276 registros de reemplazo (`es_registro_faltante`) en `clean.objects` | Hay objetos mencionados en otras tablas que no existen en `objects`. Se conservan marcados para no perder filas. |
| Se excluyen filas huérfanas: acquisitions −1, ipos −5, degrees −554, relationships −920 | No se pueden unir a nada y rompen las llaves foráneas. Cada exclusión está documentada y validada por los checks. |
| Fechas posteriores a 2013-12-31 pasan a NULL | El dataset termina en 2013, así que son errores. |
| `founded_at` pasa a NULL si la empresa tiene eventos anteriores a su fundación | Es una inconsistencia lógica (`12_clean_fechas.sql`). |
| Precio de adquisición mayor a US$100 mil millones pasa a NULL y se marca `is_price_outlier` | Había un valor de US$2.6 billones, evidentemente un error de captura. |

### Calidad y documentación
- Ajusté `checks/run_checks.py` (de Olga) para reflejar las exclusiones reales (`DELTAS_CLEAN`). Resultado final: **71 checks, 0 fallas, 0 avisos**.
- Bitácora de calidad (`docs/bitacora_calidad.md`): las filas de hallazgos de raw y staging, el puente de inversionistas (fila 20), las fechas de `objects` (fila 21) y el outlier de adquisiciones (fila 22). Olga completó el resto de la bitácora.
- Registro de decisiones (`docs/decisiones.md`) y resultados de checks (`docs/resultados_checks.md`).

### Publicación en Neon (`publish/publish_to_neon.py`)
- El script lee `DATABASE_URL` del `.env`, exporta cada tabla de DuckDB, la carga a Postgres con `COPY`, agrega llaves primarias e índices, otorga lectura al rol de solo lectura y verifica que el conteo de filas coincida con el original. Jose lo extendió después con las tablas `dash_*`.
- Creé el rol de solo lectura `bi_lectura` con SQL y verifiqué que puede leer y no escribir. El dashboard usa este rol y no el del dueño (principio de mínimo privilegio).
- Resultado: **30 tablas publicadas, unos 110 MB** (el límite del proyecto es 0.5 GB).

## 3. Problemas que encontramos y cómo se resolvieron

- **Duplicados en la tabla puente:** 102 pares ronda–inversionista repetidos (80,902 → 80,800). Se usó `DISTINCT` para que el peso `1/n` no se calculara mal.
- **Fechas imposibles:** Olga detectó 8 checks de fechas fallando; yo implementé la corrección en `12_clean_fechas.sql` y quedaron en 0.
- **Outlier de US$2.6 billones:** apareció al revisar el máximo de `price_amount_usd` antes de publicar. Se corrigió en `04_clean_acquisitions.sql`.
- **Credencial expuesta:** una cadena de conexión del dueño se compartió por error. Se rotó la contraseña de inmediato y desde entonces las contraseñas se generan localmente y no se comparten por chat.
- **README borrado por una rama:** se detectó antes de fusionar y se restauró.

## 4. Cómo reproducir mi parte

```
python run_all.py                       # raw -> staging -> clean -> marts + checks
python checks/run_checks.py --estricto  # 71 checks; los avisos cuentan como fallas
python publish/publish_to_neon.py       # requiere DATABASE_URL en .env
```

## 5. Uso de IA

**Herramienta:** Claude (Anthropic), usado como asistente de consulta durante todo el proyecto.

**Para qué lo usé**
- **Como guía paso a paso** del proceso: qué capa seguía, en qué orden hacer las cosas, cómo trabajar con Git (ramas, pull requests, resolver conflictos) y cómo configurar Neon.
- **Para proponer borradores de SQL y de código** (reglas de la capa clean, ajustes a los checks y el script de publicación). Yo los ejecuté, comprobé los resultados con mis propias consultas y los ajusté.
- **Para revisar el trabajo del equipo** en el repositorio y redactar mensajes y comentarios de pull request.
- **Para preparar la defensa:** resumen del proyecto y preguntas de práctica.

**Cómo se tomaron las decisiones**
- Las decisiones de diseño las tomé yo, con base en lo que íbamos hablando con el equipo y en lo que mostraban los datos. La IA presentaba opciones y yo elegía.
- El proceso fue iterativo. Yo corría cada paso, pegaba el resultado y se corregía con ese feedback. Ejemplos:
  - Un `NameError` en `run_checks.py` después de una edición se corrigió al ver el error.
  - El outlier de US$2.6 billones lo encontró mi consulta de verificación, y a partir de ahí se definió la regla del umbral.
  - Un error mío: la IA dijo que había 10 tablas `res_*` cuando eran 9, y lo corregí contrastando con la base.
  - También se corrigió la contraseña expuesta y el formato roto de una fila de la bitácora.
- Los conteos y cifras que cito en este documento los comprobé yo en la base y en el repositorio, no los tomé de la IA sin verificar.

**Qué no hizo la IA:** no accedió a mi cuenta de Neon ni a mis credenciales, no hizo `push` ni fusionó pull requests, y no decidió qué datos excluir sin que yo lo revisara.

## 6. Límites de mi contribución

- No construí el modelo dimensional (Cristina), el análisis de inversionistas (Ximena), el análisis de ciclos de mercado y las tablas `res_*` (Hugo), ni el dashboard, memo y presentación (Jose). Sí revisé y puedo explicar cómo se conectan con la capa clean.
- No hay tabla de tipos de cambio, así que las cifras en dólares cubren solo las rondas, adquisiciones y salidas a bolsa registradas originalmente en USD.
