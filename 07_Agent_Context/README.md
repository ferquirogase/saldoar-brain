# Agent Context

Esta carpeta guarda contexto ya preparado para agentes.

Usos:

- prompt base por area
- resumen de dominios
- lista de flujos prioritarios
- glosario
- preguntas frecuentes canonicas

Principio:

- no duplicar conocimiento si ya existe en `02_Flows/` o `01_Domains/`
- resumir y referenciar

## Contextos disponibles

- `saldoar-brain-bootstrap.md`
  Bootstrap general para cualquier agente que necesite entender Saldoar.

- `support-context.md`
  Prioriza lectura operativa, estados, recuperación, instrucciones y edge cases de atención.

- `marketing-context.md`
  Prioriza landings, acquisition, replacement systems, copy visible y límites de promesa.

- `ux-context.md`
  Prioriza fricciones, estados ambiguos, ayudas contextuales, onboarding público y casuística.

- `product-context.md`
  Prioriza reglas de negocio, diferencias entre contextos, branches por sistema y tradeoffs.

- `operations-context.md`
  Prioriza panel, tareas, intervención manual, recovery y estados no ideales.

## Cómo conviene usarlos

- Inyectar primero `saldoar-brain-bootstrap.md`.
- Después sumar solo el contexto del área que corresponda.
- Si la pregunta es muy puntual, abrir además el flow o edge case sugerido por ese contexto.
