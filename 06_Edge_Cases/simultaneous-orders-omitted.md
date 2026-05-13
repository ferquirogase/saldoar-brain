# Simultaneous Orders Omitted

## Tipo

Comportamiento esperado con friccion UX.

## Contexto

Un usuario crea dos o mas pedidos muy cerca en el tiempo y despues percibe que uno “desaparecio”, quedo omitido o salto a otro estado que no coincide con la expectativa inicial.

## Condicion disparadora

- el usuario acumula varios pedidos en ventana corta
- hay transacciones del mismo usuario en `WAITING_PAYMENT`
- una parte de la logica prioriza pedidos con `instructions_read_at`
- el umbral no es fijo para todos: depende de `max(2, user.level + 1)`

## Comportamiento observado

- un pedido puede seguir vivo y otro quedar relegado
- pedidos no leidos pueden perder `directTransfers1`
- el pedido desplazado puede pasar a `TO_NEW_TICKET`
- el usuario puede interpretarlo como bug o desaparicion, aunque backend lo trate como control de concurrencia

## Impacto

- confusion fuerte en soporte
- percepcion de inestabilidad o “pedido omitido”
- riesgo de que el usuario pague sobre el pedido equivocado o no entienda cual sigue activo

## Clasificacion

Esperado desde logica operativa, pero con friccion UX alta.

## Lo importante para decidir

- no es solo un problema de instrucciones
- `instructions_read_at` pesa para decidir cual pedido conserva prioridad
- el copy visible puede simplificar demasiado una regla que en backend depende del nivel del usuario

## Flujos relacionados

- `02_Flows/concurrent-orders-and-omitted-transactions`
- `02_Flows/payment-instructions`
- `02_Flows/chat-state-chips-and-support-actions`

## Preguntas que ayuda a responder

- “¿por que un pedido desaparecio cuando hice dos al mismo tiempo?”
- “¿por que me mando a otro ticket si cree varios pedidos?”
- “¿por que uno de mis pedidos quedo omitido?”

## Fuentes

- `saldo/app/Transactions/Jobs/EvaluatorPipes/OnlyOneTransactionWaitingPayment.php`
- `saldo/app/Transactions/Jobs/CancelMultipleWaitingPaymentTransactions.php`
- `saldo/app/Transactions/TransactionHelpers/HelperRepositories/OmittedOrdersHelperRepository.php`
