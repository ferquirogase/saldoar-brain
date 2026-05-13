# User

## Simple Definition
`User` es la entidad de identidad principal del cliente dentro de Saldoar. No solo representa quién es, sino también su nivel, riesgo, historial operativo y relaciones con cuentas, transacciones y validaciones.

## Why It Matters
En Saldoar, dos usuarios distintos pueden recibir reglas distintas aunque hagan la misma acción. Eso pasa porque `User` arrastra señales de confianza, experiencia y riesgo que alteran el producto.

## Core Role
`User` no es solo login o perfil.

También concentra:
- nivel operativo
- riesgo
- balances y referral
- acceso por key
- historial de actividad
- vínculo con cuentas, transacciones y validaciones

## Key Attributes To Read First
- `id`
  Identificador del usuario.

- `email`
  Correo principal y punto fuerte de continuidad de identidad.

- `name`
  Nombre visible.

- `alias`
  Alias interno o de presentación.

- `phone_number`
  Teléfono normalizado del usuario.

- `level`
  Nivel resumido del usuario dentro del producto.

- `level_power`
  Señal más fina de progresión/confianza.

- `flag_level`
  Riesgo o nivel de alerta.

- `isoperator`
  Distingue operador interno de cliente final.

- `has_balance`
  Señal de capacidades o features disponibles.

- `referral_balance`
  Saldo de referidos.

- `activation_code`
  Señal de activación/continuidad en algunos flujos.

## Main Relationships
- `transactions`
- `accounts`
- `validations`
- `dealsBags`
- `dealsAlerts`
- `referralTransactions`
- `userFiscalData`
- `userMetadata`
- `userHistoricalLevels`
- `userPicture`
- `ips`

## Important Distinctions
- `User` no es lo mismo que `UserInfo`.
- `User` no es lo mismo que `UserMetadata`.
- `User` no es lo mismo que `Account`.
- un usuario puede ser cliente u operador (`isoperator`), y esa diferencia cambia bastante el sistema.

## Main Backend Surface
- `saldo/app/Users/UserX.php`
- `saldo/app/Users/UserKeyV3Manager.php`
- `saldo/app/Users/`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/user.ts`
- `solido/apps/solido-app/src/app/core/resources/user-info.ts`
- dashboard de perfil
- componentes de profile info

## Common Questions This Entity Answers
- por qué este usuario tiene más o menos restricciones
- si el sistema lo considera de más confianza
- si hay riesgo o flag asociado
- si ya tenía historial previo
- si tiene cuentas, transacciones o validaciones previas

## UX / Support Reading
- Si una diferencia entre usuarios cambia el comportamiento, mirá `level`, `level_power` y `flag_level`.
- Si querés entender continuidad de identidad, mirá `email`, `activation_code` y acceso por key.
- Si querés entender si algo pertenece a cliente o a operación interna, mirá `isoperator`.

## Main References
- `saldo/app/Users/UserX.php`
- `saldo/app/Users/UserKeyV3Manager.php`
- `solido/apps/solido-app/src/app/core/resources/user.ts`
- `solido/apps/solido-app/src/app/core/resources/user-info.ts`
- `01_Domains/users`

## Evidence Level
- `confirmed`
