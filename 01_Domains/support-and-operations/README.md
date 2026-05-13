# Support And Operations

## Purpose
Describir la capa humana y operativa que interviene cuando el flujo automatico no alcanza o cuando el pedido necesita seguimiento, resolucion o accion manual.

## What This Domain Owns
- tareas para operadores
- ownership y reasignacion
- respuestas desde panel
- apertura o cierre de chat operativo
- intervenciones manuales sobre la transaccion
- seguimiento de casos anormales, conflictos o recoveries

## Core Mental Model
Saldoar no es solo automatizacion. Tiene una capa operativa embebida dentro del producto.

Esa capa:
- recibe señales desde estados y listeners
- toma tareas
- responde al usuario
- ejecuta acciones manuales
- puede cambiar el rumbo del pedido

## Main Backend Surface
Confirmado e inferido a partir de:
- `saldo/app/Transactions/Tasks`
- `saldo/app/Transactions/StateChips`
- `saldo/app/Transactions/Helpers`
- `saldo/app/Transactions/Actions`
- `saldo/routes/panel.php`
- piezas utilitarias en `saldo/app/Support/`

## Main Frontend Surface
Mas visible por efecto que por modulo unico.

Se expresa en:
- chat del pedido
- helpers
- chips
- estados visibles
- dashboard privado
- panel interno y respuestas operativas

## Main Entities And Concepts
- `Task`
- `TaskType`
- operator ownership
- `StateChip`
- `TransactionHelper`
- panel action
- state chat

## Key Responsibilities
1. Convertir casos ambiguos en trabajo operativo.
2. Permitir que una persona intervenga sobre el pedido sin romper trazabilidad.
3. Abrir, sostener o cerrar conversaciones contextuales con el usuario.
4. Resolver excepciones, disputas, cambios de destino, cancelaciones o recoveries.

## Flows Anchored In This Domain
- `chat-state-chips-and-support-actions`
- `cancellation-held-mediation-recovery`
- `operator-interventions-and-panel-actions`
- `notifications-mails-and-background-jobs`
- `concurrent-orders-and-omitted-transactions`

## Boundaries
Este dominio no define el producto base ni las reglas de sistema, pero ejecuta y resuelve cuando:
- el pedido entra en conflicto
- hace falta confirmacion humana
- hay riesgo
- el usuario necesita ayuda contextual

Se apoya mucho en:
- `transactions`
- `validations`
- `systems-and-integrations`

## UX Reading
- Para el usuario, soporte y operacion muchas veces "son el producto".
- Los helpers, chips y chats no son accesorios: son la interfaz de recovery y confianza.
- La experiencia real del pedido depende mucho de que tan bien esta orquestada esta capa humana.

## Risks
- Si esta capa no se entiende, se subestima cuanto del producto depende de acciones manuales.
- Un cambio de copy o de estado puede alterar carga operativa aunque el flujo tecnico parezca igual.
- Parte de esta logica vive dispersa entre panel, tasks, listeners y acciones.

## Main References
- `saldo/app/Transactions/Tasks/`
- `saldo/app/Transactions/StateChips/`
- `saldo/app/Transactions/Helpers/`
- `saldo/app/Transactions/Actions/`
- `saldo/routes/panel.php`
- `saldo/app/Support/`

## Evidence Level
- `confirmed`: existencia de tareas, panel actions, chat y helpers
- `inferred`: limites exactos entre soporte, operacion y producto
