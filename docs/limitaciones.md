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
