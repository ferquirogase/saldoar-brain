# Product Context

Usar este contexto cuando el agente tenga que explicar reglas de negocio, diferencias entre caminos del producto o tradeoffs del sistema.

## Objetivo

- leer el comportamiento como producto, no solo como código
- distinguir core path de ramas y recovery
- identificar qué decisiones parecen deliberadas y cuáles parecen deuda
- entender límites de promesa según contexto y sistema

## Orden de lectura recomendado

1. `00_Index/synonyms.md`
2. `01_Domains/transactions`
3. `02_Flows/create-transaction-and-next-step`
4. `02_Flows/system-specific-branches`
5. `02_Flows/public-order-creation-and-identity-bootstrap`
6. `02_Flows/operator-interventions-and-panel-actions`
7. `06_Edge_Cases/`

## Preguntas que este contexto cubre bien

- “¿qué decide el próximo paso del pedido?”
- “¿qué cambia entre contexto público y dashboard?”
- “¿por qué ciertos sistemas se comportan distinto?”
- “¿qué parte es recovery y qué parte es desvío estructural?”
- “¿cuándo una intervención manual cambia la experiencia?”

## Flujos a priorizar según el tema

- core post-creación: `create-transaction-and-next-step`
- ramas por método: `system-specific-branches`
- identidad y acceso: `public-order-creation-and-identity-bootstrap`
- operación manual: `operator-interventions-and-panel-actions`
- estados no ideales: `cancellation-held-mediation-recovery`
- deals y restricciones: `deals-and-direct-transfer-matching`

## Edge cases que conviene revisar temprano

- `instructions-read-side-effects`
- `legacy-system-links-and-replacements`
- `held-disputed-without-screenshots`
- `to-future-ready-looks-stalled`

## Errores comunes que el agente debe evitar

- no tratar ramas de sistema como variaciones cosméticas
- no mezclar acceso por key con autenticación clásica
- no asumir que recovery significa bug
- no ignorar intervención operativa cuando explica el comportamiento final

## Estilo de respuesta recomendado

- explicar la regla de negocio primero
- luego ubicar en qué flow, dominio o edge case aparece
- separar lo confirmado de lo inferido

