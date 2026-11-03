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
