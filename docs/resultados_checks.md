# Resultados de checks automatizados

Corrida: 2026-11-01 18:54 | modo: normal | resultado: **FALLA**

| Check | Estado | Detalle |
|---|---|---|
| PK objects.id | OK | capa=clean, filas=463927, nulas=0, repetidas=0 |
| PK funding_rounds.funding_round_id | OK | capa=clean, filas=52928, nulas=0, repetidas=0 |
| PK investments.id | OK | capa=clean, filas=80902, nulas=0, repetidas=0 |
| PK acquisitions.acquisition_id | OK | capa=clean, filas=9561, nulas=0, repetidas=0 |
| PK ipos.ipo_id | OK | capa=clean, filas=1254, nulas=0, repetidas=0 |
| PK funds.fund_id | OK | capa=clean, filas=1564, nulas=0, repetidas=0 |
| PK people.object_id | OK | capa=staging, filas=226709, nulas=0, repetidas=0 |
| PK degrees.id | OK | capa=staging, filas=109610, nulas=0, repetidas=0 |
| PK relationships.relationship_id | OK | capa=staging, filas=402878, nulas=0, repetidas=0 |
| PK milestones.id | OK | capa=staging, filas=39456, nulas=0, repetidas=0 |
| PK offices.office_id | OK | capa=staging, filas=112718, nulas=0, repetidas=0 |
| FK objects.parent_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=436212 |
| FK funding_rounds.object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK investments.funding_round_id -> funding_rounds.funding_round_id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK investments.funded_object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK investments.investor_object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK acquisitions.acquiring_object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK acquisitions.acquired_object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK ipos.object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK funds.object_id -> objects.id | OK | hijo=clean, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK people.object_id -> objects.id | OK | hijo=staging, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK degrees.object_id -> people.object_id | AVISO | hijo=staging, padre=staging, huerfanos=554 (llaves=380), FK nulas=0 | la tabla hija aun no tiene capa clean |
| FK relationships.person_object_id -> people.object_id | AVISO | hijo=staging, padre=staging, huerfanos=920 (llaves=752), FK nulas=0 | la tabla hija aun no tiene capa clean |
| FK relationships.relationship_object_id -> objects.id | AVISO | hijo=staging, padre=clean, huerfanos=380 (llaves=285), FK nulas=0 | la tabla hija aun no tiene capa clean |
| FK milestones.object_id -> objects.id | OK | hijo=staging, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| FK offices.object_id -> objects.id | OK | hijo=staging, padre=clean, huerfanos=0 (llaves=0), FK nulas=0 |
| Filas objects | OK | raw=462651, staging=462651, clean=463927, esperado=463927 (+1276 registros de reemplazo (bitacora fila 9)) |
| Filas funding_rounds | OK | raw=52928, staging=52928, clean=52928, esperado=52928 (sin cambios) |
| Filas investments | OK | raw=80902, staging=80902, clean=80902, esperado=80902 (sin cambios) |
| Filas acquisitions | OK | raw=9562, staging=9562, clean=9561, esperado=9561 (-1 filas segun bitacora) |
| Filas ipos | OK | raw=1259, staging=1259, clean=1254, esperado=1254 (-5 filas segun bitacora) |
| Filas funds | OK | raw=1564, staging=1564, clean=1564, esperado=1564 (sin cambios) |
| Filas people | AVISO | raw=226709, staging=226709; sin capa clean todavia |
| Filas degrees | AVISO | raw=109610, staging=109610; sin capa clean todavia |
| Filas relationships | AVISO | raw=402878, staging=402878; sin capa clean todavia |
| Filas milestones | AVISO | raw=39456, staging=39456; sin capa clean todavia |
| Filas offices | AVISO | raw=112718, staging=112718; sin capa clean todavia |
| Monto negativo objects.funding_total_usd | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.raised_amount_usd | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.raised_amount | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.pre_money_valuation_usd | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.pre_money_valuation | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.post_money_valuation_usd | OK | capa=clean, negativos=0 |
| Monto negativo funding_rounds.post_money_valuation | OK | capa=clean, negativos=0 |
| Monto negativo acquisitions.price_amount | OK | capa=clean, negativos=0 |
| Monto negativo acquisitions.price_amount_usd | OK | capa=clean, negativos=0 |
| Monto negativo ipos.valuation_amount | OK | capa=clean, negativos=0 |
| Monto negativo ipos.raised_amount | OK | capa=clean, negativos=0 |
| Monto negativo ipos.valuation_amount_usd | OK | capa=clean, negativos=0 |
| Monto negativo ipos.raised_amount_usd | OK | capa=clean, negativos=0 |
| Monto negativo funds.raised_amount | OK | capa=clean, negativos=0 |
| Monto negativo funds.raised_amount_usd | OK | capa=clean, negativos=0 |
| Fecha fuera de rango objects.founded_at | FALLA | capa=clean, fuera de [1800-01-01, 2013-12-31]=22 |
| Fecha fuera de rango objects.closed_at | FALLA | capa=clean, fuera de [1800-01-01, 2013-12-31]=5 |
| Fecha fuera de rango objects.first_investment_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango objects.last_investment_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango objects.first_funding_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango objects.last_funding_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango objects.first_milestone_at | FALLA | capa=clean, fuera de [1800-01-01, 2013-12-31]=57 |
| Fecha fuera de rango objects.last_milestone_at | FALLA | capa=clean, fuera de [1800-01-01, 2013-12-31]=87 |
| Fecha fuera de rango funding_rounds.funded_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango acquisitions.acquired_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango ipos.public_at | OK | capa=clean, fuera de [1800-01-01, 2013-12-31]=0 |
| Fecha fuera de rango funds.funded_at | FALLA | capa=clean, fuera de [1800-01-01, 2013-12-31]=1 |
| Fecha fuera de rango degrees.graduated_at | AVISO | capa=staging, fuera de [1800-01-01, 2013-12-31]=1 |
| Fecha fuera de rango relationships.start_at | AVISO | capa=staging, fuera de [1800-01-01, 2013-12-31]=31 |
| Fecha fuera de rango relationships.end_at | AVISO | capa=staging, fuera de [1800-01-01, 2013-12-31]=65 |
| Fecha fuera de rango milestones.milestone_at | AVISO | capa=staging, fuera de [1800-01-01, 2013-12-31]=59 |
| Evento anterior a fundacion funding_rounds.funded_at | FALLA | capa=clean, filas con evento < founded_at=1824 |
| Evento anterior a fundacion acquisitions.acquired_at | FALLA | capa=clean, filas con evento < founded_at=26 |
| Evento anterior a fundacion ipos.public_at | FALLA | capa=clean, filas con evento < founded_at=14 |
