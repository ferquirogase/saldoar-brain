# Accounts

## Purpose
Describir la capa que modela las cuentas con las que el usuario envia o recibe saldo, sus detalles complementarios, sus validadores y sus restricciones de uso dentro del producto.

## What This Domain Owns
- cuentas de usuario (`Account`)
- detalles complementarios (`AccountDetail`)
- direcciones operativas y cripto (`Address`)
- validadores por tipo de cuenta
- banks y tipos de cuenta bancaria
- networks ligadas a cuentas crypto
- reglas de ownership y alcance segun contexto

## Core Mental Model
En Saldoar, una cuenta no es solo un campo de texto.

Una cuenta puede ser:
- origen del envio
- destino del cobro
- una cuenta reusable del usuario
- una cuenta creada en el momento durante un pedido publico
- una cuenta que todavia necesita `AccountDetail` para quedar lista

Por eso conviene separar tres cosas:
- `Account`: identificador operativo base, por ejemplo mail, alias, wallet, cuenta bancaria o clave PIX
- `AccountDetail`: metadata adicional requerida para algunos grupos, por ejemplo titularidad, banco, identificacion o tipo
- `Address`: direcciones auxiliares, especialmente visibles en flujos crypto

## Main Backend Surface
Confirmado en `saldo/app/Accounts/`:
- `Accounts`
- `AccountDetails`
- `Addresses`
- `Banks`
- `BankAccountTypes`
- `Validators`
- `SaldoCryptoAddresses`

Tambien se conecta mucho con:
- `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- `saldo/app/Transactions/Transactions/TransactionWithTokenPolicy.php`
- `saldo/app/Transactions/TransactionHelpers/HelperRepositories/AccountDetailRequiredHelperRepository.php`

## Main Frontend Surface
Confirmado en:
- `dashboard/accounts`
- `transactions/pages/user-info/account-details`
- selectores de cuenta en creacion privada
- validadores de cuenta por tipo en `core/account-service-provider`

## Main Entities And Concepts
- `Account`
- `AccountDetail`
- `Address`
- `Bank`
- `BankAccountType`
- validator por `account_type`
- `network_id`
- `account1` y `account2` como roles dentro de la transaccion

## Key Responsibilities
1. Representar la cuenta base con la que el usuario envia o recibe.
2. Validar formato y consistencia segun sistema.
3. Pedir metadata extra cuando el grupo del sistema lo requiere.
4. Restringir que cuentas o detalles puede ver o editar una persona segun si esta en dashboard, user key o transaction key.
5. Permitir reutilizacion de cuentas existentes o creacion en caliente durante la operacion.

## Important Rules Already Seen
- `account1` y `account2` no son entidades distintas: son roles de una `Account` dentro de una transaccion
- `TransactionPublicPolicy` puede crear o reutilizar cuentas automaticamente en creacion publica
- `TransactionWithTokenPolicy` se apoya mas en ownership de cuentas preexistentes
- `AccountSchema` en contexto transaccional restringe visibilidad a las cuentas ligadas a `account1_id` y `account2_id`
- `AccountDetailPolicy` hace lo mismo para detalles de cuenta
- si el grupo del sistema exige `account_detail_required`, la transaccion puede no quedar lista hasta completar esos datos
- `ValidatePixAddressOrHeldUseCase` muestra que algunas cuentas destino no solo se validan por formato, sino por chequeo externo

## Flows Anchored In This Domain
- `accounts-and-destination-selection`
- `public-order-creation-and-identity-bootstrap`
- `payment-instructions`
- `identity-validations`
- `system-specific-branches`

## Boundaries
Este dominio no define por si solo el pedido, pero condiciona:
- que se puede crear
- que se puede cobrar
- que informacion falta para operar
- si un destino puede usarse o requiere revision

Se conecta fuerte con:
- `transactions`
- `validations`
- `systems-and-integrations`

## UX Reading
- Muchas fricciones del producto en realidad son fricciones de cuenta, no del pedido.
- Para el usuario, "ya puse mi cuenta" puede significar cosas muy distintas segun sistema.
- El hecho de que una cuenta exista no implica que este operativamente lista.
- Las diferencias entre `Account` y `AccountDetail` son importantes para soporte y para diseño de copy.

## Risks
- Si se simplifica demasiado este dominio, se mezclan problemas de formato, ownership, red y titularidad como si fueran uno solo.
- La creacion publica puede hacer parecer que la cuenta "ya existia" o que el sistema la recordo, cuando en realidad fue creada o reutilizada por policy.
- Parte de la logica vive en observers, helpers y policies, no solo en formularios.

## Main References
- `saldo/app/Accounts/`
- `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- `saldo/app/Transactions/Transactions/TransactionWithTokenPolicy.php`
- `saldo/app/Transactions/TransactionHelpers/HelperRepositories/AccountDetailRequiredHelperRepository.php`
- `solido/apps/solido-app/src/app/dashboard/accounts/`
- `solido/apps/solido-app/src/app/transactions/pages/user-info/account-details/`
- `solido/apps/solido-app/src/app/core/account-service-provider/`

## Evidence Level
- `confirmed`: estructura del dominio, entidades, restricciones y validadores principales
- `inferred`: algunos bordes con users o agreements
