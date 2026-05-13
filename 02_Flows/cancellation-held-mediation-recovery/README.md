# Cancellation Held Mediation Recovery

## Metadata

- `flow_id`: `flow-cancellation-held-mediation-recovery`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar que hace Saldoar cuando un pedido deja de seguir el camino ideal y entra en cancelacion, hold, disputa, mediacion o recovery de destinos.

## Por que importa

Este flujo es critico para producto, soporte y operacion porque define:

- cuando un pedido muere
- cuando un pedido entra en revision
- cuando un pedido queda en disputa
- cuando un pedido todavia puede recuperarse

Tambien es donde suelen aparecer las dudas mas sensibles de usuarios y equipos internos.

## Entry Points

### Cancelacion desde front

- boton de cancelacion en detalle de transaccion
- `POST /v3/users/{user_id}/transactions/{transaction_id}/cancel`
- `POST /v3/t/{transaction_id}/cancel`

### Procesamiento automatico backend

- comandos sobre pendientes con y sin `directTransfers`
- jobs de disputa y recuperacion
- acciones manuales u operativas que fuerzan `HELD`, `MEDIATION` o `CANCELED`

### Vistas y recovery visibles

- ruta de pedido cancelado `/pedido-cancelado`
- pantalla de razon/canal de recuperacion
- wiki `landing-recovery`

## Frontstage

### 1. Cancelacion por usuario

En detalle de transaccion, si `can_be_canceled` esta habilitado:

- el usuario puede cancelar el pedido
- el front pega al endpoint `cancel`
- refresca la transaccion
- redirige a `/pedido-cancelado?mid={mid}`

Si no puede cancelarse, el front muestra tooltip explicativo.

### 2. Pantalla de pedido cancelado

La UI de `transaction-canceled-reason` funciona como una capa de recovery y soporte:

- muestra informacion del pedido cancelado
- puede mostrar una encuesta o motivo de cancelacion
- puede ofrecer WhatsApp en horarios habilitados

O sea: cancelado no siempre significa "fin silencioso"; puede abrir un intento de recuperacion comercial o de soporte.

### 3. Estados no ideales sin cancelacion inmediata

No todos los problemas terminan en cancelacion.

Segun el caso, el pedido puede pasar a:

- `TO_FUTURE_READY`
- `HELD`
- `HELD_DISPUTED`
- `MEDIATION`

Para el usuario esto suele sentirse como:

- "espera"
- "revision"
- "tenemos un problema"
- "ya pague pero no avanzo"

## Backstage

### 1. Cancelacion explicita

Las acciones de cancelacion usan `CancelTransactionActionMiddleware`.

Eso:

- agrega un `State` con `CANCELED`
- guarda texto privado y opcionalmente texto publico
- notifica al usuario

Ademas, al pasar a `CANCELED` o `TO_NEW_TICKET`, `TransactionStateObserver` limpia `directTransfers1` y `directTransfers2`.

### 2. Dos motores distintos segun haya destinos o no

Backend procesa pedidos pendientes por dos caminos:

#### A. Pendientes sin `directTransfers1`

`TransactionsProcessOldPendingWithoutDirectTransfersCommand` trabaja sobre pedidos en `WAITING_PAYMENT` sin destinos asignados.

Reglas detectadas:

- exige al menos 1 hora desde el ultimo mail antes de considerar cancelacion
- evalua variacion de tasa para decidir cuanto tiempo aguanta vivo el pedido
- si la variacion es rentable, puede esperar hasta `5` dias
- si no, puede cortar mucho antes, en `4` horas
- si es un caso acreditable pero inactivo por `48` horas, puede pasar a `HELD`

Este branch muestra que no todos los pendientes se tratan igual: depende de si ya habia matching y de si la tasa sigue teniendo sentido.

#### B. Pendientes con `directTransfers1`

`TransactionsProcessOldPendingWithDirectTransfersCommand` trabaja sobre pedidos con destinos ya asignados.

El orden logico es:

1. liberar destinos no enviados temporalmente
2. cancelar si ya paso la ultima ventana y no hubo actividad ni screenshots
3. pasar a `HELD` si hay destinos mal seteados o incompletos
4. acreditar o retener segun evidencias, screenshots, tiempos y riesgo
5. si no cierra nada de eso, evaluar mediacion

Este branch es mas operativo y mas sensible porque ya hay terceros/destinos involucrados.

### 3. Ultima ventana antes de cancelar o retener

`TransactionReadyForCancelOrHeld` mira una "ultima chance" basada en:

- `instructions_read_at`
- actividad reciente de `directTransfers1`

Si el usuario leyo instrucciones hace poco o hubo actividad reciente en destinos, backend no cancela ni retiene todavia.

### 4. Held y disputa

`HELD` y `HELD_DISPUTED` son estados de revision, pero no significan exactamente lo mismo.

Una regla importante es `HeldDisputedNotReceived`:

- si hay `directTransfers1` marcados como no recibidos
- y ya paso cierto tiempo desde la ultima actividad
- el pedido puede pasar a `HELD_DISPUTED`

Si hay screenshots, backend intenta resolver la disputa antes de dejarlo ahi.
Si no hay screenshots, igual puede caer a `HELD_DISPUTED`.

Tambien hay muchas otras entradas a `HELD`:

- acciones manuales
- destinos invalidos
- actividad sospechosa
- cuentas o validaciones problemáticas

### 5. Mediacion

`MEDIATION` aparece como una etapa mas avanzada que `HELD`.

Una entrada clara es `ToHeldOrMediation`:

- si el pedido ya tiene cierta antiguedad operativa
- y no quedan destinos marcados como `received = NO`
- backend puede pasarlo a `MEDIATION`

Tambien algunas acciones finales pueden terminar en `MEDIATION` si el monto final ya no deja una salida limpia a `SENT`.

### 6. Recovery de destinos

No todo pedido cancelado o en hold queda muerto.

`RecoverDirectTransfers` intenta recuperar destinos eliminados recientemente cuando la transaccion esta en:

- `CANCELED`
- `HELD`

La accion:

- busca `directTransfers1` borrados hace poco
- intenta recrearlos
- puede remover destinos en conflicto del mismo origen
- vuelve a aplicar direct transfers
- y deja el pedido en `HELD`

Eso muestra algo importante: hay cancelaciones/holds que siguen siendo recuperables desde operacion.

### 7. Recovery de disputa

`TryToReleaseDisputeJob` intenta liberar pedidos en `HELD_DISPUTED`.

Si ya no hay destinos marcados como no recibidos:

- puede volver a `WAITING_PAYMENT`
- o incluso a `CREDITED_PAYMENT`

segun si la transaccion queda realmente lista para acreditar.

O sea: una disputa no es necesariamente terminal.

### 8. Recovery de instrucciones/destinos

`TransactionHelper::addDestinationsIfIsRequired` intenta reponer destinos en pedidos `WAITING_PAYMENT` sin `agreement` y sin `deals bag`.

Si logra recrear destinos:

- deja una traza privada
- evita perder el pedido

Si falla:

- lo manda a `TO_FUTURE_READY`

Esto es otro recovery importante: no siempre se recupera "el pago", a veces se recupera la capacidad de seguir operando.

## Trazabilidad Tecnica

### Front

- detalle y cancelacion: `solido/apps/solido-app/src/ui/pages/transaction-details/transaction-details.component.ts`
- acciones de soporte visuales: `solido/apps/solido-app/src/ui/pages/transaction-details/components/transaction-details-support-actions/transaction-details-support-actions.component.html`
- pantalla de cancelado: `solido/apps/solido-app/src/app/transactions/pages/transaction-canceled-reason/transaction-canceled-reason.component.ts`
- landing recovery wiki: `solido/apps/solido-app/src/app/wiki/help/landing-recovery/landing-recovery.component.ts`
- encuesta recovery: `solido/apps/solido-app/src/app/wiki/help/landing-recovery/poll-landing-recovery/poll-landing-recovery.component.ts`

### Back

- middleware de cancelacion: `saldo/app/Transactions/Actions/CancelTransactionActionMiddleware.php`
- observer de estado: `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- helper de cancelacion de usuario: `saldo/app/Transactions/Transactions/TransactionHelper.php`
- procesamiento sin direct transfers: `saldo/app/Transactions/Commands/TransactionsProcessOldPendingWithoutDirectTransfersCommand.php`
- procesamiento con direct transfers: `saldo/app/Transactions/Commands/TransactionsProcessOldPendingWithDirectTransfersCommand.php`
- ultima ventana de actividad: `saldo/app/Transactions/Commands/Pipes/TransactionReadyForCancelOrHeld.php`
- disputa por no recibido: `saldo/app/Transactions/Commands/Pipes/HeldDisputedNotReceived.php`
- umbral de mediacion: `saldo/app/Transactions/Commands/Pipes/TransactionWithTimesForMediation.php`
- paso a mediacion: `saldo/app/Transactions/Commands/Pipes/ToHeldOrMediation.php`
- recovery de destinos: `saldo/app/Transactions/Actions/RecoverDirectTransfers.php`
- recovery de disputa: `saldo/app/Transactions/Jobs/TryToReleaseDisputeJob.php`
- notificaciones por estado: `saldo/app/Transactions/Notifications/StateNotificationsRepository.php`

## Reglas de Negocio Detectadas

### Cancelado no siempre es el unico final malo

El sistema usa varios estados de desvio antes de matar el pedido definitivamente.

### Tener destinos cambia radicalmente el tratamiento

Un pedido sin `directTransfers1` se maneja mas por tiempo y rentabilidad.
Un pedido con destinos asignados entra en logica operativa mucho mas rica.

### La actividad reciente protege al pedido

Leer instrucciones o tocar destinos recientemente retrasa cancelacion/hold automatico.

### Held y mediation no son equivalentes

`HELD` es revision/retencion.
`HELD_DISPUTED` agrega conflicto de recepcion.
`MEDIATION` es una etapa mas avanzada donde el sistema ya reconoce una necesidad de intervencion mayor.

### Recovery existe en varias capas

Se puede intentar recuperar:

- destinos borrados
- disputas
- matching perdido
- conversacion con soporte luego de cancelacion

## Lo que este flujo ya permite responder

- Cuando un usuario puede cancelar y cuando no.
- Por que un pedido paso a `HELD`, `HELD_DISPUTED`, `TO_FUTURE_READY` o `MEDIATION`.
- Como cambia el tratamiento si el pedido tenia destinos asignados.
- Que recuperaciones operativas existen despues de un desvio.
- Por que algunas cancelaciones pueden seguir siendo reversibles internamente.
- Por que no siempre hay mail/notificacion para todos los estados de revision.

## Edge Cases / Riesgos

- `HELD`, `HELD_DISPUTED` y `MEDIATION` no parecen tener la misma cobertura de notificaciones que otros estados.
- Hay recoveries que excluyen explicitamente transacciones creadas desde `deals bag`.
- Un pedido puede parecer "muerto" para el usuario y aun asi seguir teniendo opciones internas de recuperacion.
- Parte del recovery depende de jobs y comandos, no de interaccion inmediata del usuario.
- La frontera entre cancelacion definitiva y hold recuperable puede no ser obvia para soporte si no conoce estas reglas.

## Unknowns

- Mapear todas las acciones manuales que fuerzan `HELD` o `MEDIATION`.
- Documentar con mas precision todos los tiempos de `TransactionTimesRepository`.
- Entender mejor como se presenta `HELD_DISPUTED` en cada variante de UI.
- Ver si existen mails alternativos o mensajes fuera de `StateNotificationsRepository` para estados de revision.

## Fuentes

- `solido/apps/solido-app/src/ui/pages/transaction-details/transaction-details.component.ts`
- `solido/apps/solido-app/src/app/transactions/pages/transaction-canceled-reason/transaction-canceled-reason.component.ts`
- `solido/apps/solido-app/src/app/wiki/help/landing-recovery/landing-recovery.component.ts`
- `solido/apps/solido-app/src/app/wiki/help/landing-recovery/poll-landing-recovery/poll-landing-recovery.component.ts`
- `saldo/app/Transactions/Actions/CancelTransactionActionMiddleware.php`
- `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- `saldo/app/Transactions/Transactions/TransactionHelper.php`
- `saldo/app/Transactions/Commands/TransactionsProcessOldPendingWithoutDirectTransfersCommand.php`
- `saldo/app/Transactions/Commands/TransactionsProcessOldPendingWithDirectTransfersCommand.php`
- `saldo/app/Transactions/Commands/Pipes/TransactionReadyForCancelOrHeld.php`
- `saldo/app/Transactions/Commands/Pipes/HeldDisputedNotReceived.php`
- `saldo/app/Transactions/Commands/Pipes/TransactionWithTimesForMediation.php`
- `saldo/app/Transactions/Commands/Pipes/ToHeldOrMediation.php`
- `saldo/app/Transactions/Actions/RecoverDirectTransfers.php`
- `saldo/app/Transactions/Jobs/TryToReleaseDisputeJob.php`
- `saldo/app/Transactions/Notifications/StateNotificationsRepository.php`
