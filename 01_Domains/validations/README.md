# Validations

## Purpose
Describir la capa que verifica identidad, titularidad, evidencia y condiciones de riesgo antes o durante el avance del pedido.

## What This Domain Owns
- validaciones de usuario
- validaciones de transaccion
- tipos de validacion y ejemplos
- links publicos de validacion
- biometria
- selfie, ID, screenshot y otros archivos
- estados de aprobacion, pendiente o rechazo

## Core Mental Model
Las validaciones en Saldoar no son un modulo secundario. Son un gate de confianza.

Pueden:
- dejar avanzar
- frenar
- desviar a soporte u operacion
- abrir chat
- cambiar helpers o estados visibles

## Main Backend Surface
Confirmado en `saldo/app/Validations/`:
- `Validations`
- `ValidationTypes`
- `ValidationExamples`
- `UserValidationLinks`
- `Users`
- `Jobs`
- `Events`

Tambien toca fuerte:
- `saldo/app/Transactions/Screenshots/`
- listeners y notifications del dominio `Transactions`

## Main Frontend Surface
Confirmado en:
- `transactions/pages/user-info/upload-document`
- `transactions/pages/user-info/account-details`
- vistas de validacion dentro de transaccion
- dashboard `user-validations-dashboard`

## Main Entities And Concepts
- `Validation`
- `ValidationType`
- `UserValidationLink`
- `File`
- validaciones `USER`
- validaciones `TRANSACTION`

## Key Responsibilities
1. Pedir evidencia cuando el sistema la necesita.
2. Diferenciar validacion de identidad general de validacion atada a un pedido.
3. Revisar documentos, screenshots y biometria.
4. Bloquear, poner en espera o habilitar el avance segun el resultado.

## Flows Anchored In This Domain
- `identity-validations`
- `payment-instructions`
- `accounts-and-destination-selection`
- `public-order-creation-and-identity-bootstrap`
- `notifications-mails-and-background-jobs`

## Important Rules Already Seen
- hay diferencia fuerte entre validaciones `USER` y `TRANSACTION`
- `screenshot` tiene reglas especiales de cantidad y deduplicacion por `md5`
- biometria usa flujo especifico con redirect
- validaciones pueden dispararse desde contexto publico por key y no solo desde dashboard

## Boundaries
Este dominio no "opera" el pedido, pero condiciona casi todos sus avances.

Se conecta especialmente con:
- `transactions`
- `support-and-operations`
- `systems-and-integrations` cuando hay validaciones dependientes de metodo

## UX Reading
- Muchas fricciones no son de formulario sino de confianza y riesgo.
- El usuario puede sentir que esta en una sola tarea, pero backend puede estar cruzando varios chequeos distintos.
- El copy y la secuencia de validaciones impactan fuerte en abandono o confusion.

## Risks
- Si se mira solo la pantalla, es facil no ver por que una validacion aparecio en ese momento.
- Las validaciones viven repartidas entre tipo, estado, archivos, links y contexto publico o autenticado.
- El costo UX de una validacion mal explicada es alto porque pega en dinero y confianza.

## Main References
- `saldo/app/Validations/`
- `saldo/app/Transactions/Screenshots/`
- `solido/apps/solido-app/src/app/transactions/pages/user-info/`
- `solido/apps/solido-app/src/app/dashboard/user-validations-dashboard/`

## Evidence Level
- `confirmed`: estructura principal, tipos y puntos de entrada
- `inferred`: reparto fino de ownership entre validaciones y transacciones
