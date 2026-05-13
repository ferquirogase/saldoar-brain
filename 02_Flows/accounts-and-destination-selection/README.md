# Accounts And Destination Selection

## Metadata

- `flow_id`: `flow-accounts-and-destination-selection`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar selecciona, valida y usa cuentas del usuario y destinos operativos durante la creacion y ejecucion de un pedido.

## Por que importa

Muchisimas fricciones del core nacen aca:

- cuentas obligatorias o no
- cuenta de envio versus cuenta de recepcion
- sistema incompatible con la cuenta elegida
- network incorrecta
- faltan datos extra de la cuenta destino
- destino invalido o que luego necesita cambio

Sin entender esta capa, es dificil interpretar por que un pedido no avanza o por que entra en `HELD`, `TO_FUTURE_READY` o requiere intervencion.

## Entry Points

### Creacion de pedido autenticada

- calculadora privada / dashboard de nueva transaccion

### Creacion publica

- flujo publico que crea usuario/cuenta si hace falta

### Post-creacion / operacion

- busqueda de destinos
- agregado o refill de `directTransfers`
- cambio de cuenta destino
- validaciones especiales como PIX

## Frontstage

### 1. Elegir sistemas y cuentas

En la calculadora privada, el usuario arma la transaccion combinando:

- `system1` y `system2`
- `account1` y `account2`
- monto de envio o recepcion

Cuando cambia sistemas:

- el front puede resetear cuentas
- recalcula montos
- cambia la direccion de operacion `send/receive`
- reevalua requisitos extra

### 2. La network tambien importa

Para sistemas que la usan, el front toma `network_id` desde la cuenta elegida o desde `default_network_id` del sistema.

Ese dato entra en el calculo de montos y fees.

O sea: no alcanza con elegir "crypto". La red concreta cambia el resultado.

### 3. Espera de destinos

Hay una experiencia visible de "buscando destinos" cuando el pedido todavia no tiene los `directTransfers` listos.

Eso muestra que hay una diferencia entre:

- la cuenta elegida por el usuario para cobrar o pagar
- y los destinos operativos que backend termina asignando

### 4. Falta de detalle extra

Aun cuando `account2` exista, algunos sistemas/grupos requieren datos adicionales de cuenta.

Si faltan, el usuario puede ver helpers o bloqueos posteriores aunque ya haya elegido una cuenta.

## Backstage

### 1. Dos tipos de cuenta diferentes

Hay que separar dos niveles:

#### Cuentas del usuario

- `account1`: origen declarado del usuario
- `account2`: destino declarado del usuario

Estas son relaciones de la transaccion con cuentas del usuario.

#### Destinos operativos

- `directTransfers1`
- `directTransfers2`

Estas son las piezas que realmente conectan el pedido con otras operaciones/destinos del sistema.

Una confusion muy comun es pensar que elegir `account2` ya resuelve el destino operativo. No siempre es asi.

### 2. Validacion de cuentas en creacion autenticada

`TransactionWithTokenPolicy` aplica reglas fuertes al crear una transaccion privada:

- `system1` y `system2` son obligatorios y deben ser distintos
- si un sistema requiere cuenta, esa cuenta debe existir
- `account1` y `account2` deben pertenecer al mismo usuario
- la cuenta elegida debe corresponder al sistema correcto

Tambien calcula montos automaticamente salvo ramas especiales como `BALANCE` o `VCC`.

### 3. Creacion publica puede generar usuario y cuentas

`TransactionPublicPolicy` hace algo distinto:

- valida que el par de sistemas exista
- valida montos
- crea o encuentra usuario por email
- crea o encuentra cuentas necesarias segun `account_address` y `account_network`

Eso significa que en flujo publico Saldoar puede materializar identidades y cuentas en el mismo acto de crear el pedido.

### 4. Cuenta requerida depende del sistema

No todos los sistemas exigen cuenta de la misma forma.

Backend usa flags tipo:

- `requirecuenta1`
- `requirecuenta2`

Si el sistema no la requiere, puede limpiar los datos de cuenta y seguir.
Si la requiere, la ausencia de cuenta es error de creacion.

### 5. Network y direccion afectan calculo y validez

En flujo publico, `TransactionPublicPolicy` puede inferir `network_id` desde la address.

En flujo privado, el front recalcula montos segun network seleccionada o default.

Esto es importante porque:

- una misma moneda en distinta red puede dar distinto fee
- una cuenta sin network clara puede romper validaciones o montos

### 6. Account detail requerido para liberar destino

Tener `account2` no siempre alcanza.

`TransactionObserverSetStatusFlags` usa `isAccount2Ready()` para decidir si una transaccion acreditada puede quedar `ready_to_pay`.

Si el grupo del sistema requiere `account_detail_required`:

- debe existir `AccountDetail` para `account2`

Si no existe, el pedido puede quedar trabado antes de salir.

Esto tambien se refleja en UX via `AccountDetailRequiredHelperRepository`.

### 7. Validacion especial de destino

Hay validaciones de destino que ya pueden mandar a `HELD`.

Ejemplo claro:

- `ValidatePixAddressOrHeldUseCase` consulta Kamipay para validar la PIX key
- si no es valida, el pedido pasa a `HELD` con mensaje publico

O sea: una cuenta elegida correctamente a nivel estructural igual puede fallar a nivel operativo real.

### 8. Cambiar destino no es solo editar un campo

`ChangeDestinationAddress` muestra que modificar `account2` puede ser una operacion profunda:

- libera `directTransfers2` si hace falta
- crea o encuentra una nueva cuenta destino
- replica parte del pedido en una nueva transaccion
- ajusta montos remanentes
- puede dejar el pedido viejo en `SENT` o `MEDIATION`
- acredita y notifica el nuevo pedido

Esto indica que un cambio de destino puede partir un flujo en dos pedidos relacionados, no solo "corregir" el existente.

### 9. Agregar destinos operativos no siempre esta permitido

`AddDirectTransfers` puede intentar reponer destinos operativos para ciertos pedidos.

Pero:

- no aplica a pedidos creados con `deals bag`
- depende del estado actual
- si logra matching vuelve a `WAITING_PAYMENT`
- si no, puede mandar a `TO_FUTURE_READY`

Entonces el sistema distingue entre:

- elegir cuenta del usuario
- conseguir destinos operativos
- poder reponer esos destinos mas tarde

## Trazabilidad Tecnica

### Front

- calculadora privada: `solido/apps/solido-app/src/app/dashboard/transactions/new-transaction/transaction-private-calculator/transaction-private-calculator.component.ts`
- espera de destinos: `solido/apps/solido-app/src/app/dashboard/transactions/new-transaction/searching-destinations/searching-destinations.component.html`

### Back

- politica privada: `saldo/app/Transactions/Transactions/TransactionWithTokenPolicy.php`
- politica publica: `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- flags de readiness: `saldo/app/Transactions/Transactions/TransactionObserverSetStatusFlags.php`
- helper de account detail: `saldo/app/Transactions/TransactionHelpers/HelperRepositories/AccountDetailRequiredHelperRepository.php`
- validacion PIX: `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`
- cambio de destino: `saldo/app/Transactions/Actions/ChangeDestinationAddress.php`
- agregar destinos: `saldo/app/Transactions/Actions/AddDirectTransfers.php`

## Reglas de Negocio Detectadas

### Elegir cuenta no equivale a tener destino operativo

`account1/account2` son cuentas del usuario.
`directTransfers` son destinos reales del motor operativo.

### La propiedad de la cuenta importa

En flujo autenticado, las cuentas deben pertenecer al usuario del pedido.

### El sistema de la cuenta importa

Una cuenta puede existir, pero ser invalida para ese `system1` o `system2`.

### La network puede cambiar el comportamiento economico

No es solo dato descriptivo; entra en calculo.

### Algunos sistemas necesitan detalle extra para pagar realmente

La cuenta puede estar elegida, pero si faltan `AccountDetail`, el pedido no queda listo.

### Cambiar destino puede rehacer el flujo

No siempre se edita el pedido existente; a veces se crea otro y se redistribuye el remanente.

## Lo que este flujo ya permite responder

- Que diferencia hay entre cuenta del usuario y destino operativo.
- Cuando una cuenta es obligatoria y cuando no.
- Por que una cuenta puede ser rechazada aunque exista.
- Como impacta la network en montos y validaciones.
- Por que un pedido acreditado todavia puede no estar listo para salir.
- Por que cambiar destino puede generar un nuevo pedido o una mediacion.

## Edge Cases / Riesgos

- Hay ramas publicas y privadas que modelan cuentas de forma distinta.
- Un pedido puede tener cuenta correcta pero seguir sin destinos operativos.
- Sistemas con `account_detail_required` agregan una segunda barrera despues de seleccionar cuenta.
- Validaciones externas como PIX pueden mandar a `HELD` bastante tarde en el flujo.
- Cambiar destino puede ser dificil de explicar si no se entiende que puede partir la operacion en dos.

## Unknowns

- Mapear mas fino la capa de `AccountDetail` por sistema/grupo.
- Documentar mejor como se construyen y eligen `directTransfers2`.
- Integrar la capa de balances cuando esa funcionalidad este activa para usuarios.
- Ver mas en detalle los componentes UI de seleccion de cuenta fuera de la calculadora principal.

## Fuentes

- `solido/apps/solido-app/src/app/dashboard/transactions/new-transaction/transaction-private-calculator/transaction-private-calculator.component.ts`
- `solido/apps/solido-app/src/app/dashboard/transactions/new-transaction/searching-destinations/searching-destinations.component.html`
- `saldo/app/Transactions/Transactions/TransactionWithTokenPolicy.php`
- `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- `saldo/app/Transactions/Transactions/TransactionObserverSetStatusFlags.php`
- `saldo/app/Transactions/TransactionHelpers/HelperRepositories/AccountDetailRequiredHelperRepository.php`
- `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`
- `saldo/app/Transactions/Actions/ChangeDestinationAddress.php`
- `saldo/app/Transactions/Actions/AddDirectTransfers.php`
