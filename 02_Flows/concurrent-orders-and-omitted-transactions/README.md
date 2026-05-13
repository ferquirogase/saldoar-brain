# Concurrent Orders And Omitted Transactions

## Metadata

- `flow_id`: `flow-concurrent-orders-and-omitted-transactions`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar por que, cuando un usuario crea varios pedidos casi al mismo tiempo, uno puede quedar omitido o saltar a `TO_NEW_TICKET`, y como intervienen `instructions_read_at`, `WAITING_PAYMENT` y los `direct_transfers`.

## Por que importa

Este flujo responde una duda muy frecuente y confusa:

- "cree dos pedidos y uno desaparecio"
- "por que el sistema sigue con el ultimo pedido"
- "por que me saco destinos"
- "por que un pedido quedo omitido"

No es solo una casuistica de UI.
Es una regla operativa del motor de transacciones.

## Problema que resuelve el sistema

Saldoar intenta evitar que un mismo usuario sostenga multiples pedidos activos compitiendo por el mismo momento operativo, especialmente en `WAITING_PAYMENT`.

Para eso:

- limita la cantidad de operaciones pendientes por usuario
- prioriza el ultimo pedido activo/relevante
- omite pedidos no leidos o no concluidos
- remueve `direct_transfers` de pedidos desplazados

## Punto clave

Esta logica no vive solo en instrucciones.

Cruza:

- transicion de estado de la transaccion
- lectura de instrucciones
- evaluacion de riesgo / siguiente paso
- limpieza de `direct_transfers`
- helpers UX

## Flujo general

### 1. La transaccion intenta avanzar

En `TransactionNextStepUseCase`, antes de pasar a `WAITING_PAYMENT`, se corre `OnlyOneTransactionWaitingPayment` dentro de las `pre_pipes`.

### 2. Se cuentan pedidos del usuario en `WAITING_PAYMENT`

`OnlyOneTransactionWaitingPayment` cuenta transacciones del mismo usuario que:

- estan en `WAITING_PAYMENT`
- tienen `instructions_read_at` no nulo

Tambien define un maximo:

- `max(2, user.level + 1)`

Si se supera ese umbral, corta el avance con `PipeException`.

### 3. Cuando una transaccion entra en `WAITING_PAYMENT`, se dispara limpieza

`TransactionStateChangedDebouncedEventDispatcher` escucha el cambio de estado y, si la transaccion entro a `WAITING_PAYMENT`, ejecuta `CancelMultipleWaitingPaymentTransactions`.

### 4. Se prioriza el pedido mas reciente/leido

`CancelMultipleWaitingPaymentTransactions` busca transacciones del usuario en `WAITING_PAYMENT` y las ordena por:

- `instructions_read_at` descendente
- `id` descendente

El primer pedido de esa lista se conserva como referencia principal.

### 5. Los otros pedidos no leidos pueden quedar omitidos

Para las otras transacciones:

- si `instructions_read_at !== null`, se las deja pasar
- si estan lockeadas, se requeuea
- si no fueron leidas, se borran sus `directTransfers1` con comportamiento `REMOVED_UNREAD`
- luego el pedido pasa a estado `TO_NEW_TICKET`

Ademas se setea un texto publico:

- `Seguimos en el ultimo pedido que creaste: {mid}`

## Relacion con `instructions_read_at`

Esta variable es clave porque diferencia entre:

- pedido ya leido/activado por el usuario
- pedido aun no leido / descartable

Eso conecta este flujo directamente con `payment-instructions`, donde `instructions_read_at` se dispara cuando el usuario realmente entra en instrucciones o toca recursos asociados.

## `direct_transfer` y comportamientos omitidos

Cuando un pedido es desplazado o limpiado, los `direct_transfers` pueden marcarse como:

- `REMOVED_UNREAD`
- `REMOVED_READ`

Backend usa esto en distintos servicios:

- `DeleteDirectTransfersService`
- `CancelMultipleWaitingPaymentTransactions`
- handlers de recuperacion o limpieza

En front, los comportamientos removidos tambien afectan lo que se muestra en instrucciones.

## Estados relevantes

- `TO_NEW_TICKET = 3`
- `TO_FUTURE = 5`
- `TO_FUTURE_READY = 6`
- `WAITING_PAYMENT = 11`

`TO_NEW_TICKET` en la practica funciona como pedido omitido / saltado / ya no prioritario.

## UX visible

### Helper especifico

Cuando el pedido queda en `TO_NEW_TICKET`, `HelpersContainerRepository` usa `OmittedOrdersHelperRepository`.

El mensaje actual en `resources/lang/es/transaction_helpers.php` dice:

- el pedido fue omitido porque ya hay dos pedidos pendientes o porque un operador lo gestiono manualmente
- antes de crear uno nuevo, contactar por chat

### Mensajes publicos

Tambien hay copy publico en acciones de `direct_transfer` que explican que el pedido fue omitido para poder seguir tomando ofertas.

## Trazabilidad Tecnica

### Back

- siguiente paso de transaccion: `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- limite por pedidos waiting payment: `saldo/app/Transactions/Jobs/EvaluatorPipes/OnlyOneTransactionWaitingPayment.php`
- limpieza de multiples waiting payment: `saldo/app/Transactions/Jobs/CancelMultipleWaitingPaymentTransactions.php`
- dispatcher al cambiar estado: `saldo/app/Transactions/Events/TransactionStateChangedDebouncedEventDispatcher.php`
- helper UX de omitido: `saldo/app/Transactions/TransactionHelpers/HelperRepositories/OmittedOrdersHelperRepository.php`
- contenedor de helpers por estado: `saldo/app/Transactions/TransactionHelpers/Containers/HelpersContainerRepository.php`
- comportamientos de direct transfer: `saldo/app/Transactions/DirectTransfers/BehaviourEnum.php`
- enumeracion de estados: `saldo/app/Transactions/States/StateEnum.php`
- borrado con comportamiento read/unread: `saldo/app/Transactions/DirectTransfers/Support/DeleteDirectTransfersService.php`
- ventana temporal para cancel/held: `saldo/app/Transactions/Commands/Pipes/TransactionReadyForCancelOrHeld.php`

## Reglas de Negocio Detectadas

### El sistema no trata igual todos los pedidos simultaneos

No hace una cancelacion ciega.
Prioriza segun:

- si el usuario ya leyo instrucciones
- cual fue el ultimo pedido activo

### Leer instrucciones protege un pedido

Un pedido con `instructions_read_at` tiene mas peso para seguir vivo que uno no leido.

### El "omitido" no siempre es error

Puede ser comportamiento esperado del sistema para evitar dos pedidos paralelos conflictivos.

### El limite no es exactamente "solo uno"

`OnlyOneTransactionWaitingPayment` usa `max(2, user.level + 1)`.
O sea, la logica es mas flexible que "siempre una sola operacion".

### `TO_NEW_TICKET` no es simplemente cancelado

Es un estado funcional distinto, con helper y copy propios.

## Lo que este flujo ya permite responder

- Por que un pedido puede quedar omitido si se crean dos casi a la vez.
- Que rol juega `instructions_read_at`.
- Por que el sistema "sigue con el ultimo pedido".
- Por que desaparecen destinos de un pedido desplazado.
- Donde se implementa el limite de pedidos en `WAITING_PAYMENT`.
- Por que esta casuistica no pertenece solo a instrucciones.

## Edge Cases / Riesgos

- La explicacion UX actual dice "dos pedidos pendientes", pero la regla tecnica usa `max(2, level + 1)`; puede haber desalineacion entre copy y comportamiento real segun nivel.
- Un usuario puede percibir "desaparicion" del pedido cuando en realidad hubo cambio a `TO_NEW_TICKET`.
- La proteccion via `instructions_read_at` puede volver muy sensibles los tiempos de lectura entre pedidos cercanos.
- Parte de la logica depende de jobs/debounce/locks, asi que la secuencia exacta puede ser dificil de reproducir manualmente.

## Unknowns

- Confirmar exactamente que experiencias de usuario cambian por nivel respecto al maximo de operaciones pendientes.
- Mapear todas las notificaciones visibles asociadas a `TO_NEW_TICKET`.
- Entender mejor el rol de los locks en escenarios de carrera reales.
- Ver si soporte dispone hoy del `mid` ganador/perdedor de forma legible en herramientas internas.

## Fuentes

- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- `saldo/app/Transactions/Jobs/EvaluatorPipes/OnlyOneTransactionWaitingPayment.php`
- `saldo/app/Transactions/Jobs/CancelMultipleWaitingPaymentTransactions.php`
- `saldo/app/Transactions/Events/TransactionStateChangedDebouncedEventDispatcher.php`
- `saldo/app/Transactions/TransactionHelpers/HelperRepositories/OmittedOrdersHelperRepository.php`
- `saldo/app/Transactions/TransactionHelpers/Containers/HelpersContainerRepository.php`
- `saldo/app/Transactions/DirectTransfers/BehaviourEnum.php`
- `saldo/app/Transactions/States/StateEnum.php`
- `saldo/app/Transactions/DirectTransfers/Support/DeleteDirectTransfersService.php`
- `saldo/app/Transactions/Commands/Pipes/TransactionReadyForCancelOrHeld.php`
- `saldo/resources/lang/es/transaction_helpers.php`
