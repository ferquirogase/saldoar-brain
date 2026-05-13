# Saldoar Brain — CLAUDE.md

Este repositorio es la base de conocimiento operativa de Saldoar.
Su objetivo es responder preguntas sobre el producto con trazabilidad desde la experiencia del usuario hasta el código fuente.

## Para qué sirve

Responde preguntas de soporte, marketing, UX y producto sobre:
- cómo funciona cada flujo del producto
- por qué ocurre un comportamiento específico
- qué pasa en backend cuando el usuario hace X
- qué reglas de negocio aplican en cada situación
- qué integraciones externas participan y cuándo

## Cómo navegar

| Pregunta | Dónde buscar |
|---|---|
| ¿Cómo funciona X? | `02_Flows/` |
| ¿Qué dominio maneja X? | `01_Domains/` |
| ¿Qué hace la entidad X? | `03_Entities/` |
| ¿Con qué servicio externo se conecta X? | `04_Integrations/` |
| Preguntas frecuentes de soporte/marketing | `05_FAQ_By_Area/` |
| Comportamientos inesperados o grises | `06_Edge_Cases/` |
| Contexto listo para inyectar en agentes | `07_Agent_Context/` |

## Flujos documentados

| Flow | Carpeta | Cubre |
|---|---|---|
| Visibilidad y estado de transacción | `02_Flows/transaction-visibility-and-status/` | Consulta pública, deep links, validaciones pendientes, cancelación, redirects legacy |
| Instrucciones de pago | `02_Flows/payment-instructions/` | Variantes por tipo de operación, lectura dual, efectos internos, helpers |
| Validaciones de identidad | `02_Flows/identity-validations/` | DNI, selfie, Facebook, biométrica (Veriff), screenshot, reglas de bloqueo |

## Cómo responder preguntas con este repo

1. Leer el `flow.yaml` relevante para ubicar rutas, entidades y reglas clave
2. Leer el `README.md` del flow para contexto operativo y edge cases
3. Si la pregunta es de soporte o marketing: traducir lógica técnica a lenguaje operativo
4. Marcar como inferencia todo lo que no esté explícitamente confirmado en código
5. No asumir que ruta pública (`/t/...`) implica mismo comportamiento que dashboard (`/my/...`)

## Vocabulario clave

| Término | Significado |
|---|---|
| `beforepath` | Prefijo de URL que determina el contexto API: `t` (público) o `users/{userId}` (dashboard) |
| `public transaction context` | Acceso a transacción sin login por `/t/transactions/v3/{id}/{key}/{mid}/...` |
| `dashboard context` | Acceso autenticado por `/my/dashboard/transactions/v3/{id}/...` |
| `state chips` | Elementos UI de estado/acción alrededor del chat y barra de progreso |
| `directTransfers1` | Instrucciones de pago hacia el receptor (cuentas bancarias del vendedor) |
| `directTransfers2` | Comprobantes de pago del comprador (archivos subidos) |
| `validable` | Entidad que puede tener validaciones: `USER` o `TRANSACTION` |
| `instructions_read_at` | Timestamp que registra cuándo el usuario abrió las instrucciones por primera vez |
| `marked_as_sent` | Flag que indica si el comprador marcó su pago como enviado |
| `transaction_mid` | ID público de la transacción, visible en la URL |

## Nivel de evidencia

- `confirmed`: visto directamente en código fuente
- `inferred`: inferido a partir de naming, wiring o comportamiento observado
- `unknown`: no verificado, necesita validación

## Contexto del producto

Saldoar es una plataforma fintech para pagos y transferencias. Opera en contextos públicos (sin login) y autenticados (dashboard). Sus flujos principales involucran transacciones, instrucciones de pago, validaciones de identidad y consulta de estados.

Para contexto extendido de agente, ver `07_Agent_Context/saldoar-brain-bootstrap.md`.
