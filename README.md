# Crunchbase: financiamiento de startups (BI Proyecto Final 2026)

Equipo de BI de un fondo de venture capital. Entrega: jueves 5 de noviembre de 2026, 11:59 PM.

## Equipo y roles

| Persona | Rol |
|---|---|
| Noel | Líder + Ingeniería de datos |
| Olga | Calidad de datos y documentación |
| Cristina | Modelado de datos |
| Ximena | Analista de inversionistas |
| Hugo | Analista de startups e industrias |
| Jose | BI y storytelling |

## Cómo reconstruir todo desde cero

1. `python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt`
2. Colocar los CSV originales de Crunchbase en `data/raw/` (no se suben al repo).
3. `python run_all.py` ejecuta raw → staging → clean → marts y luego los checks.
4. Copiar `.env.example` a `.env`, llenar TU rol de Neon y correr `python publish/publish_to_neon.py`.

## Estructura

- `sql/01_raw` … `sql/04_marts`: una transformación por archivo, ejecutadas en orden.
- `checks/`: checks automatizados (fallan si hay PK duplicadas, FK huérfanas, etc.).
- `docs/`: bitácora de calidad, decisiones, diccionario del modelo y de métricas.
- `notebooks/`: análisis (curvas de salida, sensibilidad de inversionistas, ciclos de mercado).
- `dashboard/`: archivo del dashboard y capturas.

## Flujo de trabajo

- Una rama por tarea (`rol/tarea`, p. ej. `olga/checks-fk`) y pull request.
- Nada llega a `main` sin revisión de otra persona.
- Credenciales solo en `.env` (ignorado por Git). Si se expone una, se rota de inmediato.

## Uso de herramientas de IA

<!-- Declarar brevemente para qué y con qué herramienta (requisito de entrega). -->
