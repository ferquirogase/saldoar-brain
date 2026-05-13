# State Chip

## Simple Definition
`StateChip` es una opcion guiada que Saldoar le muestra al usuario dentro del flujo conversacional de una transaccion.

No es un mensaje libre ni un helper pasivo: es un nodo seleccionable que puede abrir nuevas opciones, responder automaticamente o disparar una accion sobre la transaccion.

## Why It Matters
`StateChip` es una de las piezas que mas ordena la experiencia cuando el usuario no sabe que hacer o necesita salir del camino ideal.

Ayuda a responder:
- que caminos guiados ofrece el producto en cada estado
- por que el usuario ve ciertas opciones y no otras
- cuando una opcion solo navega y cuando ejecuta algo real
- como se mide el uso de esas opciones
- por que soporte o chat se abren desde un click y no desde un mensaje libre

## Core Role
`StateChip` vive entre tres capas:
- `State`: define en que situacion esta la transaccion
- `StateChip`: ofrece opciones guiadas para esa situacion
- `Task` / acciones: puede terminar convirtiendo esa eleccion en trabajo operativo o en un cambio real del pedido

No describe el estado del caso. Describe el menu contextual que el sistema pone a disposicion para actuar dentro de ese estado.

## Key Attributes To Read First
- `id`
  Identificador del chip. Usa shortflake y no tiene por que ser secuencial simple.

- `enabled`
  Si el chip esta activo o no.

- `group1_id`
  Restriccion por grupo del `system1` de la transaccion.

- `group2_id`
  Restriccion por grupo del `system2` de la transaccion.

- `transaction_action`
  Nombre de una accion de backend a ejecutar cuando el usuario selecciona el chip.

- `ask`
  Texto visible del chip para el usuario. Vive realmente en `StateChipContent`.

- `answer`
  Respuesta automatica opcional que backend agrega al flujo despues de la seleccion. Tambien vive en `StateChipContent`.

## Main Relationships
- `stateChipContents`
  Contenidos traducidos por idioma. El chip base no guarda directamente el texto.

- `parents`
- `children`
  Arman el arbol de navegacion entre chips.

- `parentPivot`
  Relacion del chip con su posicion y su padre dentro de un estado dado.

- `state_chip_statistics`
  Metricas de uso diarias por chip.

- `state`
  No es una relacion Eloquent directa sobre el modelo, pero cada respuesta de chips se calcula en funcion del `state` actual de la transaccion.

## Tree Logic
Los chips no son una lista plana. Se construyen como arbol:
- el backend pide chips para un `state` y un `parent_id`
- si el usuario elige uno, esa seleccion se cachea por transaccion
- el siguiente request devuelve sus hijos
- si no hay hijos, backend agrega chips especiales como `go back` y `support`

Eso hace que la UX se comporte como un menu conversacional escalonado.

## Special Chips
En codigo aparecen al menos dos chips funcionales especiales:
- `GO_BACK = 1`
- `SUPPORT = 2`

No dependen solo del contenido cargado. Tienen tratamiento especial en backend:
- `GO_BACK` retrocede en el stack de seleccion guardado en cache
- `SUPPORT` limpia la seleccion, abre `state chat` y agrega un mensaje aclaratorio al flujo

## Important Distinctions
- `StateChip` no es lo mismo que `State`.
- `StateChip` no es lo mismo que `TransactionHelper`.
- `StateChip` no es lo mismo que mensaje de chat libre.
- `StateChip` no es lo mismo que `Task`, aunque puede terminar generando trabajo operativo indirectamente.
- `StateChip` tampoco es solo copy: puede ejecutar `transaction_action`.

## Runtime Behavior
Cuando el usuario manda un `State` con `state_chip_id`:
- `HandlePublicTextObserver` detecta que no es un mensaje libre comun
- `TransactionStateChipsService` registra la seleccion en cache por transaccion
- `HandleReceivedStateChipJob` resuelve si ese chip tiene `transaction_action`
- si existe `answer`, se agrega una respuesta automatica parseada con variables adaptativas
- si el chip es `SUPPORT`, se abre el chat y se agrega un estado publico de confirmacion
- `IncrementStateChipUsageJob` acumula estadisticas de uso

## Filtering Rules
No todos los chips aplican a todas las transacciones.

`TransactionStateChipsService` filtra los chips por:
- `state` actual de la transaccion
- `parent_id` seleccionado
- `group1_id` del `system1`
- `group2_id` del `system2`

Eso explica por que dos pedidos parecidos pueden mostrar opciones distintas.

## Main Backend Surface
- `saldo/app/Transactions/StateChips/StateChips/StateChip.php`
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContent.php`
- `saldo/app/Transactions/StateChips/StateChipsPivot/StateChipsPivot.php`
- `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- `saldo/app/Transactions/StateChips/StateChipRepository.php`
- `saldo/app/Transactions/StateChips/StateChipController.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedStateChipJob.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- `saldo/app/Transactions/StateChips/Jobs/IncrementStateChipUsageJob.php`
- `saldo/app/Transactions/StateChips/StateChips/TransactionActionsRepository.php`

## Main Frontend Surface
- `solido/apps/solido-app/src/app/core/resources/state-chip.ts`
- `solido/apps/solido-app/src/app/core/services/state-chips.service.ts`
- `solido/apps/solido-app/src/ui/shared/components/sol-state-chip/sol-state-chip.component.ts`

En front aparece como:
- chips clickeables
- bandera `has_parent` para saber si el usuario esta dentro de un subcamino
- request de chips por transaccion en contexto publico o dashboard

## Common Questions This Entity Answers
- que opciones guiadas tiene el usuario en este estado
- por que aparece soporte como opcion
- por que un click abrio chat
- por que un chip cambio algo en la transaccion sin mensaje libre
- por que un camino guiado se corta o vuelve atras
- como medir que chips se usan mas

## UX / Support Reading
- Si queres mejorar autoservicio, mira `StateChip` antes que `chat` libre.
- Si soporte recibe siempre la misma duda, probablemente convenga resolverla con mejor arbol o mejor copy de chips.
- Si una rama genera demasiada apertura de soporte, el problema puede estar en el diseño del arbol o en una accion mal calibrada.
- Si queres entender por que una ruta conversacional varia segun sistema, mira `group1_id` y `group2_id`.

## Main References
- `saldo/app/Transactions/StateChips/StateChips/StateChip.php`
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContent.php`
- `saldo/app/Transactions/StateChips/StateChipsPivot/StateChipsPivot.php`
- `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedStateChipJob.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- `saldo/app/Transactions/StateChips/StateChipController.php`
- `solido/apps/solido-app/src/app/core/services/state-chips.service.ts`
- flujo `chat-state-chips-and-support-actions`

## Evidence Level
- `confirmed`
