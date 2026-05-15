# System Specific Branches

## Purpose
Mapear las diferencias importantes entre sistemas y mercados que cambian el recorrido real del pedido, los mensajes, las validaciones o la operacion.

## Scope
Este flujo no intenta describir cada sistema uno por uno.

Se concentra en responder:
- cuando dos pedidos parecidos toman caminos distintos
- que ramas dependen del sistema origen o destino
- que diferencias importan para UX, soporte, producto y agentes

## First Big Branch: Agreement Vs Direct Transfers
La primera bifurcacion importante no siempre es "que sistema es", sino "como se paga".

Cuando `agreement1_id > 0`:
- el pedido entra al camino de `agreement`
- `TransactionWaitingPaymentNotification` usa `TransactionToAgreementNotification`
- puede haber instrucciones mas cerradas o incluso especiales por metodo

Cuando `agreement1_id` no existe:
- el pedido entra al camino de `directTransfers`
- `TransactionWaitingPaymentNotification` usa `TransactionToDirectTransfersNotification`
- el usuario puede tener uno o varios envios manuales, marcado de enviados y subida de comprobantes

Eso hace que dos pedidos con sistemas parecidos puedan verse distintos aunque el usuario no entienda por que.

## Branch 1: Crypto As Origin
Si `system1.market` es `CRYPTO`, el comportamiento cambia bastante.

Puntos importantes:
- `TransactionToAgreementNotification` tiene tratamiento especial para `bitcoin`, `mbitcoin`, `dai`, `usdc` y `usdt`
- `WaitingBitcoin` puede mostrar instrucciones fijas o esperar confirmacion de red
- `ToWaitingPaymentOrCreditWhenItsCrypto` manda a `WAITING_PAYMENT` con texto de confirmacion automatica de red cuando aun no esta listo para acreditar
- `AddStateWeWaitYourScreenshots` no agrega el estado estandar de "sube tus comprobantes" cuando el origen es crypto

Lectura operativa:
- en crypto pesa mas la confirmacion de red que el comprobante clasico
- el ciclo de "marque enviado -> suba screenshot -> revisamos" no aplica igual que en otros metodos

## Branch 2: MercadoPago Credito And QR
`mercadopago-credito` tiene un camino especial de QR.

Puntos importantes:
- existe endpoint dedicado `mercadopagoqr`
- `MercadoPagoQrController` solo permite este camino para `SystemEnum::MERCADOPAGO_CREDITO`
- `MercadoPagoQr` genera y cachea un QR asociado a la transaccion
- si el pedido aun no tiene `agreement` listo, pedir el QR puede fallar y quedar como situacion operativa a revisar

Lectura operativa:
- aca las instrucciones no son solo texto; incluyen un artefacto operativo dinamico
- soporte y UX tienen que considerar que "no veo el QR" puede significar que el acuerdo todavia no estuvo listo

## Branch 3: PIX As Destination
PIX no es solo otro destino bancario.

Puntos importantes:
- cuando el destino es `PIX`, `ValidatePixAddressListener` dispara `ValidatePixAddressOrHeldUseCase`
- el sistema consulta validacion externa de la clave PIX via Kamipay
- si la clave no es valida, la transaccion puede ir a `HELD`
- en front existe validador especifico `PixAccountValidator`

Lectura operativa:
- una clave PIX invalida no es solo error de formulario; puede congelar el flujo
- hay dependencia de servicio externo para validar destino

## Branch 4: VCC As Destination
`VCC` es probablemente la rama mas distinta del producto.

Puntos importantes:
- hay landing y flujo propios en front (`comprar-vcc`)
- al quedar listo para pagar por primera vez, `DispatchRequestAVccJobListener` puede disparar `RequestAVccJob`
- el pedido pasa por `PRE_APPROVED_SENT` con copy especifico mientras se genera la tarjeta
- `TransactionPreApprovedSentStateNotification` cambia el mensaje standard por uno de "estamos generando tu tarjeta"
- `CreditedVcc` y `InstructionsToLoadVccNotification` agregan pasos posteriores especificos para cargarla en PayPal y luego pedir el codigo
- `TransactionSentStateNotification` intenta incluir el codigo de verificacion si ya existe
- en `TransactionToDirectTransfersNotification`, cuando el destino es `VCC`, la linea de "enviamos a esta cuenta" cambia porque no funciona como un destino comun
- por consistencia, el copy no deberia describir la VCC como una cuenta que "recibe saldo"

Lectura operativa:
- VCC no es un pago standard; es una mini experiencia propia montada sobre el motor transaccional
- tiene estados, mails y post-acreditacion diferentes
- la tarjeta sirve para verificar o cargar en PayPal dentro del flujo previsto; no es equivalente a acreditar saldo en un destino final comun

## Branch 5: PayPal Frictions
PayPal aparece como sistema con fricciones especificas.

Puntos importantes:
- `CreateATaskWhenEmailAccountIsDifferentAndIsNewListener` abre tarea operativa si es la primera vez que el usuario paga con una cuenta PayPal distinta a su email o si no la usa hace mucho
- `CreditedWithPendingDirectTransfers` agrega advertencias especiales para pagos pendientes o aceptacion manual del primer pago
- `TransactionSentStateNotification` agrega texto extra sobre retenciones de PayPal
- VCC ademas se monta sobre la experiencia de PayPal, asi que parte de la complejidad de VCC hereda restricciones de PayPal

Lectura operativa:
- PayPal tiene mas sensibilidad a identidad, antiguedad de cuenta y estados pendientes
- muchas fricciones de soporte no son "bug", sino comportamiento esperado del ecosistema PayPal

## Branch 6: Wise First Time Use
Wise tiene una rama chica pero importante.

Puntos importantes:
- `NotifyIfIsTheFirstTimeWithWiseListener` corre cuando el pago fue marcado como enviado
- aplica a `wise_eur` y `wise_usd`
- si la cuenta destino no es `wisetag` y parece ser la primera vez que el usuario recibe ahi, agrega estado y mail con instrucciones para activar la cuenta

Lectura operativa:
- en Wise el problema no siempre es el envio, sino si la cuenta del usuario ya esta lista para recibir

## Branch 7: Bank-Like Destinations And Account Details
Los destinos bancarios o similares tambien tienen comportamiento especial.

Puntos importantes:
- `CreditedBank` cambia segun exista o no `accountDetail`
- si faltan datos obligatorios, el sistema pide completar titularidad o datos bancarios antes de seguir
- cuando el metodo permite transferencias directas y no hay `agreement2`, el mail ya anticipa que el pago podria llegar en varias partes
- para cuentas argentinas, `TransactionSentStateNotification` agrega texto extra sobre demoras y ventana de reclamo
- para `payoneer`, el mail final avisa posibles demoras de hasta 2 dias habiles

Lectura operativa:
- no todos los destinos "bancarios" se comportan igual
- la necesidad de `accountDetail` y la promesa de tiempos cambia la experiencia

## What This Flow Clarifies
- por que un pedido puede pedir QR, otro comprobantes y otro esperar red
- por que algunos destinos pueden llevar a `HELD`
- por que VCC no se comporta como una transferencia comun
- por que PayPal y Wise generan advertencias especiales
- por que algunas notificaciones y estados cambian sin que cambie el esqueleto general del pedido

## Intentionally Out Of Scope
- `balance`
  No se profundizo aca porque todavia no esta activo para usuarios segun el criterio actual del proyecto.

- catalogo completo de todos los sistemas
  Este flujo prioriza las ramas que cambian decisiones o interpretacion del core.

## Connected Flows
- `payment-instructions`
- `identity-validations`
- `chat-state-chips-and-support-actions`
- `cancellation-held-mediation-recovery`
- `operator-interventions-and-panel-actions`
- `accounts-and-destination-selection`

## Important Risks
- Mirar solo la UI puede esconder reglas de sistema que viven en listeners, notificaciones y actions.
- El usuario suele percibir "Saldoar" como una sola experiencia, pero backend trata varios sistemas como subproductos distintos.
- Si producto o soporte prometen un comportamiento uniforme para todos los sistemas, es facil prometer mal.

## Open Questions
- Faltaria un mapa mas fino de sistemas secundarios o legacy menos frecuentes.
- No quedo profundizado el comportamiento de `balance` por decision de alcance.
- Puede haber diferencias adicionales en fees, rates o colas operativas que no eran necesarias para este nivel.

## Main References
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotifications/TransactionToAgreementNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotifications/TransactionToDirectTransfersNotification.php`
- `saldo/app/Transactions/Actions/ToWaitingPaymentOrCreditWhenItsCrypto.php`
- `saldo/app/Transactions/Notifications/StateNotifications/SpecialMethod/WaitingBitcoin.php`
- `saldo/app/Transactions/Http/MercadoPagoQrController.php`
- `saldo/app/Transactions/ExternalProcessors/MercadoPago/MercadoPagoQr.php`
- `saldo/app/Transactions/Transactions/Listeners/ValidatePixAddressListener.php`
- `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`
- `saldo/app/Transactions/Listeners/DispatchRequestAVccJobListener.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionPreApprovedSentStateNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/SpecialMethod/CreditedVcc.php`
- `saldo/app/Transactions/Notifications/InstructionsToLoadVccNotification.php`
- `saldo/app/Transactions/Listeners/NotifyIfIsTheFirstTimeWithWiseListener.php`
- `saldo/app/Transactions/Listeners/CreateATaskWhenEmailAccountIsDifferentAndIsNewListener.php`
- `saldo/app/Transactions/Notifications/StateNotifications/SpecialMethod/CreditedWithPendingDirectTransfers.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionSentStateNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/SpecialMethod/CreditedBank.php`
- `solido/apps/solido-app/src/app/transactions/pages/transaction-vcc/transaction-vcc.component.ts`
- `solido/apps/solido-app/src/app/transactions/pages/transaction-info/transaction-operation-data/waiting-payment/waiting-payment-crypto/waiting-payment-crypto.component.ts`
- `solido/apps/solido-app/src/app/core/account-service-provider/account-service-provider.ts`
- `solido/apps/solido-app/src/app/core/account-service-provider/accounts-validators/pix-account-validator.ts`
