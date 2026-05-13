# Chat State Chips And Support Actions

## Metadata

- `flow_id`: `flow-chat-state-chips-and-support-actions`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar usa helpers, state chips y chat para guiar al usuario, abrir caminos de soporte y convertir mensajes del usuario en trabajo operativo.

## Por que importa

Este flujo es clave porque muchas veces la experiencia real no la define solo el estado tecnico del pedido, sino:

- los helpers visibles
- los chips de accion sugerida
- si el chat esta abierto o no
- si el mensaje del usuario genera tarea para operadores

Eso hace que dos transacciones con el mismo estado nominal puedan sentirse muy distintas.

## Entry Points

### Dashboard autenticado

- vistas de detalle de transaccion en `/my/dashboard/transactions/...`

### Contexto publico por link

- vistas `t/transactions/...`

### Endpoints auxiliares

- `GET /v3/users/{user_id}/state_chips/{transaction_id}`
- `GET /v3/t/state_chips/{transaction_id}`
- `GET /v3/users/{user_id}/is-chat-available/{transaction_id}`
- `GET /v3/t/is-chat-available/{transaction_id}`
- recurso JSON:API `transaction_helpers`
- recurso JSON:API `states`

## Frontstage

### 1. Helpers contextuales

El front consulta `transaction_helpers` para mostrar mensajes contextuales arriba o abajo del flujo principal.

Esos helpers pueden incluir:

- mensaje
- severidad
- color e icono
- boton con accion

No son decoracion. Funcionan como capa de orientacion y recovery.

### 2. State chips

Si el chat todavia no esta abierto, el usuario puede ver `state chips`.

Los chips funcionan como respuestas o caminos sugeridos:

- aparecen dentro del area de chat
- pueden formar arboles con padre/hijo
- pueden incluir texto adaptado al usuario y a la transaccion
- pueden disparar acciones o abrir soporte

Mientras haya chips y el chat no este abierto, el frente prioriza mostrarlos antes que habilitar escritura libre.

### 3. Chat

Cuando el chat esta disponible:

- el input se habilita
- el usuario puede escribir texto libre
- puede adjuntar archivos
- puede completar validaciones pendientes o adjuntar imagenes desde el mismo punto de entrada

El historial incluye:

- mensaje inicial automatico del bot
- estados anteriores
- mensajes del usuario
- respuestas del sistema u operadores

## Backstage

### Helpers: seleccion por estado y prioridad

Backend construye `helper1` y `helper2` a partir de `HelpersContainerRepository`.

La seleccion depende del `state` de la transaccion.

Ejemplos:

- `WAITING_PAYMENT`: screenshots, account details, mark-as-sent, approved receipts
- `HELD`: screenshots, account details, explicacion del hold
- `TO_NEW_TICKET`: helper de pedido omitido
- `TO_FUTURE_READY`: destinos no disponibles
- `VALIDATION_REQUIRED`: helper de validacion

La logica no devuelve un catalogo completo; devuelve hasta dos helpers priorizados segun el orden de repositorios para ese estado.

### State chips: arbol navegable por estado

Backend genera chips segun:

- estado actual de la transaccion
- parent seleccionado
- grupo de `system1`
- grupo de `system2`

Si no hay chips especificos para ese punto, backend agrega chips especiales:

- `GO_BACK`
- `SUPPORT`

Los chips seleccionados se guardan en cache por transaccion, asi que el sistema recuerda en que punto del arbol esta el usuario hasta que el estado cambia o el flujo se limpia.

### Que pasa al tocar un chip

Cuando el usuario selecciona un chip, eso se guarda como un `State` con `state_chip_id`.

Luego backend puede:

- ejecutar una `transaction_action`
- generar una respuesta automatica
- incrementar estadisticas de uso
- abrir el chat si el chip corresponde a soporte

O sea: un chip puede ser UI, analitica y accion operativa al mismo tiempo.

### Apertura del chat

El chat no esta siempre abierto por defecto.

Su disponibilidad depende de `StateChatService`, que guarda un flag en cache por transaccion.

Backend puede abrirlo explicitamente, por ejemplo:

- cuando la transaccion cae a `TO_FUTURE_READY` y hay soluciones accionables
- cuando hay ciertos eventos de riesgo o revision operativa, como cuentas PayPal nuevas o sospechosas
- cuando el usuario llega al chip especial de soporte

Mientras el chat no este abierto, el input queda deshabilitado en front.

### Mensajes del usuario y escalado a operadores

Si el usuario escribe texto libre y no viene de un chip:

- se crea un `State` publico
- un job mergea mensajes consecutivos del usuario
- si corresponde, se crea una tarea para operadores

Eso evita ruido operativo y agrupa varios mensajes cortos en un mismo bloque antes de escalar.

### Limpieza al cambiar de estado

Cuando cambia el estado de la transaccion:

- se limpian los state chips seleccionados en cache
- el arbol se reinicia

Entonces las opciones sugeridas pueden cambiar por completo entre un estado y otro.

## Trazabilidad Tecnica

### Front

- chat UI: `solido/apps/solido-app/src/app/transactions/components/state-chat/state-chat.component.ts`
- template chat UI: `solido/apps/solido-app/src/app/transactions/components/state-chat/state-chat.component.html`
- servicio de chips/chat: `solido/apps/solido-app/src/app/core/services/state-chips.service.ts`
- use case de helpers: `solido/apps/solido-app/src/domain/use-cases/search-transaction-helpers-use-case.ts`
- entidad helper: `solido/apps/solido-app/src/domain/entities/transaction-helper.ts`

### Back

- rutas: `saldo/routes/api.php`
- disponibilidad chat: `saldo/app/Transactions/StateChips/ChatController.php`
- flag de apertura chat: `saldo/app/Transactions/StateChips/StateChatService.php`
- chips por transaccion: `saldo/app/Transactions/StateChips/StateChipController.php`
- logica de chips: `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- recepcion de chip: `saldo/app/Transactions/StateChips/Jobs/HandleReceivedStateChipJob.php`
- respuesta/uso de chip: `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- helpers JSON:API: `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperService.php`
- entity helpers JSON:API: `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperContainerJsonApiEntity.php`
- priorizacion de helpers: `saldo/app/Transactions/TransactionHelpers/Containers/HelpersContainerRepository.php`
- manejo de texto publico: `saldo/app/Transactions/States/States/HandlePublicTextObserver.php`
- merge y tarea operativa: `saldo/app/Transactions/States/Jobs/MergePublicTextAndCreateAnOperatorTaskJob.php`
- reset de chips al cambiar estado: `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- ejemplo de apertura operativa de chat: `saldo/app/Transactions/Listeners/CreateATaskWhenEmailAccountIsDifferentAndIsNewListener.php`
- ejemplo de apertura por next step: `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`

## Reglas de Negocio Detectadas

### Los helpers son una capa de decision UX

El sistema no muestra un mensaje fijo por estado. Muestra hasta dos helpers priorizados segun reglas backend.

### Los chips son guiados, no libres

Los state chips se calculan por estado y por compatibilidad con los grupos del sistema. No son opciones universales.

### El chat se habilita cuando backend lo decide

El input libre depende de un flag de disponibilidad. Eso permite controlar cuando conviene guiar con chips y cuando conviene abrir conversacion.

### Un mensaje del usuario puede convertirse en tarea

El texto libre no queda solo como historial. Puede agruparse y escalar a operadores.

### Las acciones de soporte y las acciones transaccionales conviven

Un chip o helper puede:

- orientar
- pedir evidencia
- abrir conversacion
- o disparar una accion sobre la transaccion

## Lo que este flujo ya permite responder

- Por que un usuario ve chips y otro puede escribir libremente.
- De donde salen los banners o helpers contextuales.
- Como se decide abrir el chat.
- Que pasa cuando un usuario toca un chip.
- Como se transforman mensajes del usuario en trabajo operativo.
- Por que las opciones visibles cambian cuando la transaccion cambia de estado.

## Edge Cases / Riesgos

- Dos transacciones con el mismo estado tecnico pueden mostrar helpers y chips distintos.
- Si el chat no esta abierto, el usuario puede sentir que no puede “hablar” aunque este dentro del area de chat.
- El arbol de chips vive en cache; cambios de estado lo resetean.
- Chips especiales como `SUPPORT` y `GO_BACK` alteran la navegacion aunque no pertenezcan al catalogo principal del estado.
- El merge de mensajes del usuario puede ocultar el detalle de varios mensajes separados si alguien espera verlos individualmente.

## Unknowns

- Mapear el catalogo completo de `state_chips` y sus relaciones padre/hijo.
- Documentar todas las `transaction_action` posibles disparadas por chips.
- Identificar todos los listeners que pueden abrir o cerrar chat fuera de los ejemplos ya encontrados.
- Entender mejor el consumo front exacto de `helper1` y `helper2` en todas las pantallas donde aparecen.

## Fuentes

- `solido/apps/solido-app/src/app/transactions/components/state-chat/state-chat.component.ts`
- `solido/apps/solido-app/src/app/transactions/components/state-chat/state-chat.component.html`
- `solido/apps/solido-app/src/app/core/services/state-chips.service.ts`
- `solido/apps/solido-app/src/domain/use-cases/search-transaction-helpers-use-case.ts`
- `solido/apps/solido-app/src/domain/entities/transaction-helper.ts`
- `saldo/routes/api.php`
- `saldo/app/Transactions/StateChips/ChatController.php`
- `saldo/app/Transactions/StateChips/StateChatService.php`
- `saldo/app/Transactions/StateChips/StateChipController.php`
- `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedStateChipJob.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperService.php`
- `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperContainerJsonApiEntity.php`
- `saldo/app/Transactions/TransactionHelpers/Containers/HelpersContainerRepository.php`
- `saldo/app/Transactions/States/States/HandlePublicTextObserver.php`
- `saldo/app/Transactions/States/Jobs/MergePublicTextAndCreateAnOperatorTaskJob.php`
- `saldo/app/Transactions/Transactions/TransactionStateObserver.php`
- `saldo/app/Transactions/Listeners/CreateATaskWhenEmailAccountIsDifferentAndIsNewListener.php`
- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
