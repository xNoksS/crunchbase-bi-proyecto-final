# Limitaciones (Parte 6)

> El PDF pide **al menos cuatro** de los puntos de su lista, analizados
> críticamente y **con evidencia de nuestros propios datos**, no en abstracto.
> Jose integra esto al memo ejecutivo.
>
> | Punto | Dueño |
> |---|---|
> | Cobertura y corte temporal | Hugo |
> | Empresas fundadas recientemente | Hugo |
> | Sesgo de supervivencia y de selección | Ximena |
> | Sensibilidad a las definiciones | Ximena |
> | Valores faltantes y decisiones de limpieza | Olga |
> | Sesgo geográfico y sectorial | Cristina |

---

## 1. Cobertura y corte temporal del conjunto de datos

**Dueño: Hugo.**

Los datos **terminan el 31 de diciembre de 2013**, pero el problema serio está
del otro lado: **Crunchbase prácticamente no registra nada antes de 2005**. Eso
no es un detalle de fechas, define qué preguntas se pueden contestar.

**Evidencia de nuestros datos** (`marts.res_cobertura_anual`, generada por
`notebooks/hugo_02_ciclos_mercado.ipynb`):

| Año | Rondas registradas | Promedio por mes |
|---|---|---|
| 1999 | 76 | 6 |
| 2000 | 125 | 10 |
| 2003 | 159 | 13 |
| 2004 | 291 | 24 |
| **2005** | **1,633** | **136** |
| 2008 | 3,774 | 315 |
| 2013 | 11,072 | 923 |

De 2004 a 2005 el conteo se multiplica por **seis en un solo año**. El mercado de
capital de riesgo no se multiplicó por seis en 2005: lo que cambió fue que
Crunchbase empezó a registrarlo. Lo mismo del lado de las empresas: la cohorte de
primera ronda de 1999 tiene **53 empresas** y la de 2004 tiene **204**, contra
**1,437 en 2005** y **5,850 en 2013** (`marts.res_cobertura_cohortes`).

**Qué hicimos con eso.**
1. El análisis de ciclos de mercado **arranca en 2005**, el primer año con al
   menos 100 rondas al mes en promedio. El umbral está en el notebook y la tabla
   que lo justifica también.
2. Las curvas de salida **solo se grafican y se citan para cohortes de 2005 en
   adelante** (mínimo 500 empresas observables). Las cohortes anteriores se
   calculan y se publican en la tabla, marcadas, pero no sostienen ninguna
   conclusión: en una cohorte de 53 empresas, una sola empresa mueve la tasa dos
   puntos porcentuales.
3. Una consecuencia concreta: al recalcular la correlación entre financiamiento y
   NASDAQ solo sobre 2005+, **sube de 0.38 a 0.55**. Los años flacos no estaban
   aportando señal, estaban metiendo ruido.

**Otros dos efectos de borde.**
- El pipeline anula toda fecha posterior a 2013-12-31 porque es imposible
  (`sql/03_clean/12_clean_fechas.sql`): 1 `graduated_at`, 31 `start_at`, 65
  `end_at` y 59 `milestone_at` (bitácora, fila 17). Si el dataset fuera una
  fotografía limpia del mercado, esas fechas no existirían.
- La **cobertura del monto** (`cobertura_monto` en `marts.met_financiamiento_mensual`)
  no es constante mes a mes: el 11.3% de rondas sin monto no está repartido
  parejo. Por eso el análisis de ciclos se corre también con el **número de
  rondas**, que no depende de que la ronda reporte cifra.

**Qué significa para el comité.** Las conclusiones son sobre **2005-2013**, no
sobre "el mercado". Y esa ventana contiene un solo ciclo grande —la crisis de
2008 y su recuperación—, así que un modelo que la ajusta bien no está
describiendo una regularidad, está describiendo un episodio.

---

## 2. Las empresas fundadas recientemente no han tenido tiempo de salir

**Dueño: Hugo.**

Este es el sesgo que más fácil produce una conclusión falsa, y es el que el
análisis 1 trata de frente.

**El problema.** Una empresa cuya primera ronda fue en 2012 no puede tener una
salida a 3 años dentro de un dataset que corta en 2013. Si la contamos en el
denominador, aparece como fracaso. Al hacerlo con toda la cohorte, las tasas de
salida de los años recientes **se desploman solas** y se lee como "las startups
de ahora son peores".

**Evidencia de nuestros datos.**
- `marts.res_curvas_salida` publica, por cohorte y horizonte, tres columnas que
  lo hacen visible: `empresas_observables`, `pct_observable` y `cohorte_completa`.
- La sección 3 del notebook compara la tasa correcta contra la **tasa ingenua**
  (la que sale de contar a todos en el denominador). La brecha aparece
  exactamente en las cohortes 2011-2013 y crece conforme el horizonte es más
  largo, que es la firma de un artefacto de medición, no de un cambio real.

**Qué hicimos.**
1. Las empresas sin plazo cumplido salen del **denominador** del horizonte
   (si ya salieron, siguen contando en el numerador).
2. La cohorte se marca `cohorte_completa = FALSE` cuando `cohorte + H > 2013`, y
   esas cohortes **no se citan ni se grafican** como tasa final.
3. El tiempo a la salida se calcula solo sobre las que salieron, y se reporta al
   lado el conteo de censuradas, porque también está sesgado hacia abajo: las
   salidas lentas todavía no ocurrieron.

**Qué significa para el comité.** La tasa de salida más reciente que se puede
citar con honestidad a 5 años es la de la cohorte **2008**, y solo hay **cuatro**
cohortes legibles a ese horizonte (2005, 2006, 2007 y 2008). La caída que se
observa en ese tramo —de 17.6% a 11.0%— descansa sobre esas cuatro
observaciones, y la última cierra su ventana exactamente en el borde del
dataset. Cualquier lectura sobre 2011-2013 es provisional por construcción.

El mismo sesgo se cuela en el **tiempo a la salida**: la mediana baja en las
cohortes recientes, pero no porque las empresas salgan más rápido. A una empresa
de 2011 solo se le pueden ver salidas de menos de tres años, así que las lentas
quedan fuera del cálculo por definición.

## 5. Valores faltantes y decisiones de limpieza

**Dueño: Olga.**

Los datos de Crunchbase tienen huecos grandes, y cada decisión de limpieza
(poner NULL, excluir una fila, crear un registro de reemplazo) pudo mover los
resultados. Cada decisión está documentada en `docs/bitacora_calidad.md`, con
filas antes y después. Aquí se resume cuáles importan para las conclusiones.

**Evidencia de nuestros datos.**

| Problema | Filas afectadas | Qué hicimos | Bitácora |
|---|---|---|---|
| Sin fecha de fundación (`founded_at`) | 98,742 de 463,927 objetos tienen fecha (21%); en los datos originales, el 46% de las empresas | Se conserva NULL | 2 |
| Eventos anteriores a la fundación | 1,824 rondas, 26 adquisiciones y 14 IPOs, en 1,642 empresas con rondas | `founded_at` a NULL en esas empresas | 21 |
| Rondas sin fecha (`funded_at`) | 248 (0.47%) | Se conservan, pero quedan fuera de cohortes y de la serie mensual | 7 |
| Monto en 0 en USD | 6,000 rondas (11.3%) | Ceros a NULL, sin imputar | 5, 8, 11 |
| Valoración pre-money | solo 31 rondas con valor; post-money, 1,194 | No se usa | 8 |
| Coordenadas (0, 0) | 80,350 de 112,718 oficinas (71%) | A NULL; se usa `country_code` | 18 |
| Llaves sin registro padre | 1,276 registros de reemplazo en `objects`; 302 rondas huérfanas suman USD 7.6 mil millones (1.8% del total) | Se conservan con atributos desconocidos | 9 |

**Cómo pudieron cambiar los resultados.**
1. **Los montos están subestimados.** Los 6,000 ceros se convirtieron en NULL en
   lugar de imputarse, así que los totales de financiamiento solo suman lo que
   se reportó y los promedios por ronda se calculan solo sobre las rondas con
   monto. De esos 6,000, 5,638 no reportaron cifra y 362 (0.68%) tenían monto en
   otra moneda, sin convertir porque los datos no traen tipos de cambio.
2. **La decisión de no convertir monedas no es neutral.** Las 362 rondas sin
   conversión son todas de monedas distintas al dólar (EUR 216, GBP 68, CAD 54,
   JPY 12, SEK 6, AUD 3, NIS 3). Quedan sin monto justamente las rondas fuera de
   Estados Unidos, lo que se suma al sesgo geográfico de la sección 6.
3. **Las cohortes no dependen de la fundación.** Como `founded_at` falta en
   casi 4 de cada 5 objetos, las cohortes y el tiempo a la salida se miden
   desde la primera ronda. Quien segmente por año de fundación trabaja con una
   muestra pequeña y menos representativa.
4. **Los reemplazos tienen atributos desconocidos.** Los 1,276 registros creados
   en `objects` no tienen industria ni país, y aparecen como "desconocido" en
   los cortes por industria y país. Se conservaron porque borrarlos habría
   quitado rondas e inversiones por USD 7.6 mil millones.
5. **Efecto pequeño de las exclusiones.** Las filas excluidas por no tener
   padre (554 de `degrees` y 920 de `relationships`) no entran en ningún análisis
   de este proyecto, así que no cambian las conclusiones.

**Qué significa para el comité.** Los totales de financiamiento son un piso, no
la cifra real del mercado, y subestiman más a las empresas fuera de Estados
Unidos. Ningún análisis de este proyecto depende de la fecha de fundación,
justo porque es el campo más incompleto. Ninguna decisión de limpieza borró
datos de monto o de fecha: todas pasan a NULL y se pueden revisar.
