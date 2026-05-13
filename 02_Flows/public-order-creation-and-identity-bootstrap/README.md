# Public Order Creation And Identity Bootstrap

## Purpose
Explicar como Saldoar permite iniciar y continuar un pedido sin login tradicional, usando contexto publico por `transaction key` o `user key`, y como en ese proceso puede crear o reutilizar usuario, cuentas y datos operativos.

## Why This Flow Matters
- Es una de las diferencias mas importantes entre Saldoar y un producto con cuenta tradicional.
- Afecta onboarding, soporte, validaciones, instrucciones y visibilidad del pedido.
- Si no se entiende este flujo, es facil asumir que "usuario logueado" y "usuario identificado" son lo mismo, y en Saldoar no siempre lo son.

## Core Idea
Saldoar tiene al menos tres contextos distintos para operar:

1. `Authenticated dashboard`
   Usuario autenticado de forma tradicional en el producto.

2. `Public transaction context`
   Acceso por `transaction_mid` + `transaction_key` a una transaccion puntual.

3. `User key context`
   Acceso por `user_id` + `user_key` a recursos del usuario sin login de dashboard.

La identidad no siempre se construye a partir de una sesion. En muchos casos se construye desde el propio pedido.

## Public Creation Path
En creacion publica, backend aplica `TransactionPublicPolicy`.

Ese camino:
- valida sistemas origen/destino y montos
- puede inferir `network` a partir de la direccion
- normaliza email y telefono
- crea o reutiliza `UserX` por email
- asigna `user_id` a la transaccion
- crea o reutiliza `account1` y `account2` si el sistema las requiere
- guarda meta de origen y referral

Esto significa que una operacion publica puede materializar varias piezas de identidad y operacion en un solo paso:
- usuario
- cuentas
- pedido

## Public Context By Transaction Key
El grupo `v3/t` usa middleware de transaccion.

Ese middleware:
- busca la transaccion por `transaction_mid`
- valida la key
- verifica que el usuario pueda verla
- inyecta la transaccion en el contexto request

Desde ahi, frontend o agentes pueden consultar recursos ligados a esa transaccion, por ejemplo:
- transaccion
- estados
- `directTransfers1`
- `directTransfers2`
- validaciones
- archivos
- `transaction_helpers`
- redirect URLs de instrucciones

La clave es que no se abre un contexto global de usuario. Se abre un contexto limitado a esa operacion.

## User Key Context
El grupo `v3/u` usa middleware de usuario.

Ese middleware:
- valida `user_id` + `user_key`
- resuelve al usuario
- lo fija como usuario actual

Ese contexto habilita recursos mas amplios que el de una sola transaccion, por ejemplo:
- cuentas del usuario
- `account_details`
- validaciones del usuario
- biometria
- archivos
- links o instrucciones relacionadas

Es un acceso sin login tradicional, pero mas amplio que el de una unica transaccion.

## Difference With Authenticated Creation
En creacion autenticada se usa `TransactionWithTokenPolicy`.

Ese camino se apoya mas en:
- usuario ya identificado
- ownership de cuentas
- compatibilidad entre cuenta y sistema
- requerimientos de telefono
- reglas privadas del dashboard

Entonces no conviene tratar la creacion publica y la autenticada como variantes cosmeticas del mismo flujo. Comparten resultado de negocio, pero no arrancan desde la misma base de identidad.

## Account And Account Detail Scope
En contexto publico por transaccion, las cuentas y detalles no quedan abiertos libremente.

Reglas importantes:
- `AccountSchema` restringe cuentas visibles/editables a `account1_id` y `account2_id` de la transaccion si el contexto actual es transaccional
- `AccountDetailPolicy` permite crear detalle solo para las cuentas ligadas a esa transaccion
- en contexto de usuario por key, el alcance pasa a las cuentas del usuario

Esto ayuda a que el acceso por key sea util pero acotado.

## UX And Product Implications
- El usuario puede entrar al sistema por una operacion, no por una cuenta.
- Parte del onboarding ocurre dentro del flujo transaccional.
- "Tengo acceso" no siempre significa "estoy logueado".
- Un mismo email puede reusar identidad previa aunque el usuario sienta que esta empezando de cero.
- Muchas consultas de soporte sobre "como entro", "por que veo esto", o "por que ya tenia datos cargados" dependen de esta logica.

## Connected Flows
- `create-transaction-and-next-step`
- `payment-instructions`
- `identity-validations`
- `transaction-visibility-and-status`
- `accounts-and-destination-selection`

## Important Risks Or Edge Cases
- Reusar usuario por email puede generar continuidad de identidad que el usuario no siempre percibe.
- La creacion publica puede crear cuentas operativas antes de que el usuario entienda del todo el alcance.
- El acceso por key es muy potente para continuidad de flujo, pero hay que pensar bien que recursos quedan expuestos en cada contexto.
- Si se analiza solo el front, este comportamiento puede pasar desapercibido porque mucho se resuelve en politicas y middleware de backend.

## What This Flow Explains Internally
- por que alguien puede continuar un pedido sin login clasico
- por que una transaccion publica igual tiene usuario asociado
- por que algunas cuentas aparecen o ya existen
- por que algunos formularios o recursos se pueden editar solo dentro del pedido puntual

## Open Questions
- No quedo cerrada toda la superficie exacta del front que emite y consume estos accesos por key.
- No quedo completamente trazado el lifecycle de emision/rotacion de todas las keys.
- Puede haber variantes historicas o legacy fuera de `v3/t` y `v3/u` que no se mapearon en este flujo.

## Main References
- `saldo/routes/api.php`
- `saldo/app/Http/Controllers/JsonApiTransactionController.php`
- `saldo/app/Http/Controllers/JsonApiUserController.php`
- `saldo/app/Transactions/Http/TransactionCheckKeyAndStateV3Middleware.php`
- `saldo/app/Users/Http/CheckUserKeyV3Middleware.php`
- `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- `saldo/app/Transactions/Transactions/TransactionWithTokenPolicy.php`
- `saldo/app/Accounts/Accounts/AccountSchema.php`
- `saldo/app/Accounts/AccountDetails/AccountDetailPolicy.php`
