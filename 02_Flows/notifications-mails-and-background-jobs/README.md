# Notifications Mails And Background Jobs

## Metadata

- `flow_id`: `flow-notifications-mails-and-background-jobs`
- `status`: `v1`
- `owner_area`: `platform`
- `evidence_level`: `confirmed`

## Objetivo

Explicar que cosas hace Saldoar por fuera de la UI: mails, notificaciones, recordatorios, jobs, listeners y comandos que cambian estados o empujan al usuario sin que nadie este interactuando en ese momento.

## Por que importa

Este flujo cierra una parte critica del producto real:

- por que un usuario recibe un mail "de la nada"
- por que un pedido cambia de situacion sin tocar la pantalla
- por que aparecen reminders, tareas o recoveries asincronicos
- por que soporte ve movimientos que no nacieron de una accion manual inmediata

Sin esta capa, muchas decisiones parecen arbitrarias.

## Entry Points

### Disparadores reactivos

- creacion de transaccion
- cambio de estado
- lectura de instrucciones
- aprobacion/rechazo de screenshots
- aprobacion de validaciones
- marcado como enviado
- mensajes publicos del usuario

### Disparadores programados

- commands que barren transacciones viejas o pendientes
- commands de reminders
- jobs debounced/throttled

## Frontstage Visible

Desde el lado usuario, este flujo se traduce en cosas como:

- mails de estado
- mensajes publicos agregados por sistema
- notificaciones de capturas recibidas o rechazadas
- recordatorios para marcar recibido
- mensajes de recovery o de "tu pedido se cancelara"

Muchas veces el usuario no ve el origen tecnico, solo ve el efecto.

## Backstage

### 1. Notificaciones por estado

`StateNotificationsRepository` es la tabla base de notificaciones de transaccion.

Estados con notificacion detectada:

- `CANCELED`
- `TO_NEW_TICKET`
- `TO_FUTURE`
- `TO_FUTURE_READY`
- `WAITING_PAYMENT`
- `CREDITED_PAYMENT`
- `VALIDATION_REQUIRED`
- `PRE_APPROVED_SENT`
- `SENT`

Estados sin cobertura explicita en ese repositorio:

- `HELD`
- `HELD_DISPUTED`
- `MEDIATION`

Eso es importante porque no todos los cambios de estado "hablan" al usuario por el mismo canal.

### 2. Primera comunicacion tras crear pedido

Si una transaccion nace en `NONE`, `TransactionObserverFirstEmail` despacha `TransactionFirstEmailJob`.

Ese job manda el primer mail usando `TransactionFirstMailStateNotification`.

La razon del job es evitar enviar ese primer mail en medio de un rollback de creacion.

### 3. Leer instrucciones agenda un warning

Cuando `MarkInstructionsReadUseCase` marca `instructions_read_at`:

- deja una traza privada
- agenda `DirectTransferVisitedButDontPaidJob`

Ese job espera `10` minutos y, si el pedido sigue en `WAITING_PAYMENT` y todavia hay destinos sin enviar, manda template `transaction_will_be_canceled`.

O sea: ver instrucciones sin pagar no es neutro, dispara seguimiento automatico.

### 4. Reminders programados sobre pedidos

Hay comandos que revisan pedidos viejos y empujan comunicacion:

#### `users:send-reminder`

Busca pedidos en `WAITING_PAYMENT` sin `agreement`, viejos, sin mail reciente, sin otras operaciones posteriores y sin señales de usuario riesgoso.

Si aplica, llama `notifyUser()`.

#### `users:reminder-mark-received`

Busca pedidos en `HELD_DISPUTED` con `directTransfers2.received = NO`.

Si ya pasaron `3` horas laborales desde la ultima referencia temporal cacheada, manda `ReminderMarkReceivedNotification`.

#### `users:reminder-client`

Busca usuarios con historial suficiente de operaciones exitosas pero mucho tiempo sin contacto reciente.

Si aplica, manda `ReminderClientStateNotification`.

Esta ya es una capa de reactivacion/CRM, no solo de transaccion puntual.

### 5. Notificaciones ligadas a screenshots

`ScreenshotsProcessor` puede notificar en `WAITING_PAYMENT` cuando:

- las capturas son aprobadas
- las capturas son rechazadas

Eso muestra que no toda comunicacion depende del estado general de la transaccion; algunas dependen de subprocesos de evidencia.

### 6. Notificaciones ligadas a eventos particulares

Ejemplos detectados:

- `NotifyIfIsTheFirstTimeWithWiseListener`: si es la primera vez con cierta cuenta Wise, agrega estado y manda `template_wise`
- listeners de crypto pueden marcar como enviado y notificar
- validaciones aprobadas pueden reactivar flujo y luego notificar al usuario

Esto mete mensajes muy contextuales que no salen de la tabla general de estados.

### 7. Cambios de estado que disparan mas trabajo

`TransactionStateObserver` no solo emite eventos.
Tambien:

- limpia chips seleccionados
- despacha `TransactionStateChangedEvent`
- agenda `TransactionStateChangedDebouncedEventDispatcher`
- para `CANCELED` y `TO_NEW_TICKET`, limpia direct transfers y puede lanzar `TransactionNextStepToFutureReadyJob`
- para `SENT`, dispara `TransactionSentEvent`

Eso significa que un cambio de estado puede abrir una cascada de tareas invisibles.

### 8. Validaciones y reactivacion del flujo

`ApproveValidationAndSendInstructionsUseCase`:

- aprueba la validacion
- puede pasar a `CREDITED_PAYMENT` o reingresar por `TransactionNextStepUseCase`
- ejecuta `ToNewTicketUserTransactionsJob`
- y luego notifica al usuario

O sea: aprobar una validacion no solo “cierra” una evidencia; puede reencender todo el pedido.

### 9. Public states y procesamiento posterior

`TransactionsProcessPublicStatesCommand` recorre mensajes publicos y los clasifica/procesa con handlers de usuario u operador.

Esto indica que la conversacion publica no solo vive en la UI; tambien se procesa offline para estadistica o contexto operativo.

### 10. Chips que disparan acciones asincronicas

`ApplyTransactionActionJob` deja claro que un `state chip` puede disparar una accion en background sobre la transaccion.

Entonces parte de la “conversacion guiada” en realidad tambien es automatizacion backend.

## Trazabilidad Tecnica

### Notificaciones y helpers

- repositorio de notificaciones por estado: `saldo/app/Transactions/Notifications/StateNotificationsRepository.php`
- helper antirepeticion: `saldo/app/Transactions/Transactions/TransactionNotificationHelper.php`
- primer mail: `saldo/app/Transactions/Transactions/TransactionObserverFirstEmail.php`
- job primer mail: `saldo/app/Transactions/Notifications/TransactionFirstEmailJob.php`

### Jobs y commands de reminder

- lectura de instrucciones: `saldo/app/Transactions/Transactions/UseCases/MarkInstructionsReadUseCase.php`
- warning de no pago: `saldo/app/Transactions/Notifications/DirectTransfers/DirectTransferVisitedButDontPaidJob.php`
- reminder transaccional: `saldo/app/Users/Commands/UsersSendReminderCommand.php`
- reminder mark received: `saldo/app/Users/Commands/UsersReminderMarkReceivedCommand.php`
- reminder cliente: `saldo/app/Users/Commands/UsersReminderClientCommand.php`

### Eventos y procesamiento asincronico

- observer de cambio de estado: `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- aprobacion de validacion: `saldo/app/Transactions/Transactions/UseCases/ApproveValidationAndSendInstructionsUseCase.php`
- dispatch a to-future-ready: `saldo/app/Transactions/Listeners/DispatchTransactionNextStepToFutureReadyJobListener.php`
- procesamiento de public states: `saldo/app/Transactions/Commands/TransactionsProcessPublicStatesCommand.php`
- accion por chip: `saldo/app/Transactions/StateChips/Jobs/ApplyTransactionActionJob.php`

### Casos especiales

- screenshots: `saldo/app/Transactions/Screenshots/ScreenshotsProcessor.php`
- wise first-time: `saldo/app/Transactions/Listeners/NotifyIfIsTheFirstTimeWithWiseListener.php`

## Reglas de Negocio Detectadas

### Notificar no es equivalente a cambiar de estado

Algunos estados tienen notificacion standard y otros no.
Ademas, hay mensajes que salen por eventos secundarios, no por el estado principal.

### El sistema evita spam parcial

Hay varias defensas:

- `notifyToUserIfNeverNotified`
- chequeos de `fechalastcorreo`
- ventanas temporales
- debounce/throttle

### Leer instrucciones ya mete al usuario en un embudo de seguimiento

No hace falta que marque enviado. Solo con leer ya puede quedar agendado un warning.

### Hay una capa de CRM mezclada con producto

No todo es lifecycle transaccional. Tambien hay reminders de reactivacion y deals alerts.

### Mucha logica importante vive fuera de la UI

Si solo se mira front, es facil subestimar cuanto empuja el sistema con commands y jobs.

## Lo que este flujo ya permite responder

- Por que un usuario recibe mails o reminders sin haber tocado nada en ese momento.
- Que estados disparan notificaciones standard y cuales no.
- Como se evita repetir ciertas notificaciones.
- Que pasa despues de leer instrucciones pero no pagar.
- Como validaciones, screenshots y eventos especiales pueden disparar mensajes fuera del flujo principal.
- Por que soporte u operaciones pueden ver cambios asincronicos en el pedido.

## Edge Cases / Riesgos

- `HELD`, `HELD_DISPUTED` y `MEDIATION` parecen tener menos cobertura de notificacion standard.
- Hay una mezcla de notificaciones por estado, por subproceso, por CRM y por eventos especiales.
- Algunos reminders dependen de `fechalastcorreo`, caches o horarios laborales, lo que puede volver dificil explicar el timing exacto.
- Jobs debounced o throttled pueden hacer que el efecto visible llegue bastante despues del disparador original.

## Unknowns

- Mapear en detalle todos los templates usados por `notifyUserByTemplate`.
- Documentar todos los commands y jobs secundarios fuera del core transaccional.
- Entender mejor la capa de notification database versus mail en todos los casos.
- Integrar mas a fondo `deals alerts` y smart opportunities en un dominio separado de marketing/CRM.

## Fuentes

- `saldo/app/Transactions/Notifications/StateNotificationsRepository.php`
- `saldo/app/Transactions/Transactions/TransactionNotificationHelper.php`
- `saldo/app/Transactions/Transactions/TransactionObserverFirstEmail.php`
- `saldo/app/Transactions/Notifications/TransactionFirstEmailJob.php`
- `saldo/app/Transactions/Transactions/UseCases/MarkInstructionsReadUseCase.php`
- `saldo/app/Transactions/Notifications/DirectTransfers/DirectTransferVisitedButDontPaidJob.php`
- `saldo/app/Users/Commands/UsersSendReminderCommand.php`
- `saldo/app/Users/Commands/UsersReminderMarkReceivedCommand.php`
- `saldo/app/Users/Commands/UsersReminderClientCommand.php`
- `saldo/app/Transactions/Screenshots/ScreenshotsProcessor.php`
- `saldo/app/Transactions/Listeners/NotifyIfIsTheFirstTimeWithWiseListener.php`
- `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- `saldo/app/Transactions/Transactions/UseCases/ApproveValidationAndSendInstructionsUseCase.php`
- `saldo/app/Transactions/Listeners/DispatchTransactionNextStepToFutureReadyJobListener.php`
- `saldo/app/Transactions/Commands/TransactionsProcessPublicStatesCommand.php`
- `saldo/app/Transactions/StateChips/Jobs/ApplyTransactionActionJob.php`
