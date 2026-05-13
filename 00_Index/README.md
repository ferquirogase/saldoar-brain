# Index

## Como leer este brain

- Empeza por `02_Flows/` si queres entender comportamiento end-to-end.
- Anda a `01_Domains/` si queres ubicar ownership funcional y tecnico.
- Usa `05_FAQ_By_Area/` para respuestas orientadas a soporte o marketing.
- Usa `07_Agent_Context/` para pasar contexto resumido a agentes.

## Reglas de documentacion

- Un flujo = una carpeta.
- Cada flujo importante debe tener:
  - `README.md`
  - `flow.yaml`
- Cada documento debe incluir:
  - objetivo
  - alcance
  - entry points
  - trazabilidad tecnica
  - riesgos / unknowns
  - fuentes

## Naming

- slugs en kebab-case
- ids canonicos tipo `flow-*`, `domain-*`, `entity-*`, `integration-*`

## Nivel de evidencia

- `confirmed`: visto en codigo o artefacto fuente
- `inferred`: inferido a partir de codigo, naming o wiring
- `unknown`: falta validar
