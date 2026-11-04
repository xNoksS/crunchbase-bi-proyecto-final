# Diagrama del modelo dimensional (esquema `marts`)

```mermaid
erDiagram
    dim_empresa ||--o{ fact_rondas : "levanta"
    dim_empresa ||--o{ fact_adquisiciones : "es adquirida"
    dim_empresa ||--o{ fact_adquisiciones : "adquiere"
    dim_empresa ||--o{ fact_ipos : "sale a bolsa"
    dim_fecha ||--o{ fact_rondas : "fecha"
    dim_fecha ||--o{ fact_adquisiciones : "fecha"
    dim_fecha ||--o{ fact_ipos : "fecha"
    fact_rondas ||--|{ puente_ronda_inversionista : "tiene"
    dim_inversionista ||--|{ puente_ronda_inversionista : "participa"
    serie_externa_mensual ||--o{ dim_fecha : "anio_mes"

    dim_empresa {
        varchar empresa_id PK
        varchar nombre
        varchar industria
        varchar pais
        varchar estatus
        bigint anio_fundacion
        bigint anio_primera_ronda
        varchar etapa
        boolean es_registro_faltante
    }
    dim_inversionista {
        varchar inversionista_id PK
        varchar nombre
        varchar tipo_inversionista
        varchar pais
        boolean es_registro_faltante
    }
    dim_fecha {
        date fecha PK
        smallint anio
        smallint trimestre
        smallint mes
        date anio_mes
    }
    fact_rondas {
        int ronda_id PK
        varchar empresa_id FK
        date fecha FK
        varchar tipo_ronda
        decimal monto_usd
        bigint n_inversionistas
    }
    puente_ronda_inversionista {
        int ronda_id PK,FK
        varchar inversionista_id PK,FK
        double peso
    }
    fact_adquisiciones {
        int adquisicion_id PK
        varchar empresa_adquirida_id FK
        varchar empresa_adquirente_id FK
        date fecha FK
        decimal precio_usd
    }
    fact_ipos {
        int ipo_id PK
        varchar empresa_id FK
        date fecha FK
    }
    serie_externa_mensual {
        date anio_mes PK
        double nasdaqcom
        double fedfunds
        double unrate
    }
```

Granos: `fact_rondas` = una ronda · `fact_adquisiciones` = una adquisición ·
`fact_ipos` = una IPO · `puente_ronda_inversionista` = un par (ronda, inversionista) ·
`serie_externa_mensual` = un mes.
El monto solo vive en `fact_rondas`; el puente reparte con `peso`.
Detalle de columnas en `diccionario_modelo.md`.
