# Transaction

## Simple Definition
La `Transaction` es la unidad central del producto. Representa un pedido concreto de intercambio y concentra casi toda la operativa relevante de Saldoar.

## Why It Matters
Si alguien pregunta "qué pasó con este caso", casi siempre la respuesta empieza en `Transaction`.

Desde esta entidad se entienden:
- que quiso hacer el usuario
- con qué sistemas
- por qué camino operativo entró
- en qué estado está
- qué falta para avanzar
- qué ayudas, validaciones, tareas o pagos quedaron asociados

## Core Role
`Transaction` no es solo una orden económica. También funciona como:
- contenedor de estado
- contenedor de contexto operativo
- vínculo entre usuario, cuentas, sistemas y evidencia
- punto de entrada para chat, helpers, validaciones y notificaciones

## Key Attributes To Read First
- `mid`
  Identificador corto visible y muy usado en soporte/operación.

- `user_id`
  Usuario dueño del pedido.

- `system1_id` / `system2_id`
  Método de origen y destino.

- `amount1` / `amount2`
  Monto que envía y monto que recibe.

- `account1_id` / `account2_id`
  Cuentas origen y destino.

- `agreement1_id` / `agreement2_id`
  Indican si algún tramo entra por route de agreement.

- `state`
  Estado actual resumido del pedido.

- `ready_to_pay`
  Señal operativa importante para pagos de salida.

- `marked_as_sent`
  Marca relevante para varios flujos, sobre todo de lado usuario.

- `instructions_read_at`
  Señal de lectura de instrucciones que participa en reglas reales, por ejemplo concurrencia entre pedidos.

- `sent`, `sent_at`, `received`, `rest_to_pay`
  Indicadores operativos del progreso del intercambio.

## Main Relationships
- `user`
- `system1`
- `system2`
- `account1`
- `account2`
- `agreement1`
- `agreement2`
- `states`
- `directTransfers1`
- `directTransfers2`
- `validations`
- `metas`
- `invoice`
- `dealsBag`
- `referralTransaction`
- `netPromoterScore`
- `vccs`

## What Changes Around A Transaction
Una transacción puede cambiar por:
- creación inicial
- cambio de estado
- asignación de agreement
- creación o ajuste de `directTransfers`
- validaciones
- subida de archivos o screenshots
- acciones manuales de operación
- jobs y listeners automáticos

## Main Backend Surface
- `saldo/app/Transactions/Transactions/Transaction.php`
- observers y jobs en `saldo/app/Transactions/`
- relaciones con `Accounts`, `Users`, `Validations`, `Agreements`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/transactions/transaction.ts`
- páginas de `transaction-info`
- `transaction-states`
- dashboards de transacciones

## Common Confusions This Entity Solves
- `Transaction` no es lo mismo que `DirectTransfer`.
- `Transaction` no es lo mismo que `State`.
- `Transaction` no es lo mismo que `Validation`.
- un pedido puede estar en un solo `state` actual y a la vez tener muchos `states` históricos.
- una transacción puede existir aunque todavía no esté "lista" para cobrar o enviar.

## UX / Support Reading
- Si querés entender el caso completo, arrancá por `Transaction`.
- Si querés entender un cambio puntual, mirá sus `states`, `validations` y `directTransfers`.
- Si querés entender por qué el camino es raro, mirá `agreement1_id`, `agreement2_id`, `system1_id`, `system2_id` y `instructions_read_at`.

## Main References
- `saldo/app/Transactions/Transactions/Transaction.php`
- `solido/apps/solido-app/src/app/transactions/transaction.ts`
- flujos en `02_Flows/`

## Evidence Level
- `confirmed`
