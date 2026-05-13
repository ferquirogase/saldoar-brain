# Kamipay

## Simple Definition
`Kamipay` es la integracion que Saldoar usa principalmente para parte del circuito `PIX`.

No se presenta con marca propia para el usuario. Se expresa como comportamiento del sistema:

- generacion de PIX dinamico
- validacion de clave PIX
- pagos a clave PIX
- actualizacion de estados por webhook

## Why It Matters
Importa porque para `PIX` no alcanza con mostrar una cuenta:

- backend puede crear un `PIX` dinamico con `emv` y `operation_id`
- puede validar si una clave PIX de destino parece legitima antes de operar
- puede retener el pedido si la validacion falla
- depende de rates BRL/USDT y de balance externo del proveedor
- los estados finales pueden entrar por webhook y no por accion humana directa

## Main Product Role
En lo mapeado, `Kamipay` cumple cuatro papeles:

1. crear cobros PIX dinamicos para payin
2. ejecutar payouts a clave PIX
3. validar una clave PIX antes de continuar
4. traducir respuestas externas a `PayStatusChangeEvent`

## Main Flows Connected

- `system-specific-branches`
- `accounts-and-destination-selection`
- `cancellation-held-mediation-recovery`
- `notifications-mails-and-background-jobs`

## Main Backend Surface

- `saldo/app/External/Kamipay/KamipayService.php`
- `saldo/app/External/Kamipay/Webhooks/KamipayWebhookController.php`
- `saldo/app/External/Kamipay/Resources/OracleResource.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayLiquidityProvider.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayLiquidityProviderRates.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayTxToPayTx.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayExternalListener.php`
- `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`

## Main Frontend Surface
No hay una pantalla `Kamipay` dedicada.

La capa visible aparece sobre todo en instrucciones PIX:

- boton para abrir QR PIX
- generacion de imagen QR desde la clave o `emv`
- presentacion del `directTransfer1` cuando `system1` es `pix`

Surface relevante:

- `solido/apps/solido-app/src/ui/pages/instructions/components/qr-pix-button/qr-pix-button.component.ts`
- `solido/apps/solido-app/src/ui/shared/helpers/qr-pix-helper.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1/direct-transfer1-active/direct-transfer1-active.component.html`

## What It Triggers

- `create_dynamic_pix_b2b` para generar un PIX dinamico
- devolucion de `emv`, `operation_id` y `amount_usdt`
- `payToPixKey` para payout
- consulta de oracle para `charge` y `pay` sobre `BRLUSDT`
- cache de rates para no golpear siempre al proveedor
- validacion de clave PIX antes de seguir
- posible `HELD` si la clave no parece valida
- webhook en `/webhooks/kamipay/receive-credentials`
- conversion de webhook a `KamipayTxEvent` y luego a `PayStatusChangeEvent`

## Important Product / Ops Reading

- Cuando el usuario ve QR o flujo especial de `PIX`, no necesariamente es una cuenta estatica; puede venir de `createNewPix`.
- Una clave PIX invalida no siempre rompe con error inmediato: puede empujar la transaccion a `HELD`.
- Si Kamipay no tiene balance, el problema puede aparecer como falla operativa del payout, no como bug de UI.
- `KamipayTxToPayTx` solo convierte ciertos estados (`DONE`, `FAILED`) y tipos (`CHARGE`, `PAY`); estados intermedios pueden no mover nada todavia.
- El webhook usa autenticacion por `X-Kamipay-Auth`, asi que un problema de firma deja a la operacion sin sincronizacion externa.

## Failure Or Friction Modes

- clave PIX invalida y pedido enviado a `HELD`
- webhook no autenticado o mal formado
- `NotEnoughBalanceException` al intentar pagar
- request fallida al crear PIX o payout
- `Tx not found` al consultar estado externo
- fallo al obtener rates del oracle
- desfasaje entre lo que ve el usuario y el estado externo aun no sincronizado

## Questions This Integration Helps Answer

- como funciona PIX en Saldoar
- de donde sale el QR o `emv` de PIX
- por que una clave PIX puede dejar el pedido retenido
- que pasa si Kamipay no tiene balance
- como entra un estado externo de PIX al sistema
- cuando una operacion PIX usa cuenta, QR o link derivado

## Main References

- `saldo/app/External/Kamipay/KamipayService.php`
- `saldo/app/External/Kamipay/Webhooks/KamipayWebhookController.php`
- `saldo/app/External/Kamipay/Resources/OracleResource.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayLiquidityProvider.php`
- `saldo/app/Liquidity/Adapters/Providers/Kamipay/KamipayTxToPayTx.php`
- `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`
- `solido/apps/solido-app/src/ui/pages/instructions/components/qr-pix-button/qr-pix-button.component.ts`
- `solido/apps/solido-app/src/ui/shared/helpers/qr-pix-helper.ts`

## Evidence Level

- `confirmed`
