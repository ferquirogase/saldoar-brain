# Saldoar Brain Bootstrap

Inyecta este archivo cuando necesites que un agente responda con precisión sobre Saldoar.

---

## ¿Qué es Saldoar?

Saldoar es una plataforma fintech para pagos y transferencias. Permite a usuarios:
- Consultar el estado de sus transacciones (con y sin login)
- Ver y seguir instrucciones de pago según el tipo de operación
- Subir validaciones de identidad requeridas por el sistema
- Cancelar transacciones en ciertos estados
- Gestionar balances y movimientos desde el dashboard
- Operar con deals (ofertas de tasa) y múltiples métodos de pago

Opera en dos contextos diferenciados:
- **Contexto público** (`/t/...`): sin login, acceso por URL con clave de transacción
- **Contexto dashboard** (`/my/...`): autenticado, acceso desde panel del usuario
- **Contexto user key** (`/u/...`): sin login, acceso a recursos de usuario por clave

---

## Reglas para el agente

- Priorizar `02_Flows/` para entender comportamiento real del producto
- Para preguntas de soporte, marketing o UX: traducir lógica técnica a lenguaje operativo
- Marcar como inferencia todo lo que no esté explícitamente confirmado en código
- No asumir que ruta pública implica mismo comportamiento que dashboard
- Antes de responder, consultar `00_Index/synonyms.md` para mapear términos del usuario a términos del sistema
- Si la pregunta no tiene respuesta en el brain: decirlo claramente, sin inventar

---

## Flujos documentados (13)

### Transacciones core

| Flow | Carpeta | Resumen |
|---|---|---|
| flow-transaction-visibility-and-status | `02_Flows/transaction-visibility-and-status/` | Consulta de estado por mid+email, deep links, validaciones pendientes, cancelación, redirects legacy |
| flow-create-transaction-and-next-step | `02_Flows/create-transaction-and-next-step/` | Pipeline post-creación: acuerdo, transferencias directas, TO_FUTURE_READY, deals_bag |
| flow-payment-instructions | `02_Flows/payment-instructions/` | Instrucciones de pago por tipo (directa, QR, crypto, balance), lectura dual, helpers |
| flow-cancellation-held-mediation-recovery | `02_Flows/cancellation-held-mediation-recovery/` | Cancelación manual, HELD, MEDIATION, HELD_DISPUTED, recuperación |
| flow-concurrent-orders-and-omitted-transactions | `02_Flows/concurrent-orders-and-omitted-transactions/` | Límite de pedidos concurrentes, limpieza automática, pedidos omitidos |
| flow-accounts-and-destination-selection | `02_Flows/accounts-and-destination-selection/` | Selección y validación de cuentas de destino, account_detail, cambio de destino |
| flow-deals-and-direct-transfer-matching | `02_Flows/deals-and-direct-transfer-matching/` | Deals públicos, deals_bag (15 min), reglas de bloqueo, matching de transferencias |

### Identidad y acceso

| Flow | Carpeta | Resumen |
|---|---|---|
| flow-identity-validations | `02_Flows/identity-validations/` | Validaciones: DNI, selfie, Facebook, biométrica Veriff, screenshot |
| flow-public-order-creation-and-identity-bootstrap | `02_Flows/public-order-creation-and-identity-bootstrap/` | Creación sin login, reutilización de identidad por email, contextos de acceso |

### Comunicación y soporte

| Flow | Carpeta | Resumen |
|---|---|---|
| flow-chat-state-chips-and-support-actions | `02_Flows/chat-state-chips-and-support-actions/` | State chips, chat in-app, helpers, tareas para operadores |
| flow-operator-interventions-and-panel-actions | `02_Flows/operator-interventions-and-panel-actions/` | Panel de operadores, tipos de tarea, bots, restricciones por origen |
| flow-notifications-mails-and-background-jobs | `02_Flows/notifications-mails-and-background-jobs/` | Emails por estado, recordatorios, jobs en background, múltiples familias de notificación |

### Sistema y variantes

| Flow | Carpeta | Resumen |
|---|---|---|
| flow-system-specific-branches | `02_Flows/system-specific-branches/` | Ramificaciones por sistema: crypto, PIX, MercadoPago QR, VCC, PayPal, Wise, banco |

---

## Dominios confirmados

| Dominio | Descripción |
|---|---|
| `transactions` | Estados, instrucciones, cancelación, visibilidad pública y dashboard |
| `users` | Perfil, autenticación, validaciones de usuario |
| `validations` | Tipos de validación, flujos de aprobación, políticas de bloqueo |
| `accounts` | Cuentas de origen/destino, redes, account_details |
| `agreements` | Acuerdos de tasa, QR de MercadoPago |
| `support-and-operations` | Tareas, operadores, panel, bots |
| `systems-and-integrations` | Configuraciones por sistema/país, ramificaciones |
| `balances` | Saldo de usuario, movimientos (en expansión) |

---

## Vocabulario clave

| Término | Significado |
|---|---|
| `beforepath` | Prefijo de URL que determina el contexto API: `t` (público) o `users/{userId}` (dashboard) |
| `public transaction context` | Acceso sin login por `/t/transactions/v3/{id}/{key}/{mid}/...` |
| `dashboard context` | Acceso autenticado por `/my/dashboard/transactions/v3/{id}/...` |
| `user key context` | Acceso sin login por `/u/users/{userId}/{userKey}/...` |
| `state chips` | Botones contextuales de estado/acción dentro de la transacción |
| `directTransfers1` | Instrucciones de pago hacia el receptor (cuentas bancarias del vendedor) |
| `directTransfers2` | Comprobantes de pago del comprador (archivos subidos) |
| `validable` | Entidad que puede tener validaciones: `USER` o `TRANSACTION` |
| `instructions_read_at` | Timestamp que registra cuándo el usuario abrió las instrucciones |
| `marked_as_sent` | Flag que indica si el comprador marcó su pago como enviado |
| `transaction_mid` | ID público de la transacción, visible en la URL |
| `deals_bag` | Carrito de deals con expiración de 15 minutos |
| `TO_FUTURE_READY` | Estado en que el pedido queda si no hay destino disponible al crearse |
| `HELD` | Estado de retención por sospecha o falta de recepción |
| `MEDIATION` | Estado de mediación activa por disputa |

---

## Integraciones externas conocidas

| Servicio | Función | Flow relacionado |
|---|---|---|
| Veriff | Verificación biométrica de identidad | flow-identity-validations |
| MercadoPago | Generación de QR para pagos por acuerdo | flow-payment-instructions, flow-system-specific-branches |
| WebSocket | Actualizaciones en tiempo real de estado y validaciones | múltiples flows |
| PIX | Validación de clave PIX y pagos en Brasil | flow-system-specific-branches |

---

## Nivel de evidencia

- `confirmed`: afirmación directamente verificable en código fuente
- `inferred`: derivado de naming, wiring o comportamiento observado
- `unknown`: no verificado, requiere inspección adicional

---

## Protocolo de consulta

1. Consultar `00_Index/synonyms.md` para mapear el término del usuario al concepto del sistema
2. Identificar el flow relevante usando la tabla de flujos de este documento o los `query_patterns` en cada `flow.yaml`
3. Leer `flow.yaml` para campos estructurados: rutas, entidades, reglas de negocio, integraciones
4. Leer `README.md` del flow para contexto narrativo y edge cases
5. Si la respuesta es operativa (soporte, marketing): formular en lenguaje no técnico
6. Si la respuesta implica código: incluir paths de archivos relevantes del `flow.yaml`
7. Indicar nivel de evidencia: `confirmed` / `inferred` / `unknown`
