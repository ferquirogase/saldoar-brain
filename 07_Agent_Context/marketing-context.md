# Marketing Context

Usar este contexto cuando el agente tenga que responder sobre landings, acquisition, rutas públicas, sistemas visibles y límites de copy o promesa.

## Objetivo

- entender cómo entra el usuario al producto desde links, SEO o campañas
- explicar por qué una landing abre cierto par o cierto sistema
- no confundir copy visible con regla real del backend
- detectar cuándo un comportamiento público depende de rates, replacement o sesión

## Orden de lectura recomendado

1. `00_Index/synonyms.md`
2. `02_Flows/landing-for-systems-and-marketing-preloads`
3. `02_Flows/system-selection-and-quote-calculator`
4. `02_Flows/system-specific-branches`
5. `06_Edge_Cases/legacy-system-links-and-replacements.md`
6. `06_Edge_Cases/stale-public-quote-session.md`

## Preguntas que este contexto cubre bien

- “¿por qué este link abre un sistema distinto?”
- “¿de dónde sale el canonical de una landing?”
- “¿por qué PayPal tiene landing curada?”
- “¿por qué una home pública recuerda una cotización?”
- “¿qué parte del journey público depende de backend vivo?”

## Flujos a priorizar según el tema

- entry points, canonical, idioma, preload: `landing-for-systems-and-marketing-preloads`
- calculadora y cotización inicial: `system-selection-and-quote-calculator`
- diferencias por método: `system-specific-branches`
- deals visibles en landings: `deals-and-direct-transfer-matching`

## Edge cases que conviene revisar temprano

- `legacy-system-links-and-replacements`
- `stale-public-quote-session`

## Errores comunes que el agente debe evitar

- no asumir que una landing es estática
- no asumir que el sistema visible coincide siempre con el slug original
- no prometer disponibilidad solo porque el front mostró una cotización
- no mezclar acquisition pública con dashboard autenticado

## Estilo de respuesta recomendado

- explicar primero la superficie pública que está actuando
- después separar qué viene de marketing/SEO y qué sigue dependiendo del backend
- si hay replacement o sesión previa, decirlo explícitamente

