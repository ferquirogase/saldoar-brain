# Users

## Purpose
Describir la capa de identidad y perfil de usuario de Saldoar: como se crea o reutiliza, como se accede, que nivel o riesgo tiene y como eso impacta en reglas del producto.

## What This Domain Owns
- entidad principal `UserX`
- autenticacion y acceso
- `user key` y acceso sin login tradicional
- nivel, `level_power` y progresion
- `flag_level` y riesgo
- metadata y perfil
- actividad, liveness y trazas de acceso
- referrals, audiences y segmentos
- datos fiscales y auxiliares del perfil

## Core Mental Model
En Saldoar, el usuario no es solo un login.

Es una identidad operativa que:
- puede crearse desde registro clasico o desde un pedido publico
- puede reutilizarse por email
- tiene nivel y reputacion operativa
- tiene indicadores de riesgo
- cambia reglas de limites, tiempos y acceso a beneficios

Por eso el usuario afecta directamente la experiencia del producto.

## Main Backend Surface
Confirmado en `saldo/app/Users/`:
- `UserX`
- `Auth`
- `Http`
- `Users`
- `Roles`
- `Notifications`
- `Activity`
- `FlagLevels`
- `AccumulatedRisk`
- `Referrals`
- `Audiences`
- `UsersInfo`
- `UserMetadata`
- `UserFiscalData`
- `UsersHistoricalLevel`

Tambien se conecta con:
- `Transactions/UserExperience`
- middleware de acceso por key
- observers y commands que recalculan nivel o mergean usuarios

## Main Frontend Surface
Confirmado en:
- dashboard `my-profile`
- componentes de `profile-info`
- recursos `user`, `user-info`, `user-historical-level`, `user-fiscal-data`
- estado global de dashboard con `level`

## Main Entities And Concepts
- `UserX`
- `UserInfo`
- `UserMetadata`
- `UserFiscalData`
- `UserHistoricalLevel`
- `level`
- `level_power`
- `flag_level`
- `user_key`

## Key Responsibilities
1. Representar la identidad base del cliente dentro de Saldoar.
2. Permitir acceso autenticado o acceso por key segun contexto.
3. Registrar progresion y confianza operativa mediante `level` y `level_power`.
4. Registrar riesgo o restricciones mediante `flag_level` y mecanismos de accumulated risk.
5. Sostener datos de perfil, fiscales, referral y segmentacion.

## Important Rules Already Seen
- la creacion publica de transaccion puede crear o reutilizar usuario por email
- existe contexto `user key` con `CheckUserKeyV3Middleware` y `UserKeyV3Manager`
- cambiar email puede disparar merge fuerte de usuarios, cuentas, transacciones, metadata y validaciones
- el `level` del usuario impacta reglas reales:
  - maximo de operaciones pendientes
  - limite de operaciones por semana
  - acceso a deals
  - tiempos de espera
  - comportamiento de ciertos procesadores o revisiones
- `flag_level` y accumulated risk afectan decisiones de seguridad

## Flows Anchored In This Domain
- `public-order-creation-and-identity-bootstrap`
- `identity-validations`
- `deals-and-direct-transfer-matching`
- `concurrent-orders-and-omitted-transactions`
- `notifications-mails-and-background-jobs`
- `system-specific-branches`

## Boundaries
Este dominio no "posee" el pedido, pero influye fuertemente en:
- confianza
- limites
- beneficios
- accesos
- riesgo
- continuidad de identidad

Se conecta especialmente con:
- `transactions`
- `validations`
- `accounts`
- `support-and-operations`

## UX Reading
- Muchas diferencias entre usuarios no son meramente cosmeticas: cambian reglas del producto.
- El usuario puede sentir que esta "empezando de cero", pero backend puede estar reusando identidad previa.
- Nivel, confianza y riesgo son variables de experiencia, no solo de backoffice.

## Risks
- Si se trata al usuario como una cuenta plana, se pierde la logica de nivel, riesgo y merge de identidad.
- Hay bastante logica repartida entre observers, commands, middleware y servicios.
- Parte de la experiencia futura puede depender de metadata o audiencias que no son visibles desde la UI principal.

## Main References
- `saldo/app/Users/`
- `saldo/app/Transactions/UserExperience/`
- `saldo/app/Users/Http/CheckUserKeyV3Middleware.php`
- `saldo/app/Users/UserKeyV3Manager.php`
- `saldo/app/Users/Users/UseCases/UpdateEmail.php`
- `solido/apps/solido-app/src/app/dashboard/my-profile/`
- `solido/apps/solido-app/src/app/core/resources/user.ts`
- `solido/apps/solido-app/src/app/core/resources/user-info.ts`

## Evidence Level
- `confirmed`: estructura principal, nivel, riesgo, acceso por key y merge de usuario
- `inferred`: uso exacto de algunas audiencias o metadata en decisiones de producto
