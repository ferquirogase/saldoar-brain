# Saldoar Brain

Base de conocimiento operativa de Saldoar conectada al producto real.

No busca solo describir el servicio. Busca responder preguntas con trazabilidad entre:

- experiencia de usuario
- rutas front
- endpoints backend
- reglas de negocio
- integraciones
- casos borde
- lenguaje útil para agentes y equipos no técnicos

## Objetivos

- Convertir el repo en conocimiento consultable para UX, marketing, soporte, producto y operaciones.
- Reducir zonas grises sobre "como funciona" cada flujo.
- Dejar contexto reutilizable para agentes en Codex, Claude u OpenCode.
- Crear una capa de traduccion entre lenguaje de negocio y lenguaje tecnico.

## Principios

- Cada flujo debe poder leerse de arriba hacia abajo: usuario -> interfaz -> logica -> backend -> equipos.
- Cada afirmacion importante debe tener referencia a codigo o artefacto fuente.
- Mejor cobertura incremental y viva que documentacion total desactualizada.
- Markdown para humanos, YAML para agentes.
- La documentacion tiene que poder detectar drift contra `saldo` y `solido`.

## Estructura

- `00_Index/`: indice general y convenciones.
- `01_Domains/`: mapa de dominios de negocio y codigo.
- `02_Flows/`: flujos end-to-end.
- `03_Entities/`: entidades clave y sus relaciones.
- `04_Integrations/`: servicios externos y puntos de contacto.
- `05_FAQ_By_Area/`: preguntas frecuentes por area.
- `06_Edge_Cases/`: casos borde, comportamientos inesperados y vacios conocidos.
- `07_Agent_Context/`: contexto listo para inyectar en agentes.
- `99_Templates/`: plantillas base.
- `docs/traceability/`: convenciones y overrides de trazabilidad.
- `docs/retrieval/`: export y convenciones para retrieval/RAG.
- `docs/scripts/`: scripts operativos del brain.

## Trazabilidad y Drift

El brain ahora puede detectar documentacion potencialmente impactada cuando cambian archivos de `saldo` o `solido`.

La capa se apoya en:

- los campos tecnicos ya presentes en los YAML (`backend_sources`, `frontend_sources`, `backend_model`, `frontend_surface`, `backend_surface`)
- un archivo manual para overrides: `docs/traceability/manual-links.json`
- un script de impacto: `docs/scripts/brain-impact-report.ps1`

Uso rapido:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\brain-impact-report.ps1
powershell -ExecutionPolicy Bypass -File .\docs\scripts\brain-impact-report.ps1 -Mode head_range -CommitRange HEAD~1..HEAD
```

Referencia completa en `docs/traceability/README.md`.

## Retrieval

El brain tambien puede exportarse como corpus estructurado para retrieval.

Uso rapido:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\build-retrieval-corpus.ps1
powershell -ExecutionPolicy Bypass -File .\docs\scripts\query-brain-retrieval.ps1 -Query "por que no me aparece el qr"
```

Eso genera un corpus JSONL listo para indexar por documento logico, no por bootstrap monolitico.

## Flujos documentados

| Flow | Descripcion |
|---|---|
| `transaction-visibility-and-status` | Consulta de estado, deep links, validaciones pendientes, cancelacion, redirects legacy |
| `payment-instructions` | Instrucciones de pago por tipo de operacion, lectura dual, helpers contextuales, no recibido |
| `identity-validations` | Validaciones de identidad: DNI, selfie, Facebook, biometrica (Veriff), screenshot |
| `balance-entries-and-general-balance` | Entry, ciclo deposit/withdrawal, por que el balance general no refleja movimientos pendientes |
| `accounts-and-destination-selection` | Creacion y reutilizacion de cuentas, seleccion de destino, account details |
| `cancellation-held-mediation-recovery` | Cancelacion, estados HELD y HELD_DISPUTED, mediacion, recuperacion |
| `chat-state-chips-and-support-actions` | Estado del chat, chips de UI, acciones disponibles por estado |
| `concurrent-orders-and-omitted-transactions` | Concurrencia de pedidos, transacciones omitidas |
| `create-transaction-and-next-step` | Creacion de pedido, logica de siguiente paso post-creacion |
| `deals-and-direct-transfer-matching` | Deals bag, matching automatico, asignacion de destinos |
| `landing-for-systems-and-marketing-preloads` | Landings publicas por sistema, preloads, SEO |
| `notifications-mails-and-background-jobs` | Mails de estado, jobs, notificaciones push, observers |
| `operator-interventions-and-panel-actions` | Acciones desde panel, tareas, pipelines de intervencion |
| `public-order-creation-and-identity-bootstrap` | Acceso sin login, contexto por transaction key y user key, creacion de identidad desde pedido |
| `system-selection-and-quote-calculator` | Seleccion de sistemas, cotizacion publica, sesion de quote |
| `system-specific-branches` | Crypto, PIX, VCC, MercadoPago QR, PayPal, Wise, destinos bancarios |

## Edge cases documentados

| Edge Case | Tipo |
|---|---|
| `simultaneous-orders-omitted` | Comportamiento esperado con friccion UX |
| `stale-public-quote-session` | Debt UX / continuidad ambigua |
| `legacy-system-links-and-replacements` | Comportamiento esperado con impacto SEO/marketing |
| `pix-key-late-held` | Comportamiento esperado con friccion alta |
| `instructions-read-side-effects` | Comportamiento esperado poco visible |
| `vcc-copy-looks-like-balance-reception` | Friccion UX por semantica incorrecta |
| `chat-visible-but-locked` | Friccion UX por control backend |
| `held-disputed-without-screenshots` | Comportamiento esperado dificil de explicar |
| `to-future-ready-looks-stalled` | Estado valido con apariencia de bloqueo |
| `payment-disappears-on-to-future-ready` | Friccion UX critica / gap de logica backend |

## Siguiente expansion sugerida

1. `public-system-landings`
2. `user-onboarding`
3. `refund-and-dispute`
