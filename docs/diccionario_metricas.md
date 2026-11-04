# Diccionario de métricas y KPIs (Parte 3)

> **Regla del equipo:** antes de construir cualquier gráfica, la métrica se define
> aquí y **todos la usan igual**. Dos analistas pueden llegar a conclusiones
> opuestas con los mismos datos solo porque definieron "éxito" distinto.
>
> **Formato de cada ficha:** nombre · definición en lenguaje de negocio · fórmula
> (SQL o DAX) · tablas y campos · tratamiento de nulos · limitaciones conocidas.
>
> **Estado del archivo.** Olga unifica el formato; Cristina verifica que cada
> campo citado exista en el modelo. Secciones por dueño:
>
> | Métrica | Dueño |
> |---|---|
> | Financiamiento total | Hugo |
> | Éxito de una startup | Hugo |
> | Tiempo a la salida | Hugo |
> | Inversionista activo | Ximena |
> | Éxito de un inversionista (dos versiones) | Ximena |
> | Benchmark de inversionista | Ximena |

---

## 1. Financiamiento total

**Dueño:** Hugo · **Tabla de resultado:** `marts.met_financiamiento_empresa`,
`marts.met_financiamiento_mensual`, `marts.met_financiamiento_industria_anio`
· **SQL:** `sql/04_marts/09_met_financiamiento.sql`

**Definición en lenguaje de negocio.**
El dinero que un grupo de empresas levantó en rondas de financiamiento, sumado en
**dólares estadounidenses**, contando solo las rondas cuyo monto conocemos en esa
moneda. El grupo puede ser una empresa, una industria, un mes o todo el mercado.

**Fórmula.**
```sql
SUM(marts.fact_rondas.monto_usd)
```
Siempre se publica acompañada de:
```sql
COUNT(*)                                   AS n_rondas
COUNT(monto_usd)                           AS n_rondas_con_monto
COUNT(monto_usd)::DOUBLE / COUNT(*)        AS cobertura_monto
```

**Tablas y campos.** `marts.fact_rondas` (`monto_usd`, `fecha`, `empresa_id`),
`marts.dim_empresa` (`industria`, `pais`, `etapa`) para segmentar.

**Tratamiento de nulos.**
- `monto_usd = NULL` significa **monto desconocido, no cero**. Se excluye de la
  suma. Nunca se imputa 0 ni un promedio.
- Los ceros originales ya se convirtieron a NULL en la capa clean
  (bitácora de calidad, fila 11): 6,000 de 52,928 rondas (11.3%).
- 362 rondas (0.68%) traían monto en otra moneda y quedaron en NULL: no hay tabla
  de tipos de cambio y convertir con una tasa inventada metería datos falsos
  (bitácora, fila 8).
- 248 rondas no tienen fecha y quedan fuera de los cortes por mes, año y cohorte.

**Moneda.** Una sola: USD. No se mezclan monedas en ninguna suma.

**Limitaciones conocidas.**
1. Es un **piso, no el mercado**: al excluir el 11% sin monto, el total está
   subestimado por una cantidad que no podemos cuantificar.
2. La cobertura del monto **no es pareja en el tiempo** ni entre industrias. Si
   los meses buenos reportan mejor, la serie exagera los picos. Se mide en
   `notebooks/hugo_02_ciclos_mercado.ipynb`, sección 5.
3. **No sumar montos a través del puente ronda-inversionista.** El monto vive
   solo en `fact_rondas`; el puente reparte con `peso = 1/n_inversionistas`
   (ver `sql/04_marts/05_puente_ronda_inversionista.sql`).
4. Incluye las rondas de las 232 empresas con registro de reemplazo
   (bitácora, fila 9): son $7.6 mil millones reales, el 1.8% del total. Se pueden
   filtrar con `es_registro_faltante = FALSE`.

---

## 2. Éxito de una startup

**Dueño:** Hugo · **Tabla de resultado:** `marts.met_salida_empresa`
· **SQL:** `sql/04_marts/10_met_salidas.sql`

**Definición en lenguaje de negocio.**
Una startup tuvo éxito si **salió**: fue adquirida o salió a bolsa (IPO), con
fecha dentro del periodo de los datos (hasta el 2013-12-31). Las dos formas
cuentan igual y **no se exige monto mínimo**.

**Fórmula.**
```sql
-- definición principal
marts.met_salida_empresa.tuvo_salida            -- BOOLEAN
-- versión alternativa (sensibilidad)
marts.met_salida_empresa.tuvo_salida_con_monto  -- la salida además trae monto en USD
-- dentro de un horizonte H
fecha_primera_salida <= fecha_primera_ronda + to_years(H)
```

**Tablas y campos.** `marts.fact_adquisiciones` (`empresa_adquirida_id`, `fecha`,
`precio_usd`), `marts.fact_ipos` (`empresa_id`, `fecha`, `monto_levantado_usd`),
`marts.fact_rondas` (`fecha` → primera ronda), `marts.dim_empresa`.

**Por qué sin monto mínimo.** 7,085 de 9,561 adquisiciones no reportan precio en
USD (bitácora, fila 12) y los montos de IPO están casi vacíos (fila 13). Exigir
monto borraría tres de cada cuatro salidas reales y convertiría una métrica de
desenlace en una métrica de **calidad del reporte**.

**Tratamiento de nulos y de lo que no se ve.**
- Empresa sin salida registrada → `tuvo_salida = FALSE` **y** `censurada = TRUE`.
  Falso no es lo mismo que fracaso: significa "no observamos salida hasta
  2013-12-31".
- Adquisiciones sin fecha (29 filas) no entran: no se pueden ubicar en un horizonte.
- Si una empresa tiene varias salidas, manda la **más antigua**.

**Limitaciones conocidas.**
1. **No mide rentabilidad.** Una adquisición de rescate cuenta igual que una
   exitosa. "Salida" es un *proxy*, y en 3 de cada 4 casos ni sabemos el precio.
2. **Sesgo de supervivencia del registro.** Crunchbase documenta mejor lo que
   termina bien; los cierres silenciosos simplemente dejan de aparecer.
3. **Depende del horizonte.** Sin fijar un horizonte, las cohortes viejas salen
   siempre mejor solo porque llevan más tiempo observadas.
4. La definición alternativa con monto reduce la tasa a una fracción que se
   reporta en `marts.res_sensibilidad_exito`.

---

## 3. Tiempo a la salida

**Dueño:** Hugo · **Tabla de resultado:** `marts.met_salida_empresa`,
`marts.res_tiempo_salida_cohorte` · **SQL:** `sql/04_marts/10_met_salidas.sql`

**Definición en lenguaje de negocio.**
Cuántos años pasan entre la **primera ronda de financiamiento** de una empresa y
su **primera salida** (adquisición o IPO).

**Fórmula.**
```sql
date_diff('day', fecha_primera_ronda, fecha_primera_salida) / 365.25
    AS anios_a_salida_desde_ronda          -- métrica principal
date_diff('day', fecha_fundacion,     fecha_primera_salida) / 365.25
    AS anios_a_salida_desde_fundacion      -- control, solo donde hay founded_at
```
Para resumir se usa la **mediana** (y p25/p75), no el promedio: la distribución
tiene cola larga y el promedio se lo lleva un puñado de casos de 15 años.

**Desde qué evento se mide, y por qué.**
Desde la **primera ronda**. `founded_at` está vacía en el 54% de las empresas
(bitácora, fila 2) y además se anuló donde había eventos anteriores a la fecha
de fundación (`sql/03_clean/12_clean_fechas.sql`). Medir desde fundación
descartaría más de la mitad de los casos y, peor, los descartaría de forma no
aleatoria. La versión desde fundación se publica como columna aparte.

**Tratamiento de las empresas que aún no salen.**
Están **censuradas por la derecha**: no tienen tiempo a la salida todavía, y no
son ceros ni infinitos. Quedan fuera del cálculo y se cuentan aparte en
`anios_observados_sin_salida` y `empresas_censuradas`.

**Limitaciones conocidas.**
1. **Está sesgado hacia abajo.** Solo se ven las salidas que ya ocurrieron: las
   lentas están todavía por pasar y nunca entran al cálculo. La mediana real es
   mayor que la que reportamos.
2. El sesgo es **peor en las cohortes recientes**, que tienen menos ventana.
3. Empresas que levantaron capital antes de que Crunchbase registrara bien
   pueden tener una "primera ronda" posterior a la real, lo que acorta el tiempo
   medido.
4. No distingue salida planeada de venta forzada.

---

## 4. Inversionista activo

**Dueño:** Ximena · **Tabla de resultado:** `marts.res_inversionista_activo`
· **Notebook:** `notebooks/ximena_analisis_inversionistas.ipynb` (secciones 1 y 4)

**Definición en lenguaje de negocio.**
Un inversionista está **activo** si participó en **al menos una ronda registrada
entre 2005-01-01 y 2013-12-31**. No es "sigue existiendo": es "aparece
invirtiendo dentro de la ventana que el dataset cubre bien".

**Fórmula.**
```python
act = participaciones[participaciones.fecha >= pd.Timestamp('2005-01-01')]
actividad = act.groupby('inversionista_id').agg(
    rondas_activas   = ('ronda_id',   'nunique'),
    empresas_activas = ('empresa_id', 'nunique'),
    primera_ronda    = ('fecha',      'min'),
    ultima_ronda     = ('fecha',      'max'))
```

**Tablas y campos.** `marts.puente_ronda_inversionista` (`inversionista_id`,
`ronda_id`, `peso`), `marts.fact_rondas` (`empresa_id`, `fecha`, `monto_usd`),
`marts.dim_inversionista` (`nombre`, `tipo_inversionista`, `pais`).

**Portafolio = empresas distintas.** No participaciones ni rondas. Un
inversionista que entró en cinco rondas de la misma empresa tiene portafolio de
**una**, no de cinco. Eso es lo que evita que un inversionista de seguimiento
parezca diversificado.

**Tratamiento de nulos y casos especiales.**
- Las participaciones se leen con `DISTINCT`: el puente puede repetir el par
  inversionista–ronda y se contaría doble.
- Las rondas sin fecha quedan fuera; no se pueden ubicar en la ventana.
- `monto_usd × peso` es una **distribución contable**, no capital efectivamente
  aportado. No se usa para rankear habilidad.

**Cifras de control.** 79,206 participaciones · 16,897 inversionistas ·
21,327 empresas · 63,235 pares únicos inversionista–empresa.

**Limitaciones conocidas.**
1. "Activo" depende del registro, no de la actividad real: un fondo que invirtió
   fuera de lo que Crunchbase documenta aparece como inactivo.
2. Los 16,897 son activos **en algún momento de nueve años**, no activos al
   final de la ventana.
3. El corte de 2005 hereda el problema de cobertura de la sección 1 de
   `docs/limitaciones.md`.

---

## 5. Éxito de un inversionista (dos versiones)

**Dueño:** Ximena · **Tabla de resultado:** `marts.res_exito_inversionista`
· **Notebook:** `notebooks/ximena_analisis_inversionistas.ipynb` (sección 5)

**Definición en lenguaje de negocio.**
Qué proporción de las empresas de su portafolio tuvo una salida. Se publican
**dos versiones a propósito**, porque la respuesta cambia según cuál se use.

| | V1 — salida observada | V2 — salida a 5 años |
|---|---|---|
| Qué cuenta | adquisición o IPO posterior a la primera inversión, hasta 2013-12-31 | salida dentro de **5 años** de la primera inversión |
| Qué empresas entran | todas las del portafolio | solo primeras inversiones **hasta 2008-12-31** |
| Para qué sirve | aprovecha todo el dato disponible | garantiza que toda empresa tuvo 5 años de observación |
| Qué sesgo trae | favorece inversiones viejas, que llevan más ventana | pierde todo lo invertido después de 2008 |

**Fórmula.**
```python
tasa_v1 = exitos_v1 / n_empresas       # n_empresas   = empresas distintas
tasa_v2 = exitos_v2 / elegibles_v2     # elegibles_v2 = primera inversion <= 2008-12-31
```

**Tablas y campos.** `marts.met_salida_empresa` (`fecha_primera_salida`), más las
de la sección 4. La salida solo cuenta si es **posterior** a la primera inversión
de ese inversionista en esa empresa.

**Umbral mínimo de portafolio: 5 empresas.** Con cinco empresas una salida vale
**20 puntos porcentuales**; con una empresa vale 100. Es un filtro operativo, no
una garantía estadística, y por eso se contrasta con umbrales 1, 3, 5, 10 y 20
en `marts.res_sensibilidad_inversionistas`. En V2 se exigen cinco empresas **con
ventana completa de observación**.

**Tratamiento de nulos y casos especiales.**
- `tasa_v2` queda **NULL**, no cero, cuando el inversionista no tiene ninguna
  empresa con ventana completa (`elegibles_v2 = 0`). Caso real: 500 Startups,
  315 empresas en portafolio, `tasa_v2` nula porque empezó en 2010.
- Los rankings V1 y V2 se comparan sobre un **universo común** de inversionistas,
  nunca sobre dos listas con denominadores distintos.

**Limitaciones conocidas.**
1. **Salida ≠ retorno.** Una adquisición de rescate cuenta igual que una de mil
   millones. No mide rentabilidad ni demuestra habilidad causal.
2. **V1 está censurada:** las salidas lentas de inversiones recientes todavía no
   ocurrieron dentro del dataset.
3. **V2 cambia la muestra, no solo la métrica:** de 16,897 inversionistas, solo
   5,463 tienen alguna empresa elegible y 919 llegan a cinco.
4. El Top 10 depende de la versión: **coinciden 4 de 10** (ver la sección 4 de
   `docs/limitaciones.md`).

---

## 6. Benchmark de inversionista

**Dueño:** Ximena · **Tabla de resultado:** `marts.res_benchmark_inversionista`
· **Notebook:** `notebooks/ximena_analisis_inversionistas.ipynb` (sección 6)

**Definición en lenguaje de negocio.**
La tasa de salida **promedio de los demás inversionistas** que invirtieron en la
misma **industria + etapa + cohorte de primera inversión**. Sirve para separar
*habilidad* de *haberle atinado al sector y al año*: un 25% en software semilla
de 2007 no significa lo mismo que un 25% en biotech.

**Fórmula.**
```python
benchmark_tasa_v1 = (suma de tasa_v1 de los pares del segmento - la propia)
                    / (pares del segmento - los propios)
diferencia_pp     = (tasa_v1 - benchmark_tasa_v1) * 100
```
El inversionista evaluado se **excluye por completo** de sus propios pares
(`pares_otros = pares - pares_propios`), para que no se compare contra sí mismo.

**Tablas y campos.** `marts.dim_empresa` (`industria`, `etapa`) cruzada contra el
portafolio de la sección 4, más `tasa_v1` de la sección 5.

**Tratamiento de nulos y casos especiales.**
- Si un segmento no tiene **otros** inversionistas, el benchmark queda **NULL**.
  No se imputa cero: un cero haría ver al inversionista infinitamente mejor que
  un benchmark que en realidad no existe.
- `segmentos_comparables` publica sobre cuántos segmentos se construyó el
  promedio, para que se vea cuándo descansa en uno solo.

**Limitaciones conocidas.**
1. **No controla lo no observado.** Industria, etapa y cohorte ayudan, pero no
   igualan calidad del equipo, geografía ni acceso al deal.
2. **`etapa` puede ser posterior a la inversión.** Es la etapa registrada en la
   dimensión, no necesariamente la que tenía la empresa cuando entró el dinero.
3. **Con portafolios de una empresa el indicador se rompe.** Sin filtrar, los
   primeros lugares por `diferencia_pp` son inversionistas con **una** empresa,
   tasa 1.0 y benchmark 0.0, es decir `diferencia_pp = 100`. Por eso el benchmark
   solo se lee junto con el umbral de portafolio de la sección 5.

---

## 7. Tasa de salida por segmento, con plazo observable

**Dueño:** Jose · **Tabla de resultado:** `marts.dash_industria_etapa`
· **SQL:** `sql/04_marts/21_dash_industrias.sql` · **Medidas:** `dashboard/medidas_dax.md`, sección 2

**Definición en lenguaje de negocio.**
De las empresas de un segmento (industria, país, etapa de entrada, cohorte) que
ya tuvieron tiempo de cumplir H años desde su primera ronda, qué porcentaje tuvo
una salida (§2) dentro de esos H años. Es la misma tasa de las curvas de salida
(análisis 1), abierta por segmento para el dashboard.

**Fórmula.**
```sql
SUM(salidas_5a) / SUM(observables_5a)          -- nunca el promedio de tasas
-- observable a H anios:  fecha_primera_ronda + H anios <= 2013-12-31
-- salida valida:         fecha_primera_salida >= fecha_primera_ronda
```

**Tablas y campos.** `marts.met_financiamiento_empresa` (`tipo_primera_ronda`,
`cohorte_primera_ronda`, `fecha_primera_ronda`), `marts.met_salida_empresa`
(`fecha_primera_salida`, `tuvo_salida_con_monto`).

**Tratamiento de nulos y casos especiales.**
- Etapa de entrada = tipo de la **primera** ronda. No se usa `dim_empresa.etapa`,
  que es la **última** ronda y por lo tanto contiene información del futuro.
- 202 empresas tienen su primera salida **antes** de su primera ronda registrada
  (134 IPOs con rondas post-IPO y 68 adquisiciones). No cuentan como salida de
  esa cohorte.
- Solo cohortes 2005-2013 y sin registros de reemplazo (`es_registro_faltante`).
- El dashboard oculta tasas calculadas sobre menos de 100 empresas observables.

**Limitaciones conocidas.** Las mismas de §2. Además, con celdas chicas
(industria × país × etapa × cohorte) la tasa solo es legible al agregar.

## 8. Exceso sobre el benchmark (implementación del §6 en el dashboard)

**Dueño:** Jose, sobre la definición de Ximena · **Tabla de resultado:**
`marts.dash_portafolio`, `marts.dash_inversionista` · **SQL:**
`sql/04_marts/20_dash_inversionistas.sql`

**Definición en lenguaje de negocio.**
Cuántos puntos porcentuales por encima (o por debajo) de lo esperado está la tasa
de éxito de un inversionista, donde "lo esperado" es la tasa de las empresas que
levantaron una ronda del mismo tipo, en la misma industria y el mismo año en que
él entró.

**Fórmula.**
```sql
exceso_v1 = exitos_v1 / n_empresas - AVG(bench_v1)    -- por inversionista
-- bench_v1 de cada par = tasa V1 de la celda industria x etapa x anio de entrada
-- si la celda tiene menos de 10 empresas, se usa la celda etapa x anio
```

**Tratamiento de nulos.** Participaciones sin fecha de ronda quedan fuera (no se
puede ubicar la entrada). Ninguna suma de montos pasa por el puente.

**Limitaciones conocidas.**
1. La mayoría de los inversionistas grandes supera su benchmark (119 de 146 con
   al menos 50 empresas): las empresas con inversionistas registrados están mejor
   documentadas. Sirve para **comparar inversionistas entre sí**, no para decir que
   le ganan al mercado.
2. El benchmark incluye a la propia empresa del inversionista; en celdas chicas
   eso acerca el benchmark a su tasa.
