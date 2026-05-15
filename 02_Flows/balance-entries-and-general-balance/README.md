# Balance Entries And General Balance

## Metadata

- `flow_id`: `flow-balance-entries-and-general-balance`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar cómo Saldoar modela los movimientos de balance a través de `Entry`, cuándo
un movimiento impacta el balance general del usuario, y por qué existe una brecha
visible entre el listado individual de movimientos y el total disponible.

## Entry Points

- `/my/dashboard/balance` — pantalla principal de balance del usuario autenticado

## Frontstage

El usuario ve dos superficies en la sección de balance:

**Lista de balances (balance general por sistema):**
muestra el saldo disponible por moneda/sistema. Se calcula en backend y se actualiza
cada vez que cambia un Entry. Solo incluye entradas confirmadas.

**Lista de entries (movimientos individuales):**
muestra todos los movimientos registrados, independientemente de su estado. Un depósito
aparece acá desde el momento de creación, aunque todavía no impacte el balance general.

**Lista de pedidos:**
las operaciones de balance también generan una transacción normal, por lo que aparecen
en la lista de pedidos del usuario. El estado que muestra esa transacción es el del
flujo transaccional estándar — no un estado propio del balance.

## Backstage

### Entidad central: Entry

`Entry` es el registro de cada movimiento de balance. Cada operación de balance
(depósito, retiro, swap, transferencia) crea un Entry vinculado a una transacción.

Atributos clave:
- `behaviour` — tipo de movimiento: `deposit`, `withdrawal`, `swap`, `transfer`
- `status` — estado del movimiento: `pending_deposit`, `pending_withdrawal`, `approved`, `rejected`
- `amount` — monto; negativo en retiros
- `entryable` — entidad a la que está atado (morfológico; actualmente siempre una `Transaction`)
- `system_id` — sistema de balance afectado

### Creación del Entry

`BalanceServiceProvider` registra dos listeners sobre `TransactionCreatedEvent`:

**Depósito** (`system2 = BALANCE`):
`CreateDepositEntryOnTransactionCreatedListener` crea el Entry con:
- `behaviour = DEPOSIT`
- `status = PENDING_DEPOSIT`
- `amount` calculado por `DepositAmountCalculator`

No mueve la transacción de estado — eso lo hace `TransactionNextStepUseCase`.

**Retiro** (`system1 = BALANCE`):
`CreateWithdrawalEntryOnTransactionCreatedListener` verifica que el balance disponible
sea suficiente antes de crear el Entry. Si no alcanza, hace rollback y lanza
`INSUFFICIENT_FUNDS`. Si alcanza:
- `behaviour = WITHDRAWAL`
- `status = PENDING_WITHDRAWAL`
- `amount` negativo calculado por `WithdrawalAmountCalculator`
- Llama a `CreditStateHelper->creditOrHeld()` — a diferencia del depósito, el retiro
  intenta acreditar la transacción de inmediato.

### Sincronización de status del Entry

`UpdateDepositEntryStatusListener` y `UpdateWithdrawalEntryStatusListener` escuchan
`TransactionStateChangedEvent` y actualizan el status del Entry según el estado actual
de la transacción:

| Estado de la transacción | Status del Entry |
|---|---|
| `TO_FUTURE`, `TO_FUTURE_READY`, `HELD`, `HELD_DISPUTED`, `WAITING_PAYMENT`, `VALIDATION_REQUIRED` | `PENDING_DEPOSIT` / `PENDING_WITHDRAWAL` |
| `CREDITED_PAYMENT`, `PRE_APPROVED_SENT`, `SENT`, `MEDIATION` | `APPROVED` |
| `CANCELED`, `SCAMMED`, `NONE`, `TO_NEW_TICKET` | `REJECTED` |

### Cálculo del balance general

`BalanceUpdateService.calculateBalance()` se ejecuta cada vez que se guarda un Entry
(vía `BalanceUpdaterEntryObserver`). Suma únicamente entries con status:

```
APPROVED + PENDING_WITHDRAWAL
```

`PENDING_DEPOSIT` queda excluido deliberadamente — el saldo no se acredita hasta que la
transacción sea confirmada. `PENDING_WITHDRAWAL` sí suma desde la creación del retiro,
actuando como reserva inmediata del saldo comprometido.

## Trazabilidad Técnica

### Frontend

- estrategia de depósito: `solido/apps/solido-app/src/ui/features/balance/application/strategies/deposit-strategy.ts`
- estrategia de retiro: `solido/apps/solido-app/src/ui/features/balance/application/strategies/withdraw-strategy.ts`
- lista de movimientos: `solido/apps/solido-app/src/ui/features/balance/ui/components/entries-list/entries-list.component.ts`
- lista de balances por sistema: `solido/apps/solido-app/src/ui/features/balance/ui/components/balances-list/balances-list.component.ts`

### Backend

- wiring de eventos: `saldo/app/Balances/BalanceServiceProvider.php`
- creación de Entry por depósito: `saldo/app/Balances/Entries/Listeners/CreateDepositEntryOnTransactionCreatedListener.php`
- creación de Entry por retiro: `saldo/app/Balances/Entries/Listeners/CreateWithdrawalEntryOnTransactionCreatedListener.php`
- sincronización de status (depósito): `saldo/app/Balances/Entries/Listeners/UpdateDepositEntryStatusListener.php`
- sincronización de status (retiro): `saldo/app/Balances/Entries/Listeners/UpdateWithdrawalEntryStatusListener.php`
- cálculo del balance general: `saldo/app/Balances/Balances/BalanceUpdateService.php`
- query de suma de entries: `saldo/app/Balances/Balances/BalanceRepository.php`
- observer que dispara recálculo: `saldo/app/Balances/Observers/BalanceUpdaterEntryObserver.php`

## Reglas de Negocio Detectadas

### El balance general no incluye depósitos pendientes

Un depósito en `PENDING_DEPOSIT` no suma al balance. Solo lo hace cuando la transacción
asociada alcanza `CREDITED_PAYMENT` o `SENT` y el Entry pasa a `APPROVED`. Esto previene
que el usuario vea saldo disponible antes de que el pago esté efectivamente confirmado.

### Los retiros reservan saldo desde la creación

`PENDING_WITHDRAWAL` sí descuenta del balance desde el momento en que se crea la
transacción de retiro. El saldo queda reservado aunque el retiro todavía no se haya
procesado. Si el retiro se cancela o falla, el Entry pasa a `REJECTED` y el saldo
se libera en el próximo recálculo.

### Las operaciones de balance son transacciones normales

Depósito y retiro usan `CreateTransactionUseCase` con `system2 = BALANCE` o
`system1 = BALANCE`. La transacción resultante es indistinguible de cualquier otra
a nivel de modelo — aparece en la lista de pedidos con el mismo ciclo de estados.
El label "Enviando" que ve el usuario en la lista de pedidos corresponde al estado
`CREDITED_PAYMENT (12)`, que es el estado estándar de la transacción en ese punto.

### El recálculo es reactivo, no periódico

El balance general no se recalcula por job o cron — se recalcula en cada `save()` de
cualquier Entry del usuario para ese sistema. Eso lo hace `BalanceUpdaterEntryObserver`.

## Preguntas que este flujo responde

- Por qué un movimiento aparece en la lista de balance pero no suma al total disponible.
- Por qué el pedido de depósito a balance aparece en la lista de pedidos con estado "Enviando".
- Cuándo exactamente se acredita el saldo después de un depósito.
- Por qué al crear un retiro el saldo disponible cae de inmediato.
- Qué pasa con el saldo reservado si el retiro es cancelado.
- Cómo se calcula el balance general del usuario.
- Qué es un Entry y cómo difiere de la transacción.

## Edge Cases / Riesgos

- El label "Enviando" en la lista de pedidos para operaciones de balance usa el copy
  genérico del estado 12: "El pedido está en cola de pagos: recibirás el total de tu
  saldo en una o varias partes." Ese copy está pensado para transferencias fiat, no
  para depósitos a balance — puede generar confusión.
- Si la transacción de retiro queda en `HELD` o `WAITING_PAYMENT`, el Entry permanece
  en `PENDING_WITHDRAWAL` y el saldo sigue reservado indefinidamente hasta que la
  transacción avance o se cancele.
- Un depósito en `TO_FUTURE_READY` puede quedar visible en la lista de movimientos
  sin impactar el balance por tiempo indefinido, hasta que operaciones lo resuelva.

## Unknowns

- Comportamiento exacto de `swap` y `transfer` a nivel de Entry — no fueron trazados
  en esta iteración, aunque los listeners y behaviours existen.
- Si existen Entries con `entryable_type` distinto de `transaction` y en qué casos.
- Cómo se muestra el status del Entry en la UI de la lista de movimientos
  (¿distingue visualmente pending de approved?).

## Fuentes

- `saldo/app/Balances/BalanceServiceProvider.php`
- `saldo/app/Balances/Entries/Entry.php`
- `saldo/app/Balances/Entries/EntryStatusEnum.php`
- `saldo/app/Balances/Entries/EntryBehaviourEnum.php`
- `saldo/app/Balances/Entries/Listeners/CreateDepositEntryOnTransactionCreatedListener.php`
- `saldo/app/Balances/Entries/Listeners/CreateWithdrawalEntryOnTransactionCreatedListener.php`
- `saldo/app/Balances/Entries/Listeners/UpdateDepositEntryStatusListener.php`
- `saldo/app/Balances/Balances/BalanceUpdateService.php`
- `saldo/app/Balances/Balances/BalanceRepository.php`
- `saldo/app/Balances/Observers/BalanceUpdaterEntryObserver.php`
- `solido/apps/solido-app/src/ui/features/balance/application/strategies/deposit-strategy.ts`
- `solido/apps/solido-app/src/ui/features/balance/application/strategies/withdraw-strategy.ts`
- `solido/apps/solido-app/src/assets/i18n/locales/es/transactions.json`
