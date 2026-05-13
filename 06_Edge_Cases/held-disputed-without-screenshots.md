# Held Disputed Without Screenshots

## Tipo

Comportamiento esperado dificil de explicar.

## Contexto

Un pedido entra en `HELD_DISPUTED` aunque el usuario no haya subido screenshots o aunque soporte espere que la disputa solo aparezca con evidencia adjunta.

## Condicion disparadora

- existen `directTransfers1` marcados como no recibidos
- pasa suficiente tiempo desde la ultima actividad relevante
- el pipeline de disputa detecta conflicto de recepcion

## Comportamiento observado

- la transaccion puede pasar a `HELD_DISPUTED`
- si hay screenshots, backend intenta resolver antes de dejarla ahi
- si no hay screenshots, igual puede quedar en disputa

## Impacto

- soporte puede explicar mal la causa si asume que la disputa depende solo de screenshots
- el usuario puede sentir que “cayo en disputa de golpe”
- se mezcla con otras lecturas de `HELD`, aunque no significan lo mismo

## Clasificacion

Esperado por la logica de conflicto de recepcion.

## Lo importante para decidir

- `HELD_DISPUTED` no es simplemente “hold con archivo faltante”
- la ausencia de screenshots no impide la disputa
- conviene separar bien `HELD`, `HELD_DISPUTED` y `MEDIATION` en cualquier explicacion interna

## Flujos relacionados

- `02_Flows/cancellation-held-mediation-recovery`
- `02_Flows/notifications-mails-and-background-jobs`

## Preguntas que ayuda a responder

- “¿por que entro en held disputed si no subi screenshots?”
- “¿que diferencia hay entre held y held disputed?”
- “¿la disputa depende de tener archivos?”

## Fuentes

- `saldo/app/Transactions/Commands/Pipes/HeldDisputedNotReceived.php`
- `saldo/app/Transactions/Jobs/TryToReleaseDisputeJob.php`

