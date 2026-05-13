# UX Context

Usar este contexto cuando el agente tenga que analizar fricciones, ambigüedades del flujo, carga cognitiva o diferencias entre el comportamiento técnico y la percepción del usuario.

## Objetivo

- detectar fricción real sin simplificar mal la lógica del producto
- separar bug de comportamiento esperado con mala explicabilidad
- encontrar puntos donde copy, timing o estado generan confusión
- conectar flows con edge cases para priorización UX

## Orden de lectura recomendado

1. `00_Index/synonyms.md`
2. `02_Flows/payment-instructions`
3. `02_Flows/chat-state-chips-and-support-actions`
4. `02_Flows/create-transaction-and-next-step`
5. `02_Flows/cancellation-held-mediation-recovery`
6. `06_Edge_Cases/`

## Fricciones típicas a observar

- acciones que parecen neutras y no lo son
- estados válidos que parecen error o abandono
- interfaces visibles pero no habilitadas
- rutas públicas que conservan contexto sin que el usuario lo entienda
- ramas por sistema que rompen expectativas de consistencia

## Flujos a priorizar según el tema

- comprensión del pago: `payment-instructions`
- UX guiada vs chat libre: `chat-state-chips-and-support-actions`
- pedido que no encuentra salida ideal: `create-transaction-and-next-step`
- desvíos, hold, disputa, mediación: `cancellation-held-mediation-recovery`
- onboarding sin login: `public-order-creation-and-identity-bootstrap`
- entry points públicos: `landing-for-systems-and-marketing-preloads`

## Edge cases que conviene revisar temprano

- `instructions-read-side-effects`
- `chat-visible-but-locked`
- `stale-public-quote-session`
- `to-future-ready-looks-stalled`
- `simultaneous-orders-omitted`
- `pix-key-late-held`

## Errores comunes que el agente debe evitar

- no medir UX solo por el estado técnico
- no asumir que dos pedidos con el mismo estado se sienten igual
- no tratar como bug cualquier fricción; muchas nacen de lógica operativa real
- no olvidar contexto público vs dashboard

## Estilo de respuesta recomendado

- nombrar la fricción desde la percepción del usuario
- luego explicar qué regla del sistema la produce
- cerrar con hipótesis UX accionable si corresponde

