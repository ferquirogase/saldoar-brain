# State Chip Content

## Simple Definition
`StateChipContent` es la capa de contenido de un `StateChip`.

Guarda, por idioma, el texto corto que el usuario ve en el chip (`ask`) y la respuesta automatica opcional que backend puede agregar despues de que el usuario lo selecciona (`answer`).

## Why It Matters
Esta entidad separa una parte muy importante del producto:
- la estructura del camino guiado vive en `StateChip`
- el copy y la respuesta visible viven en `StateChipContent`

Eso permite cambiar tono, idioma o explicacion sin tocar la logica del arbol ni las acciones del chip.

Ayuda a responder:
- donde vive el texto que ve el usuario
- por que el mismo chip puede comportarse igual pero decir cosas distintas segun idioma
- donde se edita una respuesta automatica
- por que un cambio de copy impacta inmediatamente en la experiencia

## Core Role
`StateChipContent` traduce un nodo funcional a lenguaje visible.

Sin esta entidad, `StateChip` seria solo una estructura tecnica con ids, relaciones y acciones. Con esta entidad, ese nodo pasa a ser una opcion entendible para usuario real.

## Key Attributes To Read First
- `state_chip_id`
  A que chip pertenece este contenido.

- `lang`
  Idioma del contenido. La combinacion `state_chip_id + lang` es unica.

- `ask`
  Texto breve que aparece en el chip y que el usuario puede tocar o seleccionar.

- `answer`
  Texto de respuesta opcional que backend puede publicar despues de la seleccion del chip.

- `created_at`
- `updated_at`
  Sirven para leer cambios recientes en la capa de contenido.

## Main Relationships
- `stateChip`
  El nodo funcional al que este contenido pertenece.

## Important Distinctions
- `StateChipContent` no es el chip en si.
- `StateChipContent` no define arbol, hijos, padres ni posicion.
- `StateChipContent` no define `transaction_action`.
- `StateChipContent` tampoco es un `State` creado en la conversacion: es la fuente del copy que puede terminar generando ese estado.

## Runtime Behavior
Cuando frontend pide chips:
- backend carga `stateChipContents` filtrados por `App::getLocale()`
- `TransactionStateChipsService` toma el primer contenido disponible
- `ask` se parsea con contenido adaptativo para insertar variables del usuario o de la transaccion

Cuando el usuario selecciona un chip con respuesta:
- backend busca `answer` para ese idioma
- `HandleReceivedAnswerableStateChip` lo parsea con variables adaptativas
- luego puede crear un `State` publico con esa respuesta

## Caching Behavior
`StateChipContentObserver` limpia la cache de `state_chips` cuando un contenido:
- se crea
- se actualiza

Esto importa porque la UX guiada depende mucho del copy actual y backend lo cachea por 24 horas si no hay invalidacion.

## Language Behavior
La tabla usa un modelo simple de idioma:
- `lang` corto, hoy ajustado a longitud `2`
- una fila por `state_chip_id` y por idioma
- ejemplo comun: `es`, `en`

Eso hace que un mismo chip pueda mantener:
- misma estructura y misma accion
- distinto `ask`
- distinta `answer`

## Main Backend Surface
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContent.php`
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContentObserver.php`
- `saldo/app/Transactions/StateChips/StateChipRepository.php`
- `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- `saldo/app/Transactions/StateChips/StateChipDatabaseRepository.php`

## Main Frontend Surface
No aparece como recurso independiente de UI. Se consume embebido dentro de la respuesta de chips.

En la experiencia se percibe como:
- label del chip
- respuesta automatica que aparece en la conversacion
- diferencias de idioma

## Common Questions This Entity Answers
- donde se cambia el texto de un chip
- donde vive la respuesta automatica posterior al click
- por que dos idiomas muestran copies distintas con la misma logica
- si el problema esta en el arbol o solo en el contenido visible
- por que un cambio editorial invalida cache

## UX / Support Reading
- Si el camino guiado es correcto pero el usuario no lo entiende, el problema puede estar en `StateChipContent`, no en `StateChip`.
- Si marketing, soporte o UX quieren ajustar el lenguaje de una rama sin tocar logica, esta es la capa correcta.
- Si una respuesta automatica suena rara o queda desactualizada, probablemente el fix viva aca.

## Main References
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContent.php`
- `saldo/app/Transactions/StateChips/StateChipContents/StateChipContentObserver.php`
- `saldo/app/Transactions/StateChips/TransactionStateChipsService.php`
- `saldo/app/Transactions/StateChips/Jobs/HandleReceivedAnswerableStateChip.php`
- `saldo/database/migrations/2024_04_11_100955_create_state_chip_contents.php`
- `saldo/database/migrations/2026_03_18_182948_state_chip_lang_only_with_lang.php`
- entidad `state_chip`

## Evidence Level
- `confirmed`
