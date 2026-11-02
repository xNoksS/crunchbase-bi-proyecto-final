\# Diagrama del modelo dimensional (esquema `marts`)



```mermaid

erDiagram

&#x20;   dim\_empresa ||--o{ fact\_rondas : "levanta"

&#x20;   dim\_empresa ||--o{ fact\_adquisiciones : "es adquirida"

&#x20;   dim\_empresa ||--o{ fact\_adquisiciones : "adquiere"

&#x20;   dim\_empresa ||--o{ fact\_ipos : "sale a bolsa"

&#x20;   dim\_fecha ||--o{ fact\_rondas : "fecha"

&#x20;   dim\_fecha ||--o{ fact\_adquisiciones : "fecha"

&#x20;   dim\_fecha ||--o{ fact\_ipos : "fecha"

&#x20;   fact\_rondas ||--|{ puente\_ronda\_inversionista : "tiene"

&#x20;   dim\_inversionista ||--|{ puente\_ronda\_inversionista : "participa"



&#x20;   dim\_empresa {

&#x20;       varchar empresa\_id PK

&#x20;       varchar nombre

&#x20;       varchar industria

&#x20;       varchar pais

&#x20;       varchar estatus

&#x20;       bigint anio\_fundacion

&#x20;       bigint anio\_primera\_ronda

&#x20;       varchar etapa

&#x20;       boolean es\_registro\_faltante

&#x20;   }

&#x20;   dim\_inversionista {

&#x20;       varchar inversionista\_id PK

&#x20;       varchar nombre

&#x20;       varchar tipo\_inversionista

&#x20;       varchar pais

&#x20;       boolean es\_registro\_faltante

&#x20;   }

&#x20;   dim\_fecha {

&#x20;       date fecha PK

&#x20;       smallint anio

&#x20;       smallint trimestre

&#x20;       smallint mes

&#x20;       date anio\_mes

&#x20;   }

&#x20;   fact\_rondas {

&#x20;       int ronda\_id PK

&#x20;       varchar empresa\_id FK

&#x20;       date fecha FK

&#x20;       varchar tipo\_ronda

&#x20;       decimal monto\_usd

&#x20;       bigint n\_inversionistas

&#x20;   }

&#x20;   puente\_ronda\_inversionista {

&#x20;       int ronda\_id PK,FK

&#x20;       varchar inversionista\_id PK,FK

&#x20;       double peso

&#x20;   }

&#x20;   fact\_adquisiciones {

&#x20;       int adquisicion\_id PK

&#x20;       varchar empresa\_adquirida\_id FK

&#x20;       varchar empresa\_adquirente\_id FK

&#x20;       date fecha FK

&#x20;       decimal precio\_usd

&#x20;   }

&#x20;   fact\_ipos {

&#x20;       int ipo\_id PK

&#x20;       varchar empresa\_id FK

&#x20;       date fecha FK

&#x20;   }

```



Granos: `fact\_rondas` = una ronda · `fact\_adquisiciones` = una adquisición ·

`fact\_ipos` = una IPO · `puente\_ronda\_inversionista` = un par (ronda, inversionista).

El monto solo vive en `fact\_rondas`; el puente reparte con `peso`.

Detalle de columnas en `diccionario\_modelo.md`.

