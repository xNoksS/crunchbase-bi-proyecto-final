\# Diccionario del modelo dimensional (esquema `marts`)



Modelo en estrella con 3 tablas de hechos que comparten dimensiones conformadas

(empresa, inversionista, fecha) y una tabla puente para la relación ronda–inversionista.

Origen: esquema `clean` en DuckDB. Código: `sql/04\_marts/`.



Convenciones:

\- Montos `\*\_usd`: solo tienen valor si la moneda original era USD. `NULL` = desconocido, no cero.

\- Fechas posteriores a 2013-12-31 son `NULL` (corte de Crunchbase).

\- `sin\_dato` reemplaza nulos en atributos de segmentación para que los filtros del dashboard no pierdan filas.



\---



\## dim\_empresa

\*\*Grano:\*\* una fila por empresa (`objects` con `entity\_type = 'Company'`). \*\*Filas:\*\* 197,560

\*\*PK:\*\* `empresa\_id`



| Columna | Tipo | Descripción |

|---|---|---|

| empresa\_id | VARCHAR | Id de Crunchbase con prefijo `c:` |

| nombre | VARCHAR | Nombre de la empresa |

| industria | VARCHAR | `category\_code` de Crunchbase; `sin\_dato` si falta |

| pais | VARCHAR | Código de país ISO-3; `sin\_dato` si falta |

| region | VARCHAR | Región o ciudad principal reportada |

| estatus | VARCHAR | operating, acquired, ipo, closed |

| fecha\_fundacion | DATE | Fecha de fundación |

| anio\_fundacion | BIGINT | Año de fundación (cohorte por fundación) |

| fecha\_primera\_ronda | DATE | Fecha mínima en `fact\_rondas`; `NULL` si nunca levantó capital |

| anio\_primera\_ronda | BIGINT | Año de primera ronda (cohorte de las curvas de salida) |

| etapa | VARCHAR | Tipo de la última ronda; `sin\_rondas` si nunca levantó capital |

| es\_registro\_faltante | BOOLEAN | `TRUE` si es un registro de reemplazo creado en limpieza para evitar FK huérfanas |



Nota: el 84% (165,825) nunca levantó una ronda. Para tasas de éxito, el universo son las empresas con `fecha\_primera\_ronda` no nula.



\---



\## dim\_inversionista

\*\*Grano:\*\* una fila por inversionista que participa en al menos una ronda. \*\*Filas:\*\* 17,152

\*\*PK:\*\* `inversionista\_id`



| Columna | Tipo | Descripción |

|---|---|---|

| inversionista\_id | VARCHAR | Id con prefijo `f:` (organización financiera), `c:` (empresa) o `p:` (persona) |

| nombre | VARCHAR | Nombre del inversionista |

| tipo\_inversionista | VARCHAR | organizacion\_financiera (44%), persona (40%), corporativo (15%) |

| pais | VARCHAR | País del inversionista; `sin\_dato` si falta |

| industria | VARCHAR | `category\_code` del inversionista; `sin\_dato` si falta |

| es\_registro\_faltante | BOOLEAN | `TRUE` si es registro de reemplazo |



Solo atributos descriptivos. Actividad y éxito se calculan según el diccionario de métricas.



\---



\## dim\_fecha

\*\*Grano:\*\* una fila por día calendario, de 1901-01-01 a 2013-12-31. \*\*Filas:\*\* 41,273

\*\*PK:\*\* `fecha`



| Columna | Tipo | Descripción |

|---|---|---|

| fecha | DATE | Día calendario |

| anio | SMALLINT | Año |

| trimestre | SMALLINT | 1 a 4 |

| mes | SMALLINT | 1 a 12 |

| anio\_mes | DATE | Primer día del mes; llave para unir series mensuales (FRED) |

| etiqueta\_mes | VARCHAR | Texto `YYYY-MM` para ejes del dashboard |



\---



\## fact\_rondas

\*\*Grano:\*\* una fila por ronda de financiamiento. \*\*Filas:\*\* 52,928

\*\*PK:\*\* `ronda\_id` · \*\*FK:\*\* `empresa\_id` → dim\_empresa, `fecha` → dim\_fecha



| Columna | Tipo | Descripción |

|---|---|---|

| ronda\_id | INTEGER | `funding\_round\_id` de Crunchbase |

| empresa\_id | VARCHAR | Empresa que levantó la ronda |

| fecha | DATE | Fecha de la ronda |

| tipo\_ronda | VARCHAR | angel, venture, series-a, series-b, series-c+, private-equity, crowdfunding, post-ipo, other |

| codigo\_ronda | VARCHAR | Código detallado (a, b, c, seed…) |

| monto\_usd | DECIMAL(18,2) | Monto levantado en USD; `NULL` en 11% de rondas |

| valuacion\_pre\_usd | DECIMAL(18,2) | Valuación pre-money en USD |

| valuacion\_post\_usd | DECIMAL(18,2) | Valuación post-money en USD |

| participantes\_reportados | INTEGER | Participantes según Crunchbase |

| n\_inversionistas | BIGINT | Inversionistas registrados en `investments` para la ronda (0 si ninguno) |

| es\_primera\_ronda | BOOLEAN | Primera ronda de la empresa |

| es\_ultima\_ronda | BOOLEAN | Última ronda registrada de la empresa |



\*\*Única tabla donde vive el monto de la ronda.\*\* Total: US$420.6 mil millones.



\---



\## puente\_ronda\_inversionista

\*\*Grano:\*\* una fila por par (ronda, inversionista). \*\*Filas:\*\* 80,800

\*\*PK:\*\* (`ronda\_id`, `inversionista\_id`) · \*\*FK:\*\* `ronda\_id` → fact\_rondas, `inversionista\_id` → dim\_inversionista



| Columna | Tipo | Descripción |

|---|---|---|

| ronda\_id | INTEGER | Ronda |

| inversionista\_id | VARCHAR | Inversionista que participó |

| peso | DOUBLE | 1 / número de inversionistas de la ronda; los pesos de cada ronda suman 1 |



\*\*Uso correcto:\*\*

\- Monto atribuido a un inversionista = `fact\_rondas.monto\_usd \* peso`.

\- Participación (en cuántas rondas entró) = `COUNT(DISTINCT ronda\_id)`, sin peso.



\*\*Verificación:\*\* total desde fact\_rondas (rondas con inversionistas) = US$306.4 mil millones; total por el puente con peso = US$306.4 mil millones; sin peso = US$938.5 mil millones (inflado 3 veces).



\---



\## fact\_adquisiciones

\*\*Grano:\*\* una fila por adquisición. \*\*Filas:\*\* 9,561

\*\*PK:\*\* `adquisicion\_id` · \*\*FK:\*\* `empresa\_adquirida\_id` y `empresa\_adquirente\_id` → dim\_empresa (dimensión de rol), `fecha` → dim\_fecha



| Columna | Tipo | Descripción |

|---|---|---|

| adquisicion\_id | INTEGER | `acquisition\_id` de Crunchbase |

| empresa\_adquirida\_id | VARCHAR | Empresa comprada |

| empresa\_adquirente\_id | VARCHAR | Empresa compradora |

| fecha | DATE | Fecha de la adquisición (`NULL` en 29 casos) |

| forma\_pago | VARCHAR | cash, stock, cash\_and\_stock |

| precio\_usd | DECIMAL(18,2) | Precio en USD; solo 26% lo tiene |



Nota: 150 empresas aparecen adquiridas más de una vez; las métricas de éxito usan la primera salida.



\---



\## fact\_ipos

\*\*Grano:\*\* una fila por IPO. \*\*Filas:\*\* 1,254

\*\*PK:\*\* `ipo\_id` · \*\*FK:\*\* `empresa\_id` → dim\_empresa, `fecha` → dim\_fecha



| Columna | Tipo | Descripción |

|---|---|---|

| ipo\_id | INTEGER | `ipo\_id` de Crunchbase |

| empresa\_id | VARCHAR | Empresa que salió a bolsa |

| fecha | DATE | Fecha de la IPO; `NULL` en 47% de casos |

| simbolo\_bursatil | VARCHAR | Ticker |

| monto\_levantado\_usd | DECIMAL(18,2) | Casi vacío (132 filas); no usar para montos |

| valuacion\_usd | DECIMAL(18,2) | Casi vacío; no usar para montos |



Usar para conteo de salidas y fecha, no para montos.

