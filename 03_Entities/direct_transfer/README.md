# DirectTransfer

## Simple Definition
`DirectTransfer` es la unidad de pago o cobro parcial que conecta dos transacciones cuando el flujo no va completamente por `agreement`.

## Why It Matters
Gran parte de la complejidad real de Saldoar vive acá:
- un pedido puede dividirse en varios pagos
- un pago puede quedar enviado pero no recibido
- un destino puede fallar
- un tramo puede borrarse, recuperarse o redimensionarse

Si no se entiende `DirectTransfer`, es muy fácil confundir:
- pedido
- envío puntual
- destino
- confirmación
- problema operativo

## Core Role
`DirectTransfer` funciona como vínculo operativo entre:
- la transacción que envía (`transaction1`)
- la transacción que recibe (`transaction2`)

Eso significa que una sola transacción puede tener:
- varios `directTransfers1` como envíos asignados desde su lado
- varios `directTransfers2` como pagos esperados hacia su lado

## Key Attributes To Read First
- `transaction1_id`
  Transacción que origina el envío o pago.

- `transaction2_id`
  Transacción destino vinculada a ese envío.

- `amount`
  Monto puntual de ese tramo.

- `sent`
  Si ese envío fue marcado como realizado.

- `sent_at`
  Cuándo fue marcado como enviado.

- `received`
  Estado de confirmación del receptor.
  Valores vistos: `unknown`, `no`, `yes`.

- `received_at`
  Cuándo se confirmó recepción, si ocurrió.

- `behaviour`
  Marca operativa útil cuando el transfer fue removido o alterado.

- `problems_qty`
  Señal acumulada de problemas sobre ese tramo.

- `payment_identification`
  Identificador visible que ayuda al usuario a reconocer el pago.

## Main Relationships
- `transaction1`
- `transaction2`
- `account`
- `files`

## Important Distinctions
- `DirectTransfer` no es la transacción completa.
- `DirectTransfer` no es solo un destino; es una asignación concreta entre dos lados.
- `marked_as_sent` en `Transaction` no reemplaza el detalle fino de qué `DirectTransfer` fue enviado o no.
- una transacción puede seguir viva aunque algunos `DirectTransfer` ya estén hechos y otros no.

## Operational States Hidden Here
La entidad no usa un enum único de negocio como `State`, pero igual codifica mucho estado operativo mediante:
- `sent`
- `received`
- `deleted_at`
- `behaviour`
- `problems_qty`

Además, `DirectTransferRepresentation` traduce ese conjunto a execution states como:
- `living`
- `working`
- `done`
- `failed`

## Main Backend Surface
- `saldo/app/Transactions/DirectTransfers/DirectTransfer.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransferRepresentation.php`
- processor y actions en `saldo/app/Transactions/Processors/` y `Actions/`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/direct-transfer.ts`
- relaciones `direct_transfers1` y `direct_transfers2` dentro de `transaction`
- instrucciones del pedido
- pantallas donde el usuario marca recibido o no recibido

## Common Questions This Entity Answers
- por qué un pedido se pagó en varias partes
- por qué una parte quedó pendiente
- por qué el usuario puede marcar “sí lo recibí” o “no lo recibí”
- por qué un destino fue removido o reemplazado
- por qué un pedido entró en held, disputed, mediation o recovery

## UX / Support Reading
- Si el problema es “una parte del dinero”, mirá `DirectTransfer`.
- Si el problema es “marqué enviado pero no avanza”, mirá `sent`, `received` y `sent_at`.
- Si el problema es “este destino no sirve / cambió / desapareció”, mirá `behaviour`, `deleted_at` y la relación con `transaction2`.

## Main References
- `saldo/app/Transactions/DirectTransfers/DirectTransfer.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransferRepresentation.php`
- `solido/apps/solido-app/src/app/core/resources/direct-transfer.ts`
- flujos de `payment-instructions`, `chat-state-chips-and-support-actions`, `cancellation-held-mediation-recovery`

## Evidence Level
- `confirmed`
