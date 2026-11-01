# Bitácora de calidad de datos

\# Bitácora de calidad de datos



Una fila por decisión de limpieza. Sin bitácora la limpieza no es auditable.



| # | Tabla afectada | Problema | Filas antes | Filas después | Decisión | Justificación | Responsable |

|---|---|---|---|---|---|---|---|

| 1 | raw y staging (11 tablas) | Verificar que la carga y la estandarización de tipos no pierden ni duplican filas | Según diccionario: objects 462,651; funding\_rounds 52,928; investments 80,902; acquisitions 9,562; ipos 1,259; funds 1,564; relationships 402,878; people 226,709; degrees 109,610; milestones 39,456; offices 112,718 | Iguales en `raw.\*` y en `staging.\*` | Sin cambios; raw se conserva intacto y staging solo estandariza nombres y tipos (CAST) | Los 11 conteos coinciden exactamente entre diccionario, raw y staging (2026-11-01) | Noel |

| 2 | objects.founded\_at | 362,210 de 462,651 filas (78%) son NULL. Por tipo: Person 226,708/226,708 (100%); Company 105,326/196,553 (54%); Product 23,129/27,738 (83%); FinancialOrg 7,047/11,652 (60%) | 462,651 | Pendiente | En staging se conserva como NULL. Decisión final pendiente en clean | En personas es esperable (no se "fundan"). En empresas es dato faltante real: más de la mitad no tiene fecha. Las cohortes deben armarse por año de primera ronda, no por fundación. Afecta la métrica "tiempo a la salida" y la sección de limitaciones | Noel / Olga |

| 3 | objects.founded\_at | Verificar tipos antes del cast | 462,651 | 462,651 | `CAST` a DATE en staging | 0 celdas vacías como texto y 0 valores no nulos que fallen la conversión a DATE; los 100,441 valores no nulos se conservan en staging | Noel |

| 4 | people.object\_id → objects.id | FK huérfana confirmada: `p:268597` está en `people` y no existe en `objects` (people 226,709 vs objects Person 226,708) | 226,709 | Pendiente | Pendiente en clean | Un JOIN entre ambas tablas pierde esa fila; debe resolverse para que PK/FK queden consistentes y entrar a los checks de FK huérfanas | Noel / Olga |

| 5 | funding\_rounds.raised\_amount\_usd | 6,000 de 52,928 rondas (11.3%) tienen monto 0 y ninguna tiene NULL (verificado en raw) | 52,928 | Pendiente | Pendiente en clean (propuesta: tratar 0 como monto desconocido, es decir NULL, o marcarlo con una bandera) | Una ronda de $0 no es realista; sumar ceros no es lo mismo que sumar "no sabemos". Afecta "Financiamiento total", promedios y medianas por ronda, y la regresión de ciclos de mercado. El número exacto (6,000) es muy redondo, conviene anotarlo en limitaciones | Noel |

| 6 | acquisitions | Perfilado de Olga: `acquired\_object\_id` con 1 nulo; `acquired\_at` con 29 nulos; `term\_code` con 7,656 nulos de 9,562 (80%) | 9,562 | Pendiente | Pendiente en clean | Un nulo en una FK debe entrar al check de FK; `term\_code` ya lo advierte el diccionario ("muchas filas no la reportan") | Olga |

| 7 | funding\_rounds.funded\_at | Perfilado de Olga: 248 nulos de 52,928 | 52,928 | Pendiente | Pendiente en clean | Las rondas sin fecha no se pueden ubicar en cohortes ni en la serie mensual de la regresión | Olga |

| 8 | funding\_rounds (raised\_amount, raised\_amount\_usd, pre\_money\_valuation\_usd, post\_money\_valuation\_usd) | Ceros en montos (verificado en raw): raised\_amount 5,638 (10.7%); pre\_money\_valuation\_usd 52,897 (99.94%); post\_money\_valuation\_usd 51,734 (97.7%). Además, 362 rondas (0.68%) tienen monto original > 0 y raised\_amount\_usd = 0, todas en moneda distinta de USD: EUR 216, GBP 68, CAD 54, JPY 12, SEK 6, AUD 3, NIS 3 | 52,928 | Pendiente | Pendiente en clean: ceros a NULL en valoraciones; para las 362 rondas, propuesta: dejar el monto USD como NULL (desconocido) y documentar | Solo 31 rondas con valoración pre-money y 1,194 con post-money: no son utilizables para análisis y probablemente no deban publicarse en marts (límite de Neon). Las 362 rondas son una conversión a USD que no se hizo; recuperarlas exigiría tipos de cambio externos, y el efecto (0.68%) es pequeño | Noel |

