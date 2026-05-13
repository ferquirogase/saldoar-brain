# State

## Simple Definition
`State` es el registro de cambio de situación de una transacción. Sirve tanto para guardar el estado actual como para construir el historial, el texto visible y parte de la acción operativa asociada.

## Why It Matters
Muchísimas preguntas internas en Saldoar en realidad son preguntas sobre `State`:
- por qué el usuario vio ese mensaje
- cuándo pasó algo
- quién lo disparó
- si fue público o interno
- si abrió tarea o acción

## Core Role
`State` cumple varias funciones al mismo tiempo:
- historial cronológico de lo que fue pasando
- fuente del `state` actual resumido de la transacción
- contenedor de `public_text` y `private_text`
- disparador de tareas, acciones o notificaciones

## Key Attributes To Read First
- `transaction_id`
  A qué transacción pertenece.

- `author_id`
  Quién generó el estado, si hubo autor explícito.

- `state`
  Código resumido del estado.

- `public_text`
  Texto que puede ver el usuario.

- `private_text`
  Texto más interno u operativo.

- `state_chip_id`
  Relación con caminos guiados o acciones sugeridas.

- `state_action_id`
  Acción contextual asociada.

- `state_action_resource_id`
  Recurso vinculado a esa acción.

- `notified`
  Si ya disparó o no notificación.

- `is_public`
  Si el estado queda visible como parte de la experiencia del usuario.

- `state_reason_id`
  Motivo más específico cuando aplica.

## State Enum That Shapes The Product
Visto en `StateEnum`:
- `NONE`
- `CANCELED`
- `TO_NEW_TICKET`
- `TO_FUTURE`
- `TO_FUTURE_READY`
- `HELD_DISPUTED`
- `HELD`
- `WAITING_PAYMENT`
- `CREDITED_PAYMENT`
- `VALIDATION_REQUIRED`
- `SCAMMED`
- `PRE_APPROVED_SENT`
- `SENT`
- `MEDIATION`

Estos códigos ayudan a simplificar la lectura del caso, pero no agotan toda la historia: el detalle real también vive en los textos y acciones del state.

## Main Relationships
- `transaction`
- `author`
- `tasks`
- `files`

## Important Distinctions
- `state` actual de la transacción no es lo mismo que la colección histórica de `states`
- dos transacciones con el mismo `state` numérico pueden verse distintas por `public_text`, chips, helpers o tareas
- un `State` puede ser principalmente informativo o puede cargar bastante lógica operativa

## Main Backend Surface
- `saldo/app/Transactions/States/State.php`
- `saldo/app/Transactions/States/StateEnum.php`
- observers en `saldo/app/Transactions/States/States/`

## Main Frontend Surface
- timeline o historial en `transaction-states`
- mensajes visibles en flujo de pedido
- surfaces que dependen de `public_text`, chips o acciones derivadas

## UX / Support Reading
- Si querés saber "qué le dijimos al usuario", mirá `public_text`.
- Si querés saber "qué estaba pasando internamente", mirá `private_text`.
- Si querés saber "qué cambió y cuándo", mirá la secuencia de `states`.
- Si querés saber "por qué apareció una tarea o acción", mirá `state_action_id` y relaciones asociadas.

## Common Confusions This Entity Solves
- un `State` no es solo una etiqueta de estado
- un `State` no es lo mismo que un helper
- un `State` no es lo mismo que una validation
- el `state` actual resumido no cuenta toda la historia

## Main References
- `saldo/app/Transactions/States/State.php`
- `saldo/app/Transactions/States/StateEnum.php`
- flujos de `02_Flows/`

## Evidence Level
- `confirmed`
