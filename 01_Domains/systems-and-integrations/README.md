# Systems And Integrations

## Purpose
Describir la capa que define con que sistemas opera Saldoar, como los agrupa, que redes o fees usa y que integraciones externas modifican el comportamiento del pedido.

## What This Domain Owns
- catalogo de sistemas
- groups, networks y currencies
- fees y rates
- colas o pistas de pago por sistema
- informacion de sistema visible al producto
- integraciones externas relevantes para operar

## Core Mental Model
Saldoar no intercambia "dinero" de forma abstracta. Intercambia entre sistemas concretos con reglas concretas.

Este dominio define:
- que combinaciones existen
- que datos pide cada sistema
- que tiempos o riesgos trae
- que integracion externa participa

## Main Backend Surface
Confirmado en `saldo/app/Systems/`:
- `Systems`
- `Groups`
- `Networks`
- `Currencies`
- `Rates`
- `Fees`
- `ExternalFees`
- `SystemsInformation`
- `SystemsPaymentQueue`
- `SystemsPaymentSent`

Tambien se conecta con:
- `saldo/app/Transactions/ExternalProcessors/`
- `saldo/app/External/`
- `saldo/app/CryptoCore/`

## Main Frontend Surface
Confirmado en:
- selectores de sistemas y calculadora de transaccion
- validadores de cuenta por tipo
- routes y landings de sistemas especificos
- instrucciones y waiting-payment con variantes por sistema

## Main Entities And Concepts
- `System`
- `Group`
- `Network`
- `Currency`
- `Rate`
- `Fee`
- `SystemInformation`
- external processor

## Important Branches Already Seen
- `agreement` vs `directTransfers`
- `mercadopago-credito` con QR
- `PIX` con validacion externa y posible `HELD`
- `VCC` como subproducto operativo
- `PayPal` con fricciones y checks especificos
- `Wise` con activacion inicial
- `crypto` con confirmacion de red

## Key Responsibilities
1. Definir como se representa cada sistema en producto.
2. Habilitar calculo, validacion y copy segun sistema.
3. Integrar proveedores externos que afectan pago, validacion o confirmacion.
4. Exponer metadata suficiente para front, operacion y notificaciones.

## Flows Anchored In This Domain
- `payment-instructions`
- `accounts-and-destination-selection`
- `deals-and-direct-transfer-matching`
- `system-specific-branches`
- `public-order-creation-and-identity-bootstrap`

## Boundaries
Este dominio no "posee" el pedido, pero condiciona fuertemente su comportamiento.

Se conecta directo con:
- `transactions`
- `validations`
- `support-and-operations`

## UX Reading
- Muchas diferencias de experiencia no son decisiones arbitrarias de UI sino propiedades del sistema origen o destino.
- Si este dominio se simplifica demasiado, se termina prometiendo uniformidad donde no la hay.
- Marketing, soporte y producto necesitan esta capa para no hablar de "Saldoar" como si todos los caminos fueran iguales.

## Risks
- La logica puede estar repartida entre metadata de sistemas y codigo transaccional.
- Algunas diferencias viven en integraciones externas y no son visibles desde front.
- Hay riesgo de legacy o aliases historicos de sistemas que confundan lectura.

## Main References
- `saldo/app/Systems/`
- `saldo/app/Transactions/ExternalProcessors/`
- `saldo/app/External/`
- `saldo/app/CryptoCore/`
- `solido/apps/solido-app/src/app/core/account-service-provider/`
- `solido/apps/solido-app/src/app/transactions/`

## Evidence Level
- `confirmed`: estructura principal de sistemas, redes, fees e integraciones visibles
- `inferred`: ownership fino entre sistemas y transacciones para ciertas reglas
