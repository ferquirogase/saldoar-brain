# Agreements

## Purpose
Describir la capa de `agreements`: cuentas o acuerdos operativos que permiten que una transaccion no dependa solo de `directTransfers`, sino de una ruta de pago o cobro mas cerrada.

## What This Domain Owns
- entidad `Agreement`
- asociacion entre agreement y cuenta operativa
- fees del agreement
- habilitacion por sentido (`enabled1`, `enabled2`)
- processors de agreement
- sincronizacion entre transaccion y agreement
- tooling interno y panel para administrar agreements

## Core Mental Model
Un `agreement` es una capacidad operativa prearmada.

Cuando una transaccion entra por agreement:
- cambia la forma de pagar o cobrar
- puede cambiar el tipo de instrucciones
- cambia como se evalua si esta lista para acreditar
- cambia que fees aplican
- puede apoyarse en cuentas o providers ya preparados

Entonces no conviene pensar agreement como "una cuenta más". Es una ruta operativa.

## Main Backend Surface
Confirmado en `saldo/app/Agreements/`:
- `Agreement`
- `AgreementObserver`
- `AgreementPanelRepository`
- `Processors`
- `SyncTransactionWithAgreementsJob`
- `UpdateAgreementAccountJob`
- `CryptoAgreementHelper`
- `AssignAddressToCryptoAgreementListener`

Tambien se conecta mucho con:
- `Transactions/Jobs/TransactionNextStepUseCase.php`
- `Transactions/Transactions/TransactionAgreementObserver.php`
- `Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotifications/TransactionToAgreementNotification.php`
- panel y Filament de agreements

## Main Frontend Surface
No aparece como modulo de usuario final separado, pero impacta directamente:
- instrucciones del pedido
- waiting payment
- estados y notificaciones
- QR o metodos especiales

En front ya se ve al menos por:
- `transaction.attributes.agreement1_id`
- bifurcacion de instrucciones entre agreement y direct transfers

## Main Entities And Concepts
- `Agreement`
- `agreement1_id`
- `agreement2_id`
- `agreement1_fee`
- `agreement2_fee`
- processor de agreement
- account del agreement

## Key Responsibilities
1. Representar acuerdos operativos reutilizables sobre cuentas o providers.
2. Permitir que `TransactionNextStepUseCase` matchee una transaccion con una ruta de agreement.
3. Aportar fees y estado operativo al circuito.
4. Sincronizar movimientos o entries asociados.
5. Cambiar la forma en que el usuario recibe instrucciones y la forma en que el sistema acredita o envía.

## Important Rules Already Seen
- la primera gran bifurcacion de waiting payment es `agreement1_id > 0` vs `directTransfers`
- `TransactionNextStepUseCase` intenta matchear agreement antes de seguir otros caminos
- el agreement define un `processor`, no solo una cuenta
- `TransactionEvaluator` usa una lógica propia para `isReadyForCreditBasedOnAgreement`
- `agreement1_fee` y `agreement2_fee` impactan comisiones registradas
- hay agreements tambien del lado de salida (`agreement2_id`)
- algunos caminos crypto usan `CryptoAgreementHelper` para resolver direcciones o cuentas del agreement
- Liquidity providers tambien pueden terminar bajando un `agreement_id` sobre la transaccion

## Flows Anchored In This Domain
- `payment-instructions`
- `create-transaction-and-next-step`
- `deals-and-direct-transfer-matching`
- `notifications-mails-and-background-jobs`
- `system-specific-branches`

## Boundaries
Este dominio no reemplaza a `transactions` ni a `systems`, pero se monta sobre ambos.

Se conecta fuerte con:
- `transactions`
- `systems-and-integrations`
- `accounts`
- `support-and-operations`

## UX Reading
- Para el usuario, muchas veces no es visible que el pedido fue por agreement.
- Pero eso cambia muchísimo la experiencia: QR, instrucciones más cerradas, menos dependencia de transferencias manuales, otra lógica de acreditación.
- Si esto no se entiende, se mezcla mal "pago guiado por Saldoar" con "pago distribuido por transferencias directas".

## Risks
- Parte importante de esta lógica es interna y no se ve claramente desde front.
- Hay riesgo de leer `agreement` solo como configuración cuando en realidad es una capacidad operativa con processor, account y fee.
- Algunos agreements parecen conectarse con liquidez externa o tooling interno, lo que agrega más complejidad.

## Main References
- `saldo/app/Agreements/`
- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- `saldo/app/Transactions/Transactions/TransactionAgreementObserver.php`
- `saldo/app/Transactions/Transactions/TransactionEvaluator.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotifications/TransactionToAgreementNotification.php`
- `saldo/routes/panel.php`
- `solido/apps/solido-app/src/app/transactions/transaction.ts`
- `solido/apps/solido-app/src/app/transactions/pages/transaction-info/transaction-operation-data/transaction-instructions/`

## Evidence Level
- `confirmed`: estructura principal, bifurcacion por agreement, processors y sincronizacion
- `inferred`: algunos detalles finos de operatoria interna o de proveedores externos
