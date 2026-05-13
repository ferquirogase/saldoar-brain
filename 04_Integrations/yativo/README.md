# Yativo

## Simple Definition
`Yativo` es una integracion de liquidez y ruteo bancario que Saldoar usa para mover parte de los pagos y cobros externos en sistemas bancarios concretos.

No se ve como una feature aislada en front. Se nota indirectamente cuando:

- un pago externo se arma como `payment_link`
- un payout necesita crear beneficiario y cotizacion antes de salir
- un webhook externo cambia el estado interno de una operacion
- ciertos sistemas bancarios se resuelven por gateway y no por una cuenta fija interna

## Why It Matters
Importa porque mete una capa operativa fuerte entre Saldoar y algunos sistemas:

- decide gateways de payin y payout segun pais y moneda
- usa exchange rates y quote ids para concretar operaciones
- puede devolver links de pago en vez de datos fijos
- convierte eventos externos en `PayStatusChangeEvent`
- agrega fallos posibles de balance, firma webhook, mapping y payment data

## Main Product Role
En lo mapeado hasta ahora, `Yativo` cumple cuatro papeles:

1. resolver gateways para ciertos sistemas bancarios
2. crear payins y payouts externos
3. transformar cuentas locales en `payment_data` aceptable por el proveedor
4. escuchar webhooks y traducirlos a cambios internos de pago

## Systems Touched
Los systems mapeados directamente en `YativoGatewayResolver::SYSTEM_MAP` son:

- `banco-mex` -> `MXN`
- `col-bank` -> `COP`
- `nequi` -> `COP`
- `transfer-peru` -> `PEN`
- `transfer-chile` -> `CLP`

Hay una particularidad importante en `COP`:

- `YativoCurrencyToSystem` necesita mirar el `provider_tx_id`
- eso distingue si el evento externo corresponde a `nequi` o `col-bank`
- si no logra resolver, cae por default en `col-bank`

## Main Flows Connected

- `system-specific-branches`
- `accounts-and-destination-selection`
- `notifications-mails-and-background-jobs`

## Main Backend Surface

- `saldo/app/External/Yativo/YativoPayinService.php`
- `saldo/app/External/Yativo/YativoPayoutService.php`
- `saldo/app/External/Yativo/Webhooks/YativoWebhookController.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/YativoLiquidityProvider.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/YativoGateway/YativoGatewayResolver.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/Internals/YativoCurrencyToSystem.php`
- `saldo/app/Transactions/DirectTransfers/GoToPay/PayBehaviourResolver.php`

## Main Frontend Surface
No aparece una pantalla `Yativo` dedicada.

El usuario lo ve a traves de superficies ya existentes, sobre todo:

- instrucciones
- botones de pago o links externos
- cambios de estado posteriores a webhook

## What It Triggers

- seleccion de gateway segun system, currency y method type
- pedido de cotizacion antes de ejecutar payin o payout
- creacion de beneficiario para payout con `payment_data` derivado de la cuenta
- uso de `idempotency_key` en payout
- webhook seguro por firma HMAC en `/webhooks/yativo/notification`
- dispatch de `YativoPayinEvent` y `YativoPayoutEvent`
- conversion a `PayStatusChangeEvent`

## Important Product / Ops Reading

- No todo system bancario usa Yativo. Solo ciertos systems entran en `SYSTEM_MAP`.
- Si la cuenta de destino no tiene los datos que Yativo exige, el payout no sale aunque la cuenta exista en Saldoar.
- En `COP`, un problema de reconciliacion puede no ser solo “Colombia”: hay una bifurcacion real entre `nequi` y `col-bank`.
- En caminos `GoToPay`, si la address resuelta empieza con `http`, el comportamiento visible puede pasar a `LINK`.
- El webhook de `deposit.created` esta muteado; el que realmente mueve la operacion en lo ya mapeado es `deposit.updated`.

## Failure Or Friction Modes

- system no soportado por `SYSTEM_MAP`
- gateway no resoluble para ese pais/moneda/tipo
- `payment_data` invalido o incompleto para payout
- saldo insuficiente del proveedor
- firma webhook invalida o secret faltante
- evento externo sin mapping claro de system
- request exception del proveedor o respuesta parcial

## Questions This Integration Helps Answer

- como decide Saldoar si usa Yativo para cierto sistema
- por que a veces aparece un link para pagar en vez de datos fijos
- que systems de banco/chile/colombia/peru pasan por Yativo
- por que en Colombia a veces cae en Nequi y otras en banco
- que pasa si Yativo no tiene balance
- de donde sale el webhook que cambia un estado externo

## Main References

- `saldo/app/External/Yativo/YativoPayinService.php`
- `saldo/app/External/Yativo/YativoPayoutService.php`
- `saldo/app/External/Yativo/Webhooks/YativoWebhookController.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/YativoLiquidityProvider.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/YativoGateway/YativoGatewayResolver.php`
- `saldo/app/Liquidity/Adapters/Providers/Yativo/Internals/YativoCurrencyToSystem.php`
- `saldo/app/Transactions/DirectTransfers/GoToPay/PayBehaviourResolver.php`

## Evidence Level

- `confirmed`
