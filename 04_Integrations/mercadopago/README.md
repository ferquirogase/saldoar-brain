# MercadoPago

## Simple Definition
`MercadoPago` es la integracion que Saldoar usa, en lo ya mapeado, para generar QR de pago en pedidos por acuerdo asociados a `mercadopago_credito`.

No es un medio genérico en todo el producto: aparece como rama operacional específica del flujo de instrucciones.

## Why It Matters
Importa porque cambia bastante la experiencia:

- el usuario no recibe cuentas directas sino QR
- la disponibilidad del QR depende de que el acuerdo este listo
- hay cache y proteccion contra rate limit
- si falla temprano, soporte recibe un problema que parece UI pero es de disponibilidad operativa

## Main Product Role
El camino base es:

1. el pedido entra por rama `agreement`
2. front pide `mercadopagoqr`
3. backend valida ownership y `system1_id`
4. backend genera o reutiliza un QR asociado al pedido
5. el usuario paga por ese QR

## Main Flows Connected

- `payment-instructions`
- `system-specific-branches`

## Main Backend Surface

- `saldo/app/Transactions/Http/MercadoPagoQrController.php`
- `saldo/app/Transactions/ExternalProcessors/MercadoPago/MercadoPagoQr.php`
- `saldo/app/Transactions/ExternalProcessors/MercadoPago/MercadoPagoParams.php`

## Main Frontend Surface

- `solido/apps/solido-app/src/domain/use-cases/search-qr-agreement-use-case.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement.component.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement-view-model.service.ts`

## What It Triggers

- generacion o recuperacion de QR
- armado de orden en POS externo
- cache del QR por transaccion y acuerdo
- logging si se pide QR antes de tener acuerdo listo

## Failure Or Friction Modes

- QR pedido demasiado pronto: acuerdo sin address lista
- system mismatch: el pedido no corresponde a `mercadopago_credito`
- ownership mismatch: el usuario no deberia ver ese QR
- fallo del proveedor externo o rate limit

## UX / Support Reading

- Si el usuario dice "no aparece el QR", no siempre es un bug visual; puede faltar la address del acuerdo.
- Si el pedido no es de `mercadopago_credito`, este camino no aplica.
- El cache hace que el mismo pedido no regenere QR todo el tiempo, lo que ayuda operativamente pero puede confundir si se espera refresco instantaneo.

## Questions This Integration Helps Answer

- de donde sale el QR de MercadoPago
- por que a veces el QR no aparece
- cuando un pedido usa QR y cuando usa direct transfers
- que valida backend antes de devolver el QR
- que pasa si MercadoPago falla o el acuerdo no esta listo

## Main References

- `saldo/app/Transactions/Http/MercadoPagoQrController.php`
- `saldo/app/Transactions/ExternalProcessors/MercadoPago/MercadoPagoQr.php`
- `solido/apps/solido-app/src/domain/use-cases/search-qr-agreement-use-case.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement.component.ts`

## Evidence Level

- `confirmed`
