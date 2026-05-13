# Support Context

Usar este contexto cuando el agente tenga que responder dudas de soporte, explicar comportamientos del pedido o ayudar a distinguir bug real de comportamiento esperado.

## Objetivo

- traducir lógica técnica a lenguaje operativo
- explicar qué está pasando ahora en el pedido
- evitar promesas incorrectas
- distinguir entre pedido cancelado, retenido, omitido, en disputa o recuperable

## Orden de lectura recomendado

1. `00_Index/synonyms.md`
2. `02_Flows/transaction-visibility-and-status`
3. `02_Flows/payment-instructions`
4. `02_Flows/chat-state-chips-and-support-actions`
5. `02_Flows/cancellation-held-mediation-recovery`
6. `06_Edge_Cases/`

## Preguntas que este contexto cubre bien

- “¿por qué no avanza mi pedido?”
- “¿por qué no puedo escribir en el chat?”
- “¿por qué me pidió esto ahora?”
- “¿por qué desapareció uno de mis pedidos?”
- “¿qué significa HELD, HELD_DISPUTED o TO_FUTURE_READY?”

## Flujos a priorizar según el tema

- estado, visibilidad o acceso: `transaction-visibility-and-status`
- qué hacer para pagar: `payment-instructions`
- ayuda contextual, chips, chat: `chat-state-chips-and-support-actions`
- pedido retenido, cancelado, disputado: `cancellation-held-mediation-recovery`
- pedidos simultáneos: `concurrent-orders-and-omitted-transactions`
- cuentas, destinos, PIX: `accounts-and-destination-selection`

## Edge cases que conviene revisar temprano

- `simultaneous-orders-omitted`
- `chat-visible-but-locked`
- `instructions-read-side-effects`
- `held-disputed-without-screenshots`
- `to-future-ready-looks-stalled`

## Errores comunes que el agente debe evitar

- no asumir que ver el chat significa poder escribir
- no tratar `TO_FUTURE_READY` como cancelación
- no tratar `HELD` y `HELD_DISPUTED` como sinónimos
- no asumir que una acción del usuario fue neutra; abrir instrucciones puede disparar efectos
- no mezclar contexto público `/t` con dashboard `/my`

## Estilo de respuesta recomendado

- explicar primero qué comportamiento parece estar ocurriendo
- después aclarar si es esperado, ambiguo o sospechoso
- cerrar con el flujo o edge case que respalda la explicación

