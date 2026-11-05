# Contribución individual y uso de IA — Hugo Tobías

**Rol:** Analista de startups e industrias
**Rama principal:** `hugo/fred` (PR #12, fusionado)

## 1. Rol en el equipo

Las métricas de startups (financiamiento, éxito y tiempo a la salida), el análisis
obligatorio 1 (curvas de salida por cohorte) y el análisis elegido (b) de
financiamiento y ciclos de mercado, incluida la serie externa. Más mis secciones
del diccionario de métricas y de limitaciones, y la revisión del PR de Ximena.

## 2. Qué hice

### Serie externa (`data/external/`)

Tres series mensuales de FRED (Reserva Federal de St. Louis) de 1990-01 a 2013-12,
288 filas: NASDAQ compuesto (`NASDAQCOM`, diario promediado a mes), tasa de fondos
federales (`FEDFUNDS`) y desempleo (`UNRATE`). Sin valores faltantes.

| Archivo | Qué es |
|---|---|
| `fred_mensual.csv` | La serie. Se versiona, con excepción explícita en `.gitignore` |
| `descargar_fred.py` | La descarga de nuevo desde cero, para que sea reproducible |
| `README.md` | Fuente, frecuencia, periodo, unidades y por qué estas tres series |

### SQL (`sql/04_marts/`)

| Archivo | Tabla | Grano (una fila es) |
|---|---|---|
| `08_serie_externa_mensual.sql` | `marts.serie_externa_mensual` | un mes de la serie de FRED |
| `09_met_financiamiento.sql` | `met_financiamiento_empresa`, `_mensual`, `_industria_anio` | una empresa / un mes / una industria-año |
| `10_met_salidas.sql` | `marts.met_salida_empresa` | una empresa con al menos una ronda |
| `11_res_curvas_salida.sql` | `marts.res_curvas_salida` | una cohorte × horizonte (1, 3 y 5 años) |

Dos decisiones que no son obvias y que puedo defender:

- **La cohorte es el año de la primera ronda, no el de fundación.** `founded_at`
  falta en el 54% de las empresas (bitácora, fila 2). Medir desde fundación
  botaría más de la mitad de los casos, y no al azar.
- **La primera salida se toma con `ROW_NUMBER`, no con `arg_min(monto, fecha)`.**
  `arg_min` ignora las filas con monto nulo, así que habría devuelto el monto de
  una salida posterior. Tres de cada cuatro salidas no traen monto.

### Análisis 1 — curvas de salida (`notebooks/hugo_01_curvas_salida.ipynb`)

Qué porcentaje de empresas tuvo adquisición o IPO dentro de 1, 3 y 5 años de su
primera ronda, por cohorte. El punto fino es la **censura por la derecha**: una
empresa cuya primera ronda fue en 2012 no puede tener una salida a 3 años dentro
de un dataset que corta en 2013. Si se la cuenta en el denominador aparece como
fracaso, y las tasas de los años recientes se desploman solas.

Tratamiento en dos niveles: la empresa es observable a H años solo si
`fecha_primera_ronda + H <= 2013-12-31` y, si no lo es, sale del denominador pero
no del numerador; y la cohorte se marca `cohorte_completa = FALSE` cuando
`cohorte + H > 2013` y no se cita ni se grafica como tasa final. El notebook
compara la tasa correcta contra la **tasa ingenua** para que se vea el tamaño del
artefacto.

Tablas que escribe: `res_tiempo_salida_cohorte`, `res_sensibilidad_exito`,
`res_sensibilidad_exito_cohorte`, `res_cobertura_cohortes`.

### Análisis (b) — financiamiento y ciclos de mercado (`notebooks/hugo_02_ciclos_mercado.ipynb`)

Serie mensual de financiamiento 2005–2013 contra NASDAQ, tasa de fondos federales
y desempleo: correlación contemporánea, correlación cruzada por rezago y una
regresión con errores estándar HAC (Newey-West, 12 rezagos), porque los residuos
de una serie mensual están autocorrelacionados y los errores clásicos saldrían
demasiado optimistas.

Tablas que escribe: `res_ciclos_mercado_coef`, `res_ciclos_mercado_panel`,
`res_ciclos_mercado_rezagos`, `res_cobertura_anual`.

### Documentación

- `docs/diccionario_metricas.md`: fichas 1 (financiamiento total), 2 (éxito de una
  startup) y 3 (tiempo a la salida). Más las fichas 4, 5 y 6 al corregir el PR de
  Ximena (ver abajo).
- `docs/limitaciones.md`: puntos 1 (cobertura y corte temporal) y 2 (empresas
  fundadas recientemente). Más los puntos 3 y 4, también del PR de Ximena.

### Revisión del PR #8 de Ximena

Dos vueltas. En la primera pedí cambios porque el notebook reconstruía todo desde
`clean` en vez de usar el modelo, guardaba resultados en CSV sueltos, calculaba el
benchmark sin usarlo para comparar y tenía celdas de markdown con código adentro.
Los atendió casi todos.

En la segunda el notebook todavía no corría completo, así que lo arreglé
directamente en su rama en vez de devolvérselo, porque ya estábamos sobre la fecha:

1. La celda de persistencia fallaba con `ResourceInUseException` y las 8 celdas
   siguientes nunca se ejecutaban, incluidas las de hallazgos y limitaciones. De
   las cuatro tablas de resultados solo se creaba la primera.
2. El anexo buscaba la base en una ruta que no existe en el repo y la reabría en
   solo-lectura sin cerrar la conexión previa.
3. Faltaban las fichas 4, 5 y 6 del diccionario y `docs/limitaciones.md` iba con
   tres puntos cuando el enunciado pide mínimo cuatro. Las escribí transcribiendo
   las definiciones de sus propias celdas de markdown y sus resultados ya
   ejecutados, y se lo avisé para que las revisara.

## 3. Problemas que encontré y cómo se resolvieron

- **Creí ver la crisis puntocom donde no estaba.** Al principio interpreté la caída
  de la tasa de salida entre las cohortes 1999 y 2000 como efecto de la burbuja. Al
  revisar la cobertura resultó que la cohorte 1999 tiene **53 empresas**: una sola
  empresa mueve la tasa dos puntos. No era una señal, era ruido. De ahí salió el
  corte de 2005 y el punto 1 de limitaciones.
- **El corte de 2005 cambió el resultado, no solo la presentación.** Crunchbase
  pasa de 291 rondas en 2004 a 1,633 en 2005, seis veces en un año. Al recalcular
  la correlación entre financiamiento y NASDAQ solo sobre 2005+, **sube de 0.38 a
  0.55**: los años flacos no aportaban señal, metían ruido.
- **`DECIMAL` de DuckDB llega a Python como `Decimal` y rompe `numpy.log`.** Se
  resolvió con `CAST(... AS DOUBLE)` en el SQL y `pd.to_numeric` en el notebook.
- **DuckDB 2.0 ya no permite `register()` si quedó un resultado sin consumir.** El
  `.fetchone()` de un `print` deja el resultado a medias y la siguiente vuelta del
  bucle revienta. Me pasó en mi notebook 2 y después, idéntico, en el de Ximena.
- **`docs/resultados_checks.md` se me coló en un commit.** Lo regenera `run_all.py`
  y es de Olga; solo había cambiado la fecha de ejecución. Lo saqué con
  `git restore` y `commit --amend` antes del push.

## 4. Cómo reproducir mi parte

```
python run_all.py                                 # raw -> staging -> clean -> marts + checks
jupyter nbconvert --to notebook --execute --inplace \
  notebooks/hugo_01_curvas_salida.ipynb \
  notebooks/hugo_02_ciclos_mercado.ipynb          # escriben las tablas res_*
python publish/publish_to_neon.py                 # publica marts en Neon
```

El orden importa: `run_all.py` borra y recrea la base desde cero, así que si se
publica antes de correr los notebooks, las tablas `res_*` no existen.

Para rehacer la serie externa desde la fuente: `python data/external/descargar_fred.py`.

## 5. Uso de IA

**Herramienta:** Claude (Anthropic), en Cowork, del 2 al 5 de noviembre de 2026.
No tuvo acceso a mis credenciales ni a Neon, y no hizo `push` ni fusionó pull
requests. Los commits de este repositorio con mi nombre los corrí yo.

**Para qué lo usé.** Más que como corrector: redactó los cuatro archivos `.sql`,
los dos notebooks y mis secciones del diccionario y de limitaciones, a partir del
esquema del equipo y de los resultados que yo le iba pasando. También redactó los
comentarios de mi revisión del PR de Ximena y este archivo.

**Qué hice yo.** Corrí todo en mi máquina y le pegué la salida de cada comando,
que es lo que lo obligaba a trabajar con las cifras reales y no con supuestos.
Decidí el alcance en cada punto: hasta dónde arreglar el PR de Ximena, qué entraba
en mis secciones y qué no, y qué no se tocaba a estas alturas.

**Dos veces las cifras no cuadraron y hubo que rehacer el análisis.** La primera,
cuando la tasa de la cohorte 1999 resultó estar construida sobre 53 empresas y
hubo que reescribir la interpretación de los dos notebooks. La segunda, cuando una
conclusión afirmaba que exigir monto no cambiaba el orden entre cohortes sin que
eso estuviera calculado; al calcularlo con Spearman resultó falso a 3 años
(ρ = 0.26) aunque sí se sostiene a 5 (ρ = 1.00), y la conclusión se reescribió.
Ambas correcciones están en el historial de la conversación y en los notebooks.

**Lo que esto significa.** La redacción es en buena parte de la IA; la ejecución,
la validación contra los datos y las decisiones son mías, y la responsabilidad por
lo que dicen estos archivos también.

## 6. Límites de mi contribución

No construí la carga ni la limpieza (Noel), el modelo dimensional (Cristina), los
checks y la bitácora (Olga), el análisis de inversionistas (Ximena, más allá de
corregirle el notebook y completarle dos documentos) ni el dashboard y el memo
(Jose). Mis tablas se apoyan en el modelo de Cristina y en la capa `clean` de Noel.

**Pendientes de la revisión de Jose a mi PR #12.** Pidió tres cambios. El primero,
que `publish_to_neon.py` no subía mis tablas, lo corrigió él. Los otros dos quedan
abiertos y los declaro aquí en vez de omitirlos:

- **202 empresas tienen su primera salida antes de su primera ronda** y generan
  tiempos negativos. `res_curvas_salida` cuenta esas salidas dentro del horizonte
  sin exigir que sean posteriores a la ronda, lo que infla las tasas a 1 año de las
  cohortes recientes. Jose midió el efecto en la cohorte 2010: 2.5% contra 1.6%. El
  arreglo es agregar esa condición en `11_res_curvas_salida.sql`, pero obliga a
  recorrer el pipeline, los notebooks y la publicación a Neon, y el equipo decidió
  no moverlo con la entrega encima.
- **Un comentario del SQL de `fact_rondas` dice lo contrario de lo que hace el
  código** sobre cuándo `monto_usd` trae valor. Es un error de documentación, no de
  cifras.

El efecto medido es el de 1 año. No tengo medido cuánto mueve las tasas a 3 y 5
años, que son las que sostienen las conclusiones del análisis 1, y no lo afirmo
sin haberlo calculado: 202 casos sobre un universo de decenas de miles deberían
pesar poco a esos horizontes, pero eso es una expectativa, no un resultado.
