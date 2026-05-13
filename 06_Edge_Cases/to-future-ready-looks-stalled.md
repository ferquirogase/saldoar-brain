# To Future Ready Looks Stalled

## Tipo

Estado valido con apariencia de bloqueo.

## Contexto

El pedido no avanza a `WAITING_PAYMENT` ni a `CREDITED_PAYMENT`, y para el usuario parece trabado o abandonado. En realidad backend lo dejo en `TO_FUTURE_READY`.

## Condicion disparadora

- no se encuentran destinos disponibles
- no cierra el matching esperado
- una accion de recovery o next step no logra dejar el pedido listo
- backend todavia ve una salida accionable y no cancela del todo

## Comportamiento observado

- el flujo se siente frenado
- puede abrirse chat o helpers con salida sugerida
- el pedido no esta muerto, pero tampoco sigue el camino ideal

## Impacto

- soporte o UX pueden llamarlo “pedido trabado”
- el usuario no siempre entiende que todavia hay camino de recovery
- si el copy falla, parece inaccion del sistema

## Clasificacion

Comportamiento esperado con alto riesgo de mala interpretacion.

## Lo importante para decidir

- `TO_FUTURE_READY` no es un error tecnico puro
- muchas veces es una pausa operativa con salida potencial
- necesita mucho apoyo de helpers, chat o copy para no parecer abandono

## Flujos relacionados

- `02_Flows/create-transaction-and-next-step`
- `02_Flows/chat-state-chips-and-support-actions`
- `02_Flows/cancellation-held-mediation-recovery`
- `02_Flows/operator-interventions-and-panel-actions`

## Preguntas que ayuda a responder

- “¿por que el pedido quedo frenado pero no cancelado?”
- “¿que significa to future ready?”
- “¿por que parece trabado si todavia existe?”

## Fuentes

- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- `saldo/app/Transactions/Transactions/TransactionHelper.php`
- `saldo/app/Transactions/StateChips/StateChatService.php`
