# Instructions Read Side Effects

## Tipo

Comportamiento esperado poco visible.

## Contexto

El usuario entra a instrucciones y asume que solo esta leyendo el paso a paso, pero backend empieza a registrar actividad operativa a partir de esa lectura.

## Condicion disparadora

- se abre la pantalla de instrucciones
- o se consultan `direct_transfers1` en un pedido `WAITING_PAYMENT`
- `instructions_read_at` todavia es `null`

## Comportamiento observado

- backend marca `instructions_read_at`
- se guarda un state interno no visible para el usuario
- se agenda un job de seguimiento tipo `visited but didn't pay`
- esa lectura despues influye en otras reglas, como proteccion de pedidos concurrentes o ventanas de cancelacion

## Impacto

- el usuario cree que “solo miro”, pero el sistema ya interpreta intencion operativa
- soporte puede subestimar el peso funcional de abrir instrucciones
- analisis de producto o marketing puede leer esta señal como algo mas fuerte que una simple vista

## Clasificacion

Esperado, pero muy poco obvio desde la UX.

## Lo importante para decidir

- leer instrucciones no es un gesto neutro
- este caso conecta pagos, reminders, concurrencia y timing de cancelacion
- conviene evitar explicaciones internas que traten `instructions_read_at` como metrica pasiva

## Flujos relacionados

- `02_Flows/payment-instructions`
- `02_Flows/notifications-mails-and-background-jobs`
- `02_Flows/concurrent-orders-and-omitted-transactions`

## Preguntas que ayuda a responder

- “¿por que me empiezan a seguir si solo abri instrucciones?”
- “¿que pasa cuando el usuario entra a instrucciones?”
- “¿por que leer instrucciones cambia el tratamiento del pedido?”

## Fuentes

- `saldo/app/Transactions/Transactions/UseCases/MarkInstructionsReadUseCase.php`
- `saldo/app/Transactions/Http/TransactionPixelController.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransfer1Policy.php`

