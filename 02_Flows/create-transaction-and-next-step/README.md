# Create Transaction And Next Step

## Metadata

- `flow_id`: `flow-create-transaction-and-next-step`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como nace una transaccion en Saldoar y como el sistema decide su siguiente estado operativo.

Este flujo es troncal porque conecta:

- creación desde front
- validaciones previas
- riesgo y reglas de negocio
- matching con acuerdo o destinos
- transiciones a `TO_FUTURE_READY`, `WAITING_PAYMENT` o `CREDITED_PAYMENT`

## Por que importa

Si no están el CEO o el CTO, este es el flujo que más ayuda a entender:

- por qué un pedido arranca o no arranca
- por qué a veces hay instrucciones inmediatas y a veces no
- dónde se frena por validación, riesgo o disponibilidad
- qué diferencia hay entre un pedido listo para pagar y uno a futuro

## Entry Points

### Front autenticado

Varios flujos del dashboard crean una transacción y redirigen a instrucciones:

- depósito
- retiro
- transferencia
- conversión

Todas esas estrategias terminan usando `CreateTransactionUseCase` y luego navegan a:

- `/my/dashboard/transactions/v3/{transactionId}/instructions`

### Back por deals bag

Hay otro camino importante donde la transacción no nace desde un formulario simple sino desde `DealsBag`.

Cuando un `DealsBag` pasa de `FILLING` a `FILLED`, backend crea la transacción directamente y la puede mandar a `WAITING_PAYMENT`.

### Back después de aprobar validación

Cuando se aprueba una validación que destraba al usuario, `ApproveValidationAndSendInstructionsUseCase` puede reinyectar la transacción al flujo y recalcular el siguiente paso.

## Frontstage

### Creación desde balance/dashboard

Las estrategias de balance arman un `TransactionPrivate` con:

- montos
- `system1` / `system2`
- `account1` / `account2`

Luego llaman a `CreateTransactionUseCase` con `beforepath = users/{userId}`.

Si la creación sale bien, el front no decide mucho más: redirige a instrucciones del pedido nuevo.

### Implicancia UX

Desde el punto de vista del usuario, "crear pedido" y "ver instrucciones" parecen un solo paso continuo.

Pero técnicamente entre medio backend todavía decide:

- si entra a `WAITING_PAYMENT`
- si queda en `TO_FUTURE_READY`
- si requiere validación
- si se acredita directo

## Backstage

### 1. Se crea la transacción

En front, `CreateTransactionUseCase` persiste un `TransactionPrivate` con `include: ['metas']`.

En backend, la entidad `Transaction` tiene observers y metas de creación.

### 2. Se decide el siguiente paso

El motor clave es `TransactionNextStepUseCase`.

Ese caso de uso:

- mira si la transacción ya está `received`
- corre un pipeline de reglas
- intenta matchear con acuerdo
- si no, intenta matchear con `direct_transfers`
- si tampoco puede, manda a `TO_FUTURE_READY`

### 3. Pipeline de reglas

Antes de avanzar, `TransactionNextStepUseCase` corre pipes como:

- `CheckUserFlagLevel`
- `HeldForVenezuelansOnWiseOrEuro`
- `OnlyOneTransactionWaitingPayment` cuando hay control activo
- `UserValidationsInProgress`
- `IsUserValidationRequired`
- `CheckRatesVariationPercent`
- más pipes posteriores de amount/risk

Eso significa que crear una transacción no garantiza que vaya directo a instrucciones listas para pagar.

### 4. Si ya estaba recibida

Si `transaction.received` ya es `true`, backend la manda a `CREDITED_PAYMENT`.

### 5. Intento de acuerdo

Si hay `agreement1_id` o backend consigue un `Agreement` compatible:

- se procesa por acuerdo
- si funciona, la transacción pasa a `WAITING_PAYMENT`

Esto suele terminar en instrucciones tipo QR / acuerdo.

### 6. Intento de direct transfers

Si no hay acuerdo, backend usa `TransactionDirectTransfersProcessor`.

Si logra aplicar destinos:

- limpia relación cargada de `directTransfers1`
- mueve la transacción a `WAITING_PAYMENT`

Esto suele terminar en instrucciones con uno o varios pagos/destinos.

### 7. Si no hay destinos accionables

Si no hay acuerdo ni direct transfers disponibles:

- el sistema arma alternativas con `ToFutureReadyOptionsHelper`
- si hay soluciones accionables, abre chat con `StateChatService`
- la transacción pasa a `TO_FUTURE_READY`

Ese es el caso clásico de "todavía no puedo pagar, el sistema sigue buscando / ofrece alternativas".

## Camino paralelo: DealsBag

`DealsBagCreateTransactionWhenIsFilledObserver` es otro camino clave.

Cuando el deals bag se llena:

- arma la transacción
- evalúa riesgos específicos
- valida rate drop y monto mínimo
- guarda transacción
- crea `directTransfers1`
- ajusta montos si hace falta
- manda la transacción directo a `WAITING_PAYMENT`
- notifica al usuario

Este flujo es más automático que la creación manual y ya nace mucho más cerca de instrucciones operativas.

## Camino paralelo: aprobación de validación

`ApproveValidationAndSendInstructionsUseCase` toma una validación aprobada y:

- obtiene la transacción asociada
- si ya estaba recibida la manda a `CREDITED_PAYMENT`
- si no, la devuelve a `TO_FUTURE`
- reejecuta `TransactionNextStepUseCase`
- luego notifica y corre limpieza de otros pedidos del usuario

Eso explica por qué aprobar una validación puede "destrabar" de golpe un pedido que antes no avanzaba.

## Trazabilidad Tecnica

### Front

- creación genérica: `solido/apps/solido-app/src/domain/use-cases/create-transaction.use-case.ts`
- ejemplo depósito: `solido/apps/solido-app/src/ui/features/balance/application/strategies/deposit-strategy.ts`
- ejemplo retiro: `solido/apps/solido-app/src/ui/features/balance/application/strategies/withdraw-strategy.ts`

### Back

- siguiente paso: `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- creación por deals bag: `saldo/app/Transactions/Deals/DealsBag/DealsBagCreateTransactionWhenIsFilledObserver.php`
- reentrada tras validación: `saldo/app/Transactions/Transactions/UseCases/ApproveValidationAndSendInstructionsUseCase.php`
- notificación waiting payment: `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotification.php`

## Reglas de Negocio Detectadas

### Crear no equivale a quedar listo para pagar

Después del create, backend todavía decide si:

- acredita
- pide validación
- asigna acuerdo
- asigna destinos
- manda a futuro

### `WAITING_PAYMENT` tiene dos sabores principales

Cuando una transacción entra en `WAITING_PAYMENT`, la experiencia posterior cambia bastante según:

- `agreement1_id > 0`
- o direct transfers asignados

### `TO_FUTURE_READY` no es error

Es un estado operativo válido para:

- esperar destinos
- ofrecer alternativas
- abrir chat si hay salida accionable

### Validaciones y riesgo influyen temprano

El motor de siguiente paso corta antes de generar instrucciones finales si:

- hay validaciones en progreso
- el usuario requiere validación
- el riesgo/rates no dan

## Lo que este flujo ya permite responder

- Qué pasa realmente entre “crear pedido” y “ver instrucciones”.
- Por qué algunos pedidos van directo a pago y otros no.
- Dónde se decide acuerdo vs direct transfers.
- Cuándo aparece `TO_FUTURE_READY`.
- Cómo una validación aprobada puede reactivar el pedido.
- Qué diferencia tiene una transacción creada vía dashboard versus vía deals bag.

## Edge Cases / Riesgos

- El front parece lineal, pero backend puede tomar varios desvíos antes de estabilizar el pedido.
- `DealsBag` y creación manual no son equivalentes; si se comparan sin contexto, pueden parecer inconsistentes.
- `TO_FUTURE_READY` puede sentirse ambiguo si UX/copy no deja clara la causa.
- Las reglas del pipeline pueden cambiar el resultado sin que el formulario del front cambie.

## Unknowns

- Mapear mejor qué pipes son más frecuentes en producción para explicar desvíos reales.
- Documentar mejor los caminos de `transfer` y `convert`, no sólo `deposit`/`withdraw`.
- Entender con más detalle la capa exacta donde se crea el `TransactionPrivate` en backend JSON:API.
- Profundizar el rol de `metas` en la creación inicial.

## Fuentes

- `solido/apps/solido-app/src/domain/use-cases/create-transaction.use-case.ts`
- `solido/apps/solido-app/src/ui/features/balance/application/strategies/deposit-strategy.ts`
- `solido/apps/solido-app/src/ui/features/balance/application/strategies/withdraw-strategy.ts`
- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagCreateTransactionWhenIsFilledObserver.php`
- `saldo/app/Transactions/Transactions/UseCases/ApproveValidationAndSendInstructionsUseCase.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotification.php`
