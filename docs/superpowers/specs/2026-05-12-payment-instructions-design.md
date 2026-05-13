# Payment Instructions — Diseño de experiencia (Checkpoint Model)

**Fecha:** 2026-05-12
**Flow:** `flow-payment-instructions`
**Variante cubierta:** Fiat directo (direct transfers)
**Dispositivo:** Mobile-first, responsive

---

## Contexto y problema

Saldoar se comunica externamente como "3 simples pasos", pero cuando el usuario crea un pedido y entra a las instrucciones de pago se encuentra con una pantalla de complejidad notoriamente mayor a la prometida. Esto genera fricción cognitiva en el momento más sensible del flujo, que es cuando el usuario tiene que ejecutar una transferencia real.

El objetivo de este diseño no es esconder la complejidad, sino estructurarla de forma que se revele de a una tarea a la vez, manteniendo coherencia con la promesa de "3 pasos".

**Decisión de diseño clave:** en contextos financieros, la fricción bien ubicada suma claridad. El modelo de checkpoints introduce confirmaciones deliberadas donde reducen errores y disputas, sin bloquear el flujo del usuario.

---

## Modelo elegido: Checkpoints confirmados

La pantalla se estructura como una secuencia de tres bloques que el usuario resuelve en orden. Cada bloque tiene estado visual propio (pendiente / activo / completado) y el bloque activo tiene un CTA flotante asociado.

---

## Anatomía general

```
┌─────────────────────────────────┐
│  CONTEXTO DE TRANSACCIÓN        │  ← header fijo
├─────────────────────────────────┤
│  ALERTA / HELPER  (si aplica)   │  ← banner contextual del backend
├─────────────────────────────────┤
│  CHECKPOINT 1                   │
│  CHECKPOINT 2                   │  ← cuerpo scrolleable
│  CHECKPOINT 3                   │
├─────────────────────────────────┤
│  CTA FLOTANTE                   │  ← acción del checkpoint activo
└─────────────────────────────────┘
```

### Header fijo

Muestra monto de la operación, nombre de la contraparte y `transaction_mid`. No scrollea. Mínimo espacio vertical en mobile. Ubica al usuario sin sobrecargar.

### Banner de helper

Aparece sólo cuando el backend devuelve un `transaction_helper` activo. Tiene severidad visual (info / warning / error). Es dismissible si es informativo, no dismissible si requiere acción. Se posiciona antes de los checkpoints para ser visto antes de intentar pagar.

### CTA flotante

Botón sticky al fondo de la pantalla. Cambia según el checkpoint activo. Siempre describe la consecuencia de tocarlo, no sólo "confirmar".

---

## Checkpoint 1 — Transferí el dinero

### Estado activo

```
┌─────────────────────────────────┐
│ ● 1  Transferí el dinero        │
│                                 │
│  Enviá exactamente este monto:  │
│  ┌───────────────────────────┐  │
│  │  $ 45.000,00              │  │  ← copy on tap
│  └───────────────────────────┘  │
│                                 │
│  A esta cuenta:                 │
│  ┌───────────────────────────┐  │
│  │  Banco Galicia             │  │
│  │  CBU  0070123400000123..  │  │  ← truncado, expandible
│  │  [Copiar CBU]             │  │
│  │  Titular: Juan García     │  │
│  └───────────────────────────┘  │
│                                 │
│  ¿No podés pagar con esta       │
│  cuenta?  Ver opciones →        │  ← link secundario, nunca CTA
└─────────────────────────────────┘
```

### Reglas de comportamiento

- Si hay múltiples `direct_transfers1`, se muestran como cards apiladas con indicador "1 de 2". El front ya identifica la activa pendiente — esa va primero.
- El monto tiene copy-on-tap. Es el dato con mayor tasa de error por transcripción.
- El CBU está truncado por defecto con botón de copia explícito. El número completo se expande con tap.
- "No podés pagar" es link secundario, nunca botón prominente. Disponible pero no compite con la acción principal. Al activarse, dispara `direct_transfer_action` hacia backend via `send-direct-transfer-action-use-case`.

### Estado completado

```
┌─────────────────────────────────┐
│ ✓ 1  Transferí el dinero     ›  │  ← verde, expandible para revisar datos
└─────────────────────────────────┘
```

---

## Checkpoint 2 — Avisá que pagaste

### Estado activo

```
┌─────────────────────────────────┐
│ ● 2  Avisá que pagaste          │
│                                 │
│  Una vez que hiciste la         │
│  transferencia, confirmalo acá. │
│  El vendedor recibirá un aviso. │
│                                 │
│  ⚠ Hacelo solo si ya            │
│  transferiste el dinero.        │
└─────────────────────────────────┘

[  Ya transferí, avisar al vendedor  ]  ← CTA flotante
```

### Reglas de comportamiento

- La advertencia "hacelo solo si ya transferiste" es fricción intencional. Reduce errores y disputas posteriores. Tono directo, no alarmista.
- El CTA describe la consecuencia ("el vendedor recibe un aviso"), no sólo la acción. Reduce ansiedad sobre qué se está activando.
- Al confirmar, setea `marked_as_sent` en backend y el checkpoint colapsa a verde. El CTA flotante pasa al checkpoint 3.

---

## Checkpoint 3 — Subí tu comprobante

### Estado activo (vacío)

```
┌─────────────────────────────────┐
│ ● 3  Subí tu comprobante        │
│                                 │
│  Adjuntá el comprobante de      │
│  transferencia. Puede ser una   │
│  captura de pantalla o PDF.     │
│                                 │
│  ┌── ── ── ── ── ── ── ── ──┐  │
│  │  +  Agregar archivo       │  │  ← tap abre file picker
│  └── ── ── ── ── ── ── ── ──┘  │
│                                 │
│  (Opcional pero recomendado)    │
└─────────────────────────────────┘
```

### Estado con archivo adjunto

```
┌─────────────────────────────────┐
│ ● 3  Subí tu comprobante        │
│                                 │
│  ┌───────────────────────────┐  │
│  │  📄 comprobante.jpg    ✕  │  │  ← preview + eliminar
│  └───────────────────────────┘  │
└─────────────────────────────────┘

[       Listo, enviar pedido       ]  ← CTA final
```

### Reglas de comportamiento

- Los archivos subidos corresponden a `direct_transfers2`.
- Si el campo es opcional en el flujo, se indica visualmente para no bloquear al usuario que no tiene comprobante.
- El CTA final cierra el ciclo del comprador dentro de la página de instrucciones.

---

## Vista del vendedor

El vendedor abre la misma transacción pero su rol cambia el énfasis de la pantalla: los checkpoints se convierten en **estados de seguimiento**, no de acción.

```
┌─────────────────────────────────┐
│ ◷ 1  Esperando transferencia    │  ← gris / en espera
│ ◷ 2  Comprador aún no avisó     │
│ ◷ 3  Sin comprobante todavía    │
└─────────────────────────────────┘
```

- Los estados se actualizan en tiempo real via websocket (`websocket-driven transaction refresh`).
- El vendedor no tiene CTAs. Tiene visibilidad.
- Al avanzar el comprador, los checkpoints del vendedor cambian a confirmado (`✓`) automáticamente.
- Los helpers del backend que apliquen al vendedor aparecen como banners en la parte superior.

---

## Integraciones relevantes

| Mecanismo | Rol en este diseño |
|---|---|
| `MarkInstructionsReadUseCase` | Se dispara al cargar el checkpoint 1 (por pixel o por acceso a `direct_transfers1`). Sin cambio de comportamiento visible para el usuario. |
| `direct_transfer_actions` | Se activa desde el link "No podés pagar" en checkpoint 1. |
| `transaction_helpers` | Se mapean al banner superior. La severidad del helper determina si es dismissible. |
| Websocket refresh | Actualiza la vista del vendedor en tiempo real sin recargar la página. |
| `MarketAtSendService` | Persiste el estado de "avisé que pagué" en checkpoint 2. Pendiente validar persistencia end-to-end. |

---

## Edge cases cubiertos por el diseño

- **Múltiples cuentas bancarias:** cards apiladas con indicador de progreso, priorizando la activa.
- **Helper bloqueante del backend:** banner no dismissible antes de los checkpoints impide avanzar si hay acción requerida.
- **Comprador sin comprobante:** el campo de upload es opcional/recomendado, no bloqueante.
- **Vendedor viendo la misma URL:** variante de sólo lectura sin CTAs, con estados actualizados en tiempo real.

## Unknowns pendientes de validación

- Persistencia real end-to-end de `MarketAtSendService`.
- Catálogo completo de `direct_transfer_action` para mapear opciones del "No podés pagar".
- Comportamiento exacto de `transaction_instructions_redirect_urls` y si puede sobreescribir la UI principal.
- Si el campo de comprobante (`direct_transfers2`) es siempre opcional o depende del tipo de operación.
