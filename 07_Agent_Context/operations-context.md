# Operations Context

Usar este contexto cuando el agente tenga que responder sobre tareas, panel, intervención manual, estados de revisión o recovery interno.

## Objetivo

- entender qué puede hacer operación y qué impacto visible tiene
- separar automatismo, task y acción manual
- leer bien estados recuperables, retenidos o en mediación
- ubicar cuándo el sistema dejó de ser solo self-service

## Orden de lectura recomendado

1. `00_Index/synonyms.md`
2. `01_Domains/support-and-operations`
3. `02_Flows/operator-interventions-and-panel-actions`
4. `02_Flows/cancellation-held-mediation-recovery`
5. `02_Flows/chat-state-chips-and-support-actions`
6. `03_Entities/task`
7. `06_Edge_Cases/`

## Preguntas que este contexto cubre bien

- “¿qué puede hacer un operador sobre el pedido?”
- “¿por qué una respuesta de panel cambió la experiencia visible?”
- “¿cuándo un pedido todavía es recuperable?”
- “¿qué abre chat y qué crea tarea?”

## Flujos a priorizar según el tema

- catálogo de acciones manuales: `operator-interventions-and-panel-actions`
- estados desviados y recovery: `cancellation-held-mediation-recovery`
- chips, chat y escalado: `chat-state-chips-and-support-actions`
- jobs y notificaciones: `notifications-mails-and-background-jobs`

## Edge cases que conviene revisar temprano

- `chat-visible-but-locked`
- `held-disputed-without-screenshots`
- `to-future-ready-looks-stalled`
- `simultaneous-orders-omitted`

## Errores comunes que el agente debe evitar

- no asumir que todo cambio visible viene de una acción del usuario
- no tratar `task`, `state` y `chat` como la misma cosa
- no olvidar que algunas acciones operativas pueden dejar el pedido en un estado peor o ambiguo

## Estilo de respuesta recomendado

- ubicar primero si el caso parece automático, escalado o manual
- después explicar la acción o estado resultante
- si aplica, mencionar qué parte es visible al usuario y cuál queda interna
