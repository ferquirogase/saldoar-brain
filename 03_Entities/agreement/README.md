# Agreement

## Simple Definition
`Agreement` es la entidad que representa un acuerdo operativo reutilizable, asociado a una cuenta y a un `processor`, que permite que una transacción tome una ruta más cerrada que la de `directTransfers`.

## Why It Matters
Cuando una transacción entra por `agreement`, cambian varias cosas a la vez:
- cómo se generan las instrucciones
- cómo se evalúa si está lista para acreditar
- qué fees aplican
- qué cuenta operativa usa Saldoar o el provider
- qué parte del flujo deja de depender de pagos distribuidos

## Core Role
`Agreement` funciona como una capacidad operativa preconfigurada.

No es solo una cuenta ni solo una bandera. Une:
- una cuenta operativa (`account_id`)
- un `processor`
- fees
- habilitación por sentido

Y después puede ser tomada por una `Transaction` mediante `agreement1_id` o `agreement2_id`.

## Key Attributes To Read First
- `id`
  Identificador del agreement.

- `alias`
  Nombre interno o etiqueta.

- `processor`
  Clase o estrategia que maneja su operatoria.

- `account_id`
  Cuenta operativa asociada.

- `fee1`
  Fee asociado al tramo 1.

- `fee2`
  Fee asociado al tramo 2.

- `enabled1`
  Si está habilitado para el sentido 1.

- `enabled2`
  Si está habilitado para el sentido 2.

## Main Relationships
- `account`

Indirectamente se conecta fuerte con:
- `transaction.agreement1`
- `transaction.agreement2`

## Important Distinctions
- `Agreement` no es lo mismo que `Account`.
- `Agreement` no es lo mismo que `System`.
- `Agreement` no es lo mismo que `DirectTransfer`.
- una transacción puede tener `agreement1`, `agreement2`, ambos o ninguno.

## Main Backend Surface
- `saldo/app/Agreements/Agreement.php`
- `saldo/app/Agreements/AgreementPanelRepository.php`
- `saldo/app/Agreements/SyncTransactionWithAgreementsJob.php`
- `saldo/app/Agreements/UpdateAgreementAccountJob.php`
- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`

## Main Frontend Surface
No suele aparecer como recurso explícito de usuario final, pero sí se ve por sus efectos:
- `transaction.attributes.agreement1_id`
- bifurcación de instrucciones entre agreement y direct transfers
- cambios en wait, QR, fees o acreditación

## Common Questions This Entity Answers
- por qué este pedido no fue por direct transfers
- qué cuenta operativa quedó detrás del flujo
- qué processor está manejando este camino
- por qué se aplicó una fee de agreement
- por qué el pedido entró en una rama más cerrada o más guiada

## UX / Support Reading
- Si el usuario ve instrucciones más directas o más cerradas, puede haber agreement detrás.
- Si querés entender por qué no aparecen destinos distribuidos, mirá `agreement1_id` y `agreement2_id`.
- Si querés entender por qué un pago se comporta distinto al estándar, revisá si la transacción está apoyada en un agreement.

## Main References
- `saldo/app/Agreements/Agreement.php`
- `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionWaitingPaymentNotification.php`
- `01_Domains/agreements`
- `02_Flows/system-specific-branches`

## Evidence Level
- `confirmed`
