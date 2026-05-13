# Operator Interventions And Panel Actions

## Metadata

- `flow_id`: `flow-operator-interventions-and-panel-actions`
- `status`: `v1`
- `owner_area`: `operations`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como la operacion interviene manualmente sobre los pedidos desde panel, como se crean y asignan tareas, y que acciones pueden cambiar el estado o la estructura de una transaccion.

## Por que importa

Este flujo es clave porque parte importante del comportamiento real de Saldoar no depende solo del usuario o del backend automatico.

Tambien depende de:

- tareas para operadores
- respuestas manuales
- cambios de estado hechos desde panel
- acciones correctivas sobre destinos, montos o acreditacion

Sin esta capa, el brain queda incompleto.

## Entry Points

### Panel / tareas

- `/panel/transactions/tasks/reply`
- `/panel/transactions/task_completed`
- `/panel/transactions/reply_text`
- `/panel/state-chips/close-chat/{transaction_id}/{transaction_mid}`
- `/panel/movimiento/?mid={mid}`

### Eventos internos que crean trabajo

- estados con `saveWithOperatorTask()`
- mensajes publicos del usuario
- listeners de riesgo o inconsistencia
- acciones que crean o redistribuyen tareas

## Frontstage / Operacion Visible

### 1. El pedido entra al radar operativo

Una transaccion puede generar tarea porque:

- el usuario escribio algo relevante
- un bot o regla detecto un problema
- un estado interno exige revision
- un operador o proceso previo dejo una tarea asociada

La unidad de trabajo visible para operacion es la `Task`, ligada a un `State`.

### 2. Un operador toma o responde una tarea

Desde panel, un operador puede:

- tomar una tarea sin asignar
- responder y entrar al movimiento del pedido
- marcarla como completada
- dejar texto privado o publico
- eventualmente crear una nueva tarea para otro operador

### 3. El operador ejecuta una accion

Segun el `task_type`, operacion puede hacer cosas como:

- cancelar
- congelar (`HELD`)
- agregar destinos
- cambiar cuenta destino
- marcar destino no valido
- acreditar con o sin reset de posicion
- recuperar pedido
- redimensionar montos
- revertir pedido
- finalizar como `SENT`
- mandar a `MEDIATION`

## Backstage

### La tarea es el puente entre estado y operacion

`TaskService` toma un `ActionRequest` y lo pasa por un pipeline segun `TaskTypesEnum`.

Eso significa que una tarea no es solo un pendiente visual.
Es una instruccion ejecutable con efectos de negocio.

### Catalogo operativo principal

`TaskTypesEnum` define el menu de intervenciones manuales.

Ejemplos detectados:

- `cancel`
- `freeze`
- `add_destinations`
- `change_destination`
- `destination_not_valid`
- `credit_reset`
- `credit`
- `recover`
- `resize`
- `reverse_transaction`
- `finish_as_sent`
- `to_mediation`

Cada uno tiene:

- nombre operativo
- estado objetivo esperado
- pipeline de acciones

### Los pipelines tienen fallback y controles

Muchos task types no ejecutan una sola accion lineal.

Ejemplos:

- `cancel` intenta cancelar, valida si hay pago o validacion en progreso, puede crear tarea admin y termina en `Held` si no pudo cerrar limpio
- `add_destinations` intenta reponer `directTransfers`, pero si falla puede dejar el pedido en `TO_FUTURE_READY`
- `credit` y `credit_reset` intentan varias estrategias de acreditacion antes de caer a `Held`

O sea: la operacion no siempre “aplica una accion”. Muchas veces corre una secuencia de intentos controlados.

### Crear un estado puede crear una tarea

`TransactionStateHelper` es el punto comun:

- guarda `State`
- puede cambiar el `state` actual de la transaccion
- puede adjuntar texto privado/publico
- puede dejar `saveWithOperatorTask()`

Entonces una intervencion operativa suele materializarse como:

1. nuevo `State`
2. posible cambio de estado transaccional
3. posible nueva `Task`

### Ownership y asignacion

`PanelTaskController` muestra reglas simples pero importantes:

- si una tarea no tiene `assigned_user_id`, el primer operador que responde puede apropiarsela
- una tarea se puede completar si esta asignada al operador actual o a nadie
- si la tarea cambió de estado/base mientras el operador trabajaba, se evita cerrarla a ciegas

Ademas, `OnlyAssignedCanRemoveTasksCreatedBySystemObserver` protege tareas de sistema:

- no cualquiera puede completarlas
- debe ser el asignado o el autor

### Creacion masiva o inteligente de tareas

`OperatorTaskHelper` maneja varios patrones:

- crear tarea para todos los operadores
- crearla solo si no hay otra abierta
- asignarla a un operador online segun rol
- evitar duplicados sobre el mismo pedido

Tambien aparece una capa de bot:

- si el estado es `WAITING_PAYMENT` y no hay cierta condicion de bloqueo, puede asignarse al bot
- luego el bot puede devolver la tarea a humanos

Esto muestra que operacion no es solo humana: hay un reparto mixto bot/humano.

### Reply manual desde panel

`PanelTaskReplyTextController` permite:

- dejar texto privado
- dejar texto publico
- abrir chat si el mensaje publico va al usuario
- crear nueva tarea para un operador especifico
- cerrar la tarea origen si ya hubo respuesta o reasignacion

Es una pieza importante porque convierte la interfaz de panel en canal conversacional y no solo en tablero interno.

### Ejemplos de acciones con impacto alto

#### `Held`

Deja el pedido en `HELD` con observacion privada/publica y autor identificado.

#### `AddDirectTransfers`

Intenta agregar destinos nuevos.
No aplica en pedidos creados con `deals bag`.
Si logra matching, vuelve a `WAITING_PAYMENT`; si no, puede ir a `TO_FUTURE_READY`.

#### `AdjustAndCreditWithDirectTransfers`

Elimina destinos no enviados, ajusta montos, valida que siga siendo acreditable y si todo cierra mueve a `CREDITED_PAYMENT`.

Esto muestra que operacion puede reconfigurar economicamente un pedido antes de acreditarlo.

## Trazabilidad Tecnica

### Panel y rutas

- rutas panel: `saldo/routes/panel.php`
- controller de reply/completado: `saldo/app/Transactions/Tasks/PanelTaskController.php`
- reply manual con texto: `saldo/app/View/Controllers/Transactions/PanelTaskReplyTextController.php`
- cierre manual de chat: `saldo/app/Transactions/StateChips/ChatController.php`

### Tasks y ejecucion

- servicio de tareas: `saldo/app/Transactions/Tasks/TaskService.php`
- catalogo de task types: `saldo/app/Transactions/Tasks/TaskTypesEnum.php`
- helper de estados y tareas: `saldo/app/Transactions/Helpers/StatesAndTasks/TransactionStateHelper.php`
- request de accion: `saldo/app/Transactions/Actions/ActionRequest.php`
- helper de asignacion: `saldo/app/Users/Operators/OperatorTaskHelper.php`
- proteccion de completado: `saldo/app/Transactions/Tasks/OnlyAssignedCanRemoveTasksCreatedBySystemObserver.php`
- estados visibles en panel: `saldo/app/Transactions/States/StatePanelRepository.php`

### Ejemplos de acciones

- `saldo/app/Transactions/Actions/Held.php`
- `saldo/app/Transactions/Actions/AddDirectTransfers.php`
- `saldo/app/Transactions/Actions/AdjustAndCreditWithDirectTransfers.php`
- `saldo/app/Transactions/Actions/RecoverDirectTransfers.php`
- `saldo/app/Transactions/Actions/ToMediation.php`

## Reglas de Negocio Detectadas

### Operacion no solo comenta: ejecuta

Las tareas pueden disparar pipelines que cambian estado, destinos, montos y notificaciones.

### El estado del pedido puede cambiar por una mezcla de humano y automatizacion

Hay tareas creadas por sistema, por usuario, por bot y por operadores.

### No todas las acciones manuales estan disponibles para todos los tipos de pedido

Ejemplo claro: no se pueden agregar destinos manualmente a pedidos creados con `deals bag`.

### El ownership importa

La asignacion de tareas cambia quien puede cerrarlas y reduce intervenciones conflictivas.

### El panel tambien habla con el usuario

Cuando un operador deja `public_text`, no esta solo documentando internamente: puede alterar el chat y la experiencia visible del usuario.

## Lo que este flujo ya permite responder

- Que puede hacer operacion manualmente sobre un pedido.
- Como una tarea se convierte en cambio real de transaccion.
- Como se asignan, responden y cierran tareas.
- Que diferencia hay entre observacion interna y mensaje publico.
- Por que un operador puede cambiar destinos, ajustar montos o mandar un pedido a hold/mediacion.
- Como se combinan bot, reglas y operadores humanos.

## Edge Cases / Riesgos

- Algunas acciones operativas tienen fallback a `HELD`, asi que un intento fallido puede dejar el pedido retenido y no resuelto.
- Hay restricciones especificas por tipo de pedido que soporte/UX puede no tener presentes.
- El panel puede cerrar tareas sobre bases que cambian por merge de mensajes o cambios de estado.
- Parte de la experiencia usuario visible puede originarse en texto manual desde panel y no en la UI principal del producto.
- La mezcla bot/humano puede volver dificil rastrear “quien movio” realmente un pedido si no se mira la secuencia de estados.

## Unknowns

- Mapear el uso real en panel de cada `task_type` y en que pantallas se ofrece.
- Documentar todas las acciones no inspeccionadas del catalogo.
- Entender mejor las reglas de reasignacion entre operadores y roles.
- Ver si existen auditorias o métricas mas ricas para uso de acciones panel.

## Fuentes

- `saldo/routes/panel.php`
- `saldo/app/Transactions/Tasks/PanelTaskController.php`
- `saldo/app/View/Controllers/Transactions/PanelTaskReplyTextController.php`
- `saldo/app/Transactions/Tasks/TaskService.php`
- `saldo/app/Transactions/Tasks/TaskTypesEnum.php`
- `saldo/app/Transactions/Helpers/StatesAndTasks/TransactionStateHelper.php`
- `saldo/app/Transactions/Actions/ActionRequest.php`
- `saldo/app/Users/Operators/OperatorTaskHelper.php`
- `saldo/app/Transactions/Tasks/OnlyAssignedCanRemoveTasksCreatedBySystemObserver.php`
- `saldo/app/Transactions/States/StatePanelRepository.php`
- `saldo/app/Transactions/Actions/Held.php`
- `saldo/app/Transactions/Actions/AddDirectTransfers.php`
- `saldo/app/Transactions/Actions/AdjustAndCreditWithDirectTransfers.php`
- `saldo/app/Transactions/Actions/RecoverDirectTransfers.php`
- `saldo/app/Transactions/Actions/ToMediation.php`
