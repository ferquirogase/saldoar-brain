# Task

## Simple Definition
`Task` es la entidad que representa trabajo operativo pendiente o realizado sobre un caso, normalmente asociado a un `State`.

## Why It Matters
`Task` marca un cambio importante en el producto: el caso deja de depender solo de lógica automática y pasa a requerir atención humana, asignación o seguimiento.

Ayuda a responder:
- qué caso necesita operador
- quién lo tiene asignado
- desde cuándo está pendiente
- si ya se completó
- qué tipo de intervención se esperaba

## Core Role
`Task` no describe el pedido entero ni el cambio de estado en sí. Describe el trabajo operativo que nace a partir de eso.

Normalmente:
- un `State` expresa la situación
- una `Task` expresa el trabajo que alguien tiene que hacer con esa situación

## Key Attributes To Read First
- `state_id`
  Estado del cual nace la tarea.

- `author_user_id`
  Quién la creó.

- `assigned_user_id`
  A qué operador o usuario interno quedó asignada.

- `priority`
  Qué urgencia tiene.

- `since`
  Desde cuándo se considera pendiente o activa.

- `completed`
  Si ya se resolvió o no.

- `created_at`
  Cuándo se creó.

## Main Relationships
- `state`
- `authorUser`
- `assignedUser`

## Important Related Config: TaskTypesEnum
`TaskTypesEnum` define varios tipos operativos relevantes, por ejemplo:
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

Cada tipo no es solo una etiqueta: también define:
- estado objetivo
- acciones encadenadas que pueden ejecutarse

Eso hace que `Task` sea una puerta de entrada a pipelines manuales reales.

## Important Distinctions
- `Task` no es lo mismo que `State`.
- `Task` no es lo mismo que `Validation`.
- `Task` no es lo mismo que un helper o chip.
- una tarea puede estar asociada al mismo caso que otras tareas, pero con distinta prioridad, asignación o momento.

## Main Backend Surface
- `saldo/app/Transactions/Tasks/Task.php`
- `saldo/app/Transactions/Tasks/TaskTypesEnum.php`
- `saldo/app/Users/Operators/OperatorTaskHelper.php`
- `saldo/app/Transactions/Helpers/StatesAndTasks/TransactionStateHelper.php`

## Main Frontend Surface
No aparece como entidad de usuario final típica, pero se ve reflejada en:
- atención operativa del caso
- ownership interno
- cambios de estado, mensajes y tiempos de respuesta
- panel y capa de operación

En front público o privado normalmente se percibe por sus efectos, no por un CRUD explícito de `Task`.

## Common Questions This Entity Answers
- quién está llevando este caso
- por qué el caso quedó esperando a un operador
- qué intervención manual se esperaba
- si una tarea fue reasignada o liberada
- por qué hubo una acción de cancelación, mediación, resize o recovery

## UX / Support Reading
- Si el usuario siente que “alguien lo está viendo”, eso suele vivir en la capa de `Task`.
- Si querés entender la carga operativa de un flujo, mirá cuántas tareas genera.
- Si querés entender por qué un caso quedó frenado sin explicación de UI, mirá si abrió tarea.

## Main References
- `saldo/app/Transactions/Tasks/Task.php`
- `saldo/app/Transactions/Tasks/TaskTypesEnum.php`
- `saldo/app/Users/Operators/OperatorTaskHelper.php`
- `saldo/app/Transactions/Helpers/StatesAndTasks/TransactionStateHelper.php`
- flujos de `chat-state-chips-and-support-actions`, `operator-interventions-and-panel-actions`, `cancellation-held-mediation-recovery`

## Evidence Level
- `confirmed`
