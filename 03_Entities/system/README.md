# System

## Simple Definition
`System` es la entidad que representa un método operativo disponible dentro de Saldoar, como PayPal, banco, PIX, crypto, VCC o similares.

## Why It Matters
Muchas diferencias del producto que el usuario percibe como “comportamientos raros” en realidad vienen de `System`:
- qué cuenta pide
- qué red usa
- si se puede enviar o recibir
- qué mínimos y fees tiene
- si admite `directTransfers`
- qué rama operativa toma

## Core Role
`System` no es solo un nombre o logo.

Define propiedades reales del método:
- moneda
- grupo
- market
- tipo de cuenta
- necesidad de cuenta origen/destino
- fees
- montos mínimos
- redes
- tiempos promedio
- si habilita transferencias directas o caminos más cerrados

## Key Attributes To Read First
- `id`
  Identificador canónico del sistema.

- `name`
  Nombre visible.

- `group_id`
  Grupo funcional al que pertenece.

- `currency_id`
  Moneda principal del sistema.

- `market`
  Mercado o familia, por ejemplo crypto u otros.

- `account_type`
  Tipo de cuenta que espera.

- `default_network_id`
  Red por defecto cuando aplica.

- `envia` / `recibo`
  Si puede enviar o recibir.

- `requirecuenta1` / `requirecuenta2`
  Si exige cuenta origen o destino.

- `direct_transfers_enabled`
  Si participa en el circuito de destinos/transferencias directas.

- `direct_transfer_min_amount`
  Mínimo operativo para direct transfers.

- `minimum_usd1` / `minimum_usd2`
  Mínimos de entrada y salida.

- `time_average`
  Tiempo promedio visible u operativo.

## Main Relationships
- `currency`
- `group`
- `networks`
- `banks`
- `bankAccountTypes`
- `systemInformation`

## Important Distinctions
- `System` no es lo mismo que `Account`.
- `System` no es lo mismo que `Agreement`.
- `System` no es lo mismo que `Network`, aunque pueda depender de una.
- dos sistemas con la misma moneda pueden comportarse muy distinto.

## Main Backend Surface
- `saldo/app/Systems/Systems/System.php`
- `saldo/app/Systems/Systems/SystemEnum.php`
- `saldo/app/Systems/`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/system.ts`
- selectores de sistema
- calculadora de transacción
- formularios de cuenta
- landings por sistema
- instrucciones y waits del pedido

## Common Questions This Entity Answers
- qué tipo de cuenta pide este método
- si requiere red
- por qué cambia el formulario al cambiar de sistema
- si este método puede entrar por direct transfer
- por qué un sistema lleva a QR, otro a screenshots y otro a validación

## UX / Support Reading
- Si cambia el método, cambia una parte importante de la experiencia.
- Muchas promesas de producto tienen que chequearse contra `System`, no solo contra el flujo general.
- Si querés entender por qué un camino se bifurca, mirá `market`, `group_id`, `account_type`, `direct_transfers_enabled` y `default_network_id`.

## Main References
- `saldo/app/Systems/Systems/System.php`
- `saldo/app/Systems/Systems/SystemEnum.php`
- `solido/apps/solido-app/src/app/core/resources/system.ts`
- `01_Domains/systems-and-integrations`
- `02_Flows/system-specific-branches`

## Evidence Level
- `confirmed`
