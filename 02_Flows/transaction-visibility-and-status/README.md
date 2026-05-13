# Transaction Visibility And Status

## Metadata

- `flow_id`: `flow-transaction-visibility-and-status`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como un usuario consulta una transaccion, ve instrucciones, revisa estados, detecta validaciones pendientes y eventualmente cancela desde contexto publico o dashboard.

## Por que importa

Este flujo cruza a varias areas:

- soporte: seguimiento de pedidos, estado, chat, validaciones
- marketing: enlaces publicos y landings de consulta
- UX: claridad de estados, recuperacion y fricciones
- producto/dev: wiring entre deep links, estado y backend

## Entry Points

### 1. Consulta publica de estado

- ruta frontend: `/transaction-states`
- tambien admite locale: `/:langCode/transaction-states`
- existe redireccion legacy desde backend: `/estado-solicitud` -> `/transaction-states`

### 2. Deep links publicos de transaccion

- `/t/transactions/v3/{transactionId}/{transactionKey}/{transactionMid}/instructions`
- `/t/transactions/v3/{transactionId}/{transactionKey}/{transactionMid}/states`
- `/t/transactions/v3/{transactionId}/{transactionKey}/{transactionMid}/screenshot`

### 3. Acceso autenticado desde dashboard

- `/my/dashboard/transactions/v3/{transactionId}/instructions`
- `/my/dashboard/transactions/v3/{transactionId}/states`
- `/my/dashboard/transactions/v3/{transactionId}/screenshot`

## Frontstage

### Consulta publica de estado

El usuario llega a una pantalla de consulta de pedido, ingresa `mid` y `email`, y el front guarda/consulta un `TransactionStatePublic`.

Cuando el token queda disponible, el front recupera el recurso incluyendo:

- `states`
- `system1`
- `system2`

Despues transforma ese recurso publico a un objeto `Transaction` para mostrar el estado.

### Deep links de transaccion

El front tiene un `UrlHandlerService` que resuelve URLs y navega a:

- instrucciones
- screenshot
- states

En contexto publico usa `document.location.href`.
En dashboard usa `router.navigate`.

### Contextos distintos

El front distingue entre:

- `public transaction context`: URL contiene `/t/`
- `dashboard context`: URL contiene `dashboard`

Eso cambia:

- prefijo de llamadas backend (`beforepath`)
- forma de navegacion
- uso de socket privado y `userAlive`
- algunos endpoints de cancelacion

## Backstage

### Redireccion legacy

El backend conserva compatibilidad:

- `/estado-solicitud` redirige con `301` al frontend `/transaction-states`

### Endpoints API de estado y acciones

Contexto autenticado por usuario:

- `GET v3/users/{user_id}/state_chips/{transaction_id}`
- `GET v3/users/{user_id}/is-chat-available/{transaction_id}`
- `POST v3/users/{user_id}/transactions/{transaction_id}/cancel`
- `GET v3/users/{user_id}/transactions/{transaction_id}/mercadopagoqr`

Contexto publico por transaccion:

- `GET v3/t/state_chips/{transaction_id}`
- `GET v3/t/is-chat-available/{transaction_id}`
- `POST v3/t/{transaction_id}/cancel`
- `GET v3/t/{transaction_id}/mercadopagoqr`

### Endpoints protegidos por key/mid

El backend tambien expone rutas tipo:

- `/transactions/{transaction_mid}/{key}/chat-available`
- `/transactions/{transaction_mid}/{key}/has-pending-validation`

Estas viven bajo middleware de chequeo de transaccion y son relevantes para vistas publicas con llave.

## Trazabilidad Tecnica

### Front

- rutas base en `solido/apps/solido-app/src/app/app-routing.module.ts`
- logica de contexto en `solido/apps/solido-app/src/ui/shared/services/instructions.service.ts`
- resolucion de deep links en `solido/apps/solido-app/src/ui/shared/services/url-handler.service.ts`
- pantalla publica de consulta en `solido/apps/solido-app/src/app/transactions/pages/transaction-states/transaction-states.component.ts`
- detalle de transaccion y cancelacion en `solido/apps/solido-app/src/ui/pages/transaction-details/transaction-details.component.ts`

### Back

- rutas API en `saldo/routes/api.php`
- rutas publicas/legacy en `saldo/routes/panel.php`
- redireccion legacy en `saldo/app/Core/Legacy/LegacyRedirectionController.php`
- validacion pendiente en `saldo/app/Transactions/TransactionDetails/PendingValidationController.php`

## Reglas de Negocio Detectadas

### `beforepath`

El front genera un `beforepath` distinto segun contexto:

- dashboard: `users/{userId}`
- publico: `t`

Eso define desde que namespace API se consultan acciones y recursos.

### Cancelacion

La cancelacion desde `TransactionDetailsComponent`:

- arma una copia de `Transaction`
- la marca como `CANCELED`
- pega al endpoint `v3/{beforepathForCancel}/{transactionId}/cancel`
- vuelve a pedir la transaccion actualizada
- redirige a `/pedido-cancelado`

### Validaciones pendientes

El backend devuelve `validation_links` segun dos caminos:

- link por transaccion a screenshot
- link por usuario a validacion

La logica de screenshot solo aplica si:

- la transaccion esta en `WAITING_PAYMENT`
- esta `marked_as_sent`
- y no existen validaciones con estado `PRE_APPROVED`, `APPROVED` o `SKIPPED`

## Lo que este flujo ya permite responder

- Como llega un usuario a consultar el estado de su pedido.
- Cual es la diferencia entre ver una transaccion publica y verla en dashboard.
- Donde vive la logica de cancelacion.
- Donde buscar chat disponible y state chips.
- Como se mantiene compatibilidad con URLs legacy.
- En que casos aparece una validacion pendiente ligada a la transaccion.

## Edge Cases / Riesgos

- El mismo concepto "estado de transaccion" aparece por al menos dos superficies: `transaction-states` y detalle `/t/transactions/v3/...`.
- Hay mezcla de rutas nuevas, rutas legacy y resolucion por URL matcher.
- El nombre `beforepath` concentra bastante logica implícita; si cambia, rompe multiples use cases.
- Todavia no esta documentado aqui el recurso exacto `TransactionStatePublic` del backend.

## Unknowns

- Confirmar modelo/backend exacto de `TransactionStatePublic` y su ciclo de vida.
- Mapear el origen completo de `state_chips` y sus tipos.
- Documentar cuando el chat se habilita funcionalmente, no solo tecnicamente.
- Ver si `mercadopagoqr` participa siempre en este flujo o solo en ciertos sistemas/metodos.

## Fuentes

- `solido/apps/solido-app/src/app/app-routing.module.ts`
- `solido/apps/solido-app/src/ui/shared/services/instructions.service.ts`
- `solido/apps/solido-app/src/ui/shared/services/url-handler.service.ts`
- `solido/apps/solido-app/src/ui/pages/transaction-details/transaction-details.component.ts`
- `solido/apps/solido-app/src/app/transactions/pages/transaction-states/transaction-states.component.ts`
- `saldo/routes/api.php`
- `saldo/routes/panel.php`
- `saldo/app/Core/Legacy/LegacyRedirectionController.php`
- `saldo/app/Transactions/TransactionDetails/PendingValidationController.php`
