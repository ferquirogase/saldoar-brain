# State Chip Statistic

## Simple Definition
`StateChipStatistic` es el contador agregado de uso de un `StateChip`.

Registra cuantas veces se uso un chip en una fecha determinada.

## Why It Matters
Esta entidad convierte el arbol conversacional en algo medible.

Ayuda a responder:
- que opciones guiadas usa mas la gente
- que ramas casi no se tocan
- que chips terminan desviando a soporte
- si una mejora de copy o de flujo cambio el comportamiento real
- que dudas aparecen de manera recurrente

## Core Role
`StateChipStatistic` no describe una conversacion individual. Describe volumen agregado.

Su rol no es operativo sino analitico:
- `StateChip` define la opcion
- `StateChipContent` define el copy
- `StateChipStatistic` muestra adopcion y frecuencia de uso

## Key Attributes To Read First
- `state_chip_id`
  Que chip se esta contando.

- `date`
  Fecha agregada del conteo.

- `qty`
  Cantidad de usos acumulados para ese chip en esa fecha.

- `id`
  Identificador tecnico del registro.

## Main Relationships
- `stateChip`
  Relacion con el chip cuya seleccion se esta midiendo.

## Runtime Behavior
Cuando el usuario selecciona un chip con respuesta procesable:
- `HandleReceivedAnswerableStateChip` ejecuta `IncrementStateChipUsageJob`
- el job puede publicar una respuesta automatica como `State`
- luego actualiza el `state_chip_id` del estado original
- y hace un `INSERT ... ON DUPLICATE KEY UPDATE` sobre `state_chip_statistics`

Eso implica que la metrica se incrementa por dia y por chip, no por evento guardado como fila independiente.

## Aggregation Logic
La tabla tiene una restriccion unica por:
- `state_chip_id`
- `date`

Entonces:
- el primer uso del dia crea fila
- los siguientes usos del mismo dia incrementan `qty`

Esto simplifica lectura de volumen y evita guardar una tabla enorme de clicks unitarios.

## Important Distinctions
- `StateChipStatistic` no es tracking detallado por usuario.
- `StateChipStatistic` no dice por que se eligio el chip.
- `StateChipStatistic` no reemplaza revisar `State`, `Task` o chat para entender contexto.
- `StateChipStatistic` mide seleccion de chip, no exito de resolucion.

## Main Backend Surface
- `saldo/app/Transactions/StateChips/StateChipStatistics/StateChipStatistic.php`
- `saldo/app/Transactions/StateChips/Jobs/IncrementStateChipUsageJob.php`
- `saldo/database/migrations/2024_01_23_134822_create_state_chip_statistics.php`

## Main Frontend Surface
No aparece como entidad visible para usuario final.

Su valor esta en:
- analisis de soporte
- lectura de autoservicio
- decisiones de UX
- paneles o queries internas

## Common Questions This Entity Answers
- que chip se usa mas
- que chip casi nadie toca
- si una rama de soporte se disparo mas esta semana
- si un cambio de copy hizo subir o bajar el uso de una opcion
- si conviene simplificar o eliminar una rama guiada

## UX / Support Reading
- Si un chip de soporte tiene muchisimo uso, puede haber una oportunidad de resolver mejor antes en el arbol.
- Si una rama importante casi no se usa, puede estar mal nombrada o mal posicionada.
- Si despues de un cambio de copy sube el uso de un chip, la causa puede ser claridad o tambien mayor confusion: hay que leerlo junto con contexto operativo.

## Main References
- `saldo/app/Transactions/StateChips/StateChipStatistics/StateChipStatistic.php`
- `saldo/app/Transactions/StateChips/Jobs/IncrementStateChipUsageJob.php`
- `saldo/database/migrations/2024_01_23_134822_create_state_chip_statistics.php`
- entidad `state_chip`
- entidad `state_chip_content`

## Evidence Level
- `confirmed`
