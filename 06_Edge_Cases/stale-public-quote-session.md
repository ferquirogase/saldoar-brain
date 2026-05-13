# Stale Public Quote Session

## Tipo

Debt UX / continuidad ambigua.

## Contexto

Un usuario entra a una ruta publica incompleta o vuelve a home y ve una cotizacion que parece venir “de la nada”, aunque la URL actual no traiga todos los parametros.

## Condicion disparadora

- `system1` y `system2` no vienen completos en la ruta
- existe snapshot previo en `QuoteSessionService`
- el usuario vuelve a una superficie publica del mismo journey

## Comportamiento observado

- el front rehidrata una cotizacion previa
- se restauran sistemas, montos, operacion y `account_network2`
- la pantalla puede sentirse precargada aunque el link actual no explique ese estado

## Impacto

- soporte o UX pueden creer que el problema viene del link actual
- marketing puede pensar que una landing carga defaults neutros cuando en realidad hereda contexto previo
- un agente puede responder mal si no distingue URL actual de sesion temporal

## Clasificacion

Comportamiento intencional de continuidad, pero con riesgo de interpretacion errada.

## Lo importante para decidir

- no es persistencia de backend: es snapshot local en memoria del front
- ayuda a continuidad, pero puede volver opaco el origen real de una cotizacion
- cualquier analisis de entry point publico tiene que contemplar esta capa

## Flujos relacionados

- `02_Flows/system-selection-and-quote-calculator`
- `02_Flows/landing-for-systems-and-marketing-preloads`

## Preguntas que ayuda a responder

- “¿por que me aparece una cotizacion vieja si el link esta vacio?”
- “¿por que la home recuerda una cotizacion anterior?”
- “¿de donde sale esta cotizacion si la URL no tiene sistemas?”

## Fuentes

- `solido/apps/solido-app/src/app/core/services/quote-session.service.ts`
- `solido/apps/solido-app/src/app/home/home.component.ts`
- `solido/apps/solido-app/src/app/home/home-step-b.component.ts`
