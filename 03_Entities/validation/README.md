# Validation

## Simple Definition
`Validation` es la entidad que registra un requisito de verificación, evidencia o revisión aplicado a un usuario o a una transacción.

## Why It Matters
Muchas fricciones de Saldoar no son problemas de UI ni de estado puro. Son problemas de confianza y revisión, y eso vive en `Validation`.

Esta entidad ayuda a responder:
- qué se pidió exactamente
- a quién se le pidió
- en qué estado está esa revisión
- qué archivos o evidencia se asociaron
- si bloquea, deja avanzar o cambia el rumbo del pedido

## Core Role
`Validation` actúa como una capa de control sobre un `validable`.

Ese `validable` puede ser:
- `User`
- `Transaction`

Por eso una validation puede ser:
- general de identidad o perfil
- puntual de un pedido específico

## Key Attributes To Read First
- `validable_type`
  A qué tipo de objeto pertenece.

- `validable_id`
  A qué usuario o transacción puntual pertenece.

- `validation_type_id`
  Qué tipo de chequeo es.

- `status`
  Estado de esa revisión.

- `score`
  Señal de evaluación cuando aplica.

- `observations`
  Texto visible o semivisible de observación.

- `private_observations`
  Observación más interna.

- `author_user_id`
  Quién la generó o evaluó cuando hay autor explícito.

- `created_at`
  Cuándo se creó esa instancia de revisión.

## Important Related Entity: ValidationType
`ValidationType` define el tipo de chequeo y varias reglas de comportamiento, por ejemplo:
- `validable_type`
- `title`
- `important`
- `can_be_rejected`
- `can_be_requested`
- `is_public`
- `has_files`
- `min_quantity`

O sea: `Validation` es la instancia concreta, `ValidationType` es la definición del tipo.

## Status Reading
En código aparecen estados como:
- `none`
- `requested`
- `processing`
- `pending`
- `pre_approved`
- `approved`
- `rejected`
- `disqualified`
- `skipped`
- `expired`

Además, para usuario final algunos estados se simplifican:
- `processing` y `pending` pueden verse como pendiente
- `pre_approved` y `approved` pueden verse como aprobado
- `rejected`, `disqualified` y `skipped` pueden caer en rechazado

## Main Relationships
- `validable`
- `validationType`
- `authorUser`
- `files`
- `metas`

## Important Distinctions
- `Validation` no es lo mismo que `State`.
- `Validation` no es lo mismo que `File`.
- `Validation` no es lo mismo que un helper o un chip.
- un usuario puede tener validaciones propias y, además, una transacción puede tener validaciones específicas.

## Main Backend Surface
- `saldo/app/Validations/Validations/Validation.php`
- `saldo/app/Validations/ValidationTypes/ValidationType.php`
- `saldo/app/Validations/Validations/ValidationPolicy.php`
- `saldo/app/Validations/Validations/ValidationStatusEnum.php`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/validation.ts`
- vistas de upload de documentos
- flujo de screenshots
- surfaces de state chat o links a validación
- dashboard de validaciones

## Common Questions This Entity Answers
- por qué apareció este requisito
- si el requisito era del usuario o del pedido
- si la revisión está pendiente o ya aprobada
- qué archivos le corresponden
- por qué el pedido no puede avanzar todavía

## UX / Support Reading
- Si la duda es “qué nos falta pedir o revisar”, mirá `Validation`.
- Si la duda es “de quién es este requisito”, mirá `validable_type` y `validable_id`.
- Si la duda es “qué tipo de prueba espera el sistema”, mirá `validation_type_id` y `ValidationType`.
- Si la duda es “qué evidencia ya subió”, mirá su relación con `files`.

## Main References
- `saldo/app/Validations/Validations/Validation.php`
- `saldo/app/Validations/ValidationTypes/ValidationType.php`
- `saldo/app/Validations/Validations/ValidationPolicy.php`
- `solido/apps/solido-app/src/app/core/resources/validation.ts`
- flujos de `identity-validations` y `payment-instructions`

## Evidence Level
- `confirmed`
