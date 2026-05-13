# Transactions

## Purpose
Describir el dominio central de Saldoar: el pedido como unidad operativa, su lifecycle, sus bifurcaciones y los artefactos que lo hacen avanzar o desviarse.

## What This Domain Owns
- creacion publica y autenticada de pedidos
- transiciones de estado
- instrucciones y visibilidad
- direct transfers
- deals bag y matching
- concurrencia entre pedidos
- chat contextual, helpers y state chips
- notificaciones del pedido
- tareas y acciones que impactan una transaccion

## Core Mental Model
En Saldoar, la transaccion no es solo un registro de cambio. Es el contenedor principal de:
- identidad operativa
- estado
- instrucciones
- validaciones ligadas al pedido
- evidencia
- intervenciones humanas
- notificaciones

Muchos otros dominios se conectan a traves de ella.

## Main Backend Surface
Confirmado en `saldo/app/Transactions/`:
- `Transactions`
- `States`
- `Actions`
- `Deals`
- `DirectTransfers`
- `Notifications`
- `Listeners`
- `Jobs`
- `Tasks`
- `TransactionHelpers`
- `StateChips`
- `ExternalProcessors`
- `Vccs`
- `Screenshots`

## Main Frontend Surface
Confirmado en `solido/apps/solido-app/src/app/transactions/` y dashboard:
- creacion de pedido
- `transaction-states`
- `transaction-info`
- instrucciones
- upload de documentos y comprobantes
- vistas publicas por key
- dashboards de transacciones
- VCC

## Main Entities And Concepts
- `Transaction`
- `State`
- `DirectTransfer`
- `DealsBag`
- `Deal`
- `TransactionHelper`
- `StateChip`
- `Task`
- `Validation` ligada al pedido
- `File` como evidencia

## Key Responsibilities
1. Crear el pedido y decidir su siguiente paso.
2. Determinar si cae en `agreement`, `directTransfers`, `QR`, `crypto wait`, `VCC` u otra rama.
3. Mantener trazabilidad del pedido en estados, helpers, chips, chat y notificaciones.
4. Coordinar con validaciones, cuentas, sistemas, operacion y soporte.
5. Resolver recuperacion, omision, mediacion o acciones manuales.

## Flows Anchored In This Domain
- `create-transaction-and-next-step`
- `transaction-visibility-and-status`
- `payment-instructions`
- `concurrent-orders-and-omitted-transactions`
- `deals-and-direct-transfer-matching`
- `chat-state-chips-and-support-actions`
- `cancellation-held-mediation-recovery`
- `operator-interventions-and-panel-actions`
- `notifications-mails-and-background-jobs`
- `public-order-creation-and-identity-bootstrap`
- `system-specific-branches`

## Boundaries
Este dominio no decide todo solo.

Depende mucho de:
- `validations` para aprobar o bloquear
- `systems-and-integrations` para reglas de sistema, red, rates y procesadores externos
- `support-and-operations` para resolver casos manuales

## UX Reading
- Es el dominio que mas define la experiencia real del usuario.
- Gran parte de la "UI" de Saldoar en realidad se decide en backend via estados, helpers, acciones y restricciones.
- Si no se entiende este dominio, es facil interpretar mal fricciones como si fueran bugs aislados.

## Risks
- Es un dominio muy grande y con mucha logica dispersa en listeners, notifications, actions y jobs.
- Dos pedidos visualmente parecidos pueden divergir mucho por estado, agreement, sistema o direct transfer.
- La experiencia conversacional y operativa esta embebida en este mismo dominio, no separada.

## Main References
- `saldo/app/Transactions/`
- `saldo/routes/api.php`
- `solido/apps/solido-app/src/app/transactions/`
- `solido/apps/solido-app/src/app/dashboard/transactions/`

## Evidence Level
- `confirmed`: estructura principal y responsabilidades generales
- `inferred`: limites finos con otros dominios
