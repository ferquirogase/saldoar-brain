# Account

## Simple Definition
`Account` es la entidad base que representa la cuenta, dirección o identificador operativo con el que un usuario envía o recibe saldo en un sistema determinado.

## Why It Matters
Muchas preguntas del producto parecen sobre transacciones, pero en realidad son sobre cuentas:
- qué cuenta está usando el usuario
- si esa cuenta ya existía
- si pertenece a ese usuario
- si necesita red
- si necesita datos adicionales
- si sirve como origen o destino real

## Core Role
`Account` funciona como identificador operativo reusable.

Puede representar, por ejemplo:
- mail
- alias
- wallet
- clave PIX
- cuenta bancaria
- identificador de cuenta digital

Y después puede enriquecerse con `AccountDetail` cuando el sistema lo necesita.

## Key Attributes To Read First
- `user_id`
  Dueño de la cuenta.

- `system_id`
  Sistema al que pertenece.

- `network_id`
  Red asociada cuando aplica, especialmente en crypto.

- `address`
  Identificador principal de la cuenta.

- `alias`
  Nombre corto o etiqueta.

- `status`
  Estado operativo de la cuenta.

- `balance`
  Saldo asociado cuando aplica.

## Important Related Entity: AccountDetail
`Account` no siempre alcanza por sí sola.

`AccountDetail` guarda metadata adicional, por ejemplo:
- `holder_name`
- `identification_number`
- `bank_id`
- `bank_account_type_id`
- `account_number`
- `bank_name`

Entonces:
- `Account` = cuenta base
- `AccountDetail` = datos complementarios para poder operar correctamente

## Main Relationships
- `user`
- `system`
- `network`
- `accountDetail`
- `agreements`
- `accountEntries`
- `metas`

## Important Distinctions
- `Account` no es lo mismo que `AccountDetail`.
- `Account` no es lo mismo que `DirectTransfer`.
- `Account` no es lo mismo que `agreement`.
- `account1` y `account2` en transacción no son entidades nuevas: son roles que toma una `Account`.

## Main Backend Surface
- `saldo/app/Accounts/Accounts/Account.php`
- `saldo/app/Accounts/AccountDetails/AccountDetail.php`
- `saldo/app/Accounts/Accounts/AccountSchema.php`
- observers y validators dentro de `saldo/app/Accounts/`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/account.ts`
- dashboard de cuentas
- formularios de alta/edición de cuenta
- vistas de `account-details`
- formularios públicos o privados de creación de pedido

## Common Questions This Entity Answers
- qué cuenta exacta usó el usuario
- si la cuenta ya estaba guardada o se creó en ese momento
- si la cuenta tiene red asociada
- si faltan datos complementarios para operarla
- si esa cuenta participa en agreements o en transacciones previas

## UX / Support Reading
- Si el usuario dice “ya cargué mi cuenta”, eso puede referirse solo a `Account`, no necesariamente a `AccountDetail`.
- Si el sistema sigue pidiendo datos después de tener cuenta, probablemente falte `AccountDetail`.
- Si hay confusión con destino, titularidad o red, mirá `Account` antes de mirar la transacción completa.

## Main References
- `saldo/app/Accounts/Accounts/Account.php`
- `saldo/app/Accounts/AccountDetails/AccountDetail.php`
- `saldo/app/Accounts/Accounts/AccountSchema.php`
- `solido/apps/solido-app/src/app/core/resources/account.ts`
- `01_Domains/accounts`

## Evidence Level
- `confirmed`
