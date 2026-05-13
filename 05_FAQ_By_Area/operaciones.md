# FAQ — Operaciones

Preguntas sobre acciones del panel, tareas, intervenciones manuales y comportamiento del sistema operativo interno.

---

## ¿Qué puede hacer un operador sobre un pedido en HELD?

**Respuesta corta**: Puede ejecutar acciones como recuperar destinos, acreditar, mandar a mediación, agregar destinos nuevos o cancelar — según el task_type asignado.

**Contexto**: `TaskTypesEnum` define el catálogo completo de intervenciones. Para un pedido en HELD, las acciones más comunes son `recover` (recupera destinos eliminados y devuelve a revisión), `to_mediation` (escala a mediación), `add_destinations` (intenta asignar nuevos destinos y vuelve a `WAITING_PAYMENT`) o `credit` / `credit_reset` (acredita el pedido). Cada acción corre un pipeline, no una mutación simple.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`, `02_Flows/cancellation-held-mediation-recovery/`

---

## ¿Cómo se asigna una tarea a un operador?

**Respuesta corta**: Puede asignarse automáticamente según disponibilidad y rol, o manualmente cuando el primer operador que responde la toma.

**Contexto**: `OperatorTaskHelper` maneja los patrones de asignación: puede crear la tarea para todos los operadores, solo si no hay otra abierta, o asignarla a un operador online según rol. Si la tarea no tiene `assigned_user_id`, el primer operador que responde desde panel puede apropiársela. Las tareas de sistema tienen protección adicional: solo el asignado o el autor pueden completarlas.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Cuándo interviene un bot antes que un operador humano?

**Respuesta corta**: Cuando el pedido está en `WAITING_PAYMENT` y no hay condición de bloqueo activa — el bot puede tomar la tarea temporalmente y luego devolverla a humanos.

**Contexto**: Hay una capa de bot que puede asumir tareas antes de que llegue a un operador humano. Esto forma parte del reparto mixto bot/humano del sistema operativo. Si el bot no puede resolver, libera la tarea para que un humano la tome. Esto puede volver difícil rastrear "quién movió" realmente un pedido si no se mira la secuencia completa de estados.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Qué operaciones están restringidas para pedidos creados desde deals?

**Respuesta corta**: No se pueden agregar destinos manualmente (`add_destinations`) en pedidos de deals-bag. Otras acciones también pueden tener restricciones específicas.

**Contexto**: `AddDirectTransfers` verifica el origen del pedido antes de ejecutar. Los pedidos creados vía `DealsBag` tienen sus `directTransfers1` generados por el proceso de matching del bag, y no admiten la misma reasignación manual que un pedido creado desde dashboard. Si se intenta forzar, la acción puede fallar y dejar el pedido en `TO_FUTURE_READY`.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`, `02_Flows/deals-and-direct-transfer-matching/`

---

## ¿Qué pasa cuando un operador deja texto desde el panel?

**Respuesta corta**: Depende del tipo de texto: el texto privado queda solo en el sistema interno; el texto público altera el chat visible por el usuario y puede abrir el canal de chat.

**Contexto**: `PanelTaskReplyTextController` permite dejar texto privado o público. Cuando el texto es público, `HandlePublicTextObserver` puede abrirle el chat al usuario y crear una tarea nueva para otro operador. Una respuesta de panel no es solo documentación interna — puede cambiar activamente la experiencia del usuario en tiempo real.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Qué pasa cuando una acción operativa falla?

**Respuesta corta**: Muchos pipelines tienen fallback a `HELD`. Un intento fallido puede dejar el pedido retenido en lugar de volver al estado anterior.

**Contexto**: Los pipelines de tareas son secuencias de intentos controlados, no mutaciones directas. Por ejemplo, `cancel` valida primero si hay pago o validación en progreso; si no puede cerrar limpio, puede terminar en `HELD`. `credit` y `credit_reset` intentan varias estrategias antes de caer a `HELD`. Esto significa que una intervención fallida puede generar más trabajo, no menos.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Cómo puede operaciones ajustar el monto de un pedido antes de acreditarlo?

**Respuesta corta**: Usando `AdjustAndCreditWithDirectTransfers`, que elimina destinos no enviados, recalcula montos y acredita si el resultado es válido.

**Contexto**: Esta acción permite que operaciones reconfigure económicamente un pedido antes de cerrarlo. Elimina los `directTransfers1` que no fueron enviados, ajusta los montos correspondientes, valida que el pedido siga siendo acreditable con los nuevos valores y, si todo cierra, mueve la transacción a `CREDITED_PAYMENT`. Es una de las acciones de mayor impacto económico disponibles en panel.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Cuándo puede un pedido recuperar destinos que fueron eliminados?

**Respuesta corta**: Cuando se ejecuta la acción `recover` — recupera `directTransfers` eliminados y devuelve el pedido a un estado de revisión si el resultado es válido.

**Contexto**: `RecoverDirectTransfers` existe para casos donde el pedido llegó a un estado bloqueado con destinos borrados (por cancelación parcial, disputa o hold) pero la situación operativa permite intentar retomarlo. Los pedidos creados con deals-bag están explícitamente excluidos de esta lógica de recuperación. La recuperación depende de jobs en background y de que el operador ejecute la acción correspondiente.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`, `02_Flows/cancellation-held-mediation-recovery/`

---

## ¿Cómo se cierra el chat de una transacción desde el panel?

**Respuesta corta**: A través del endpoint `/panel/state-chips/close-chat/{transaction_id}/{transaction_mid}`, manejado por `ChatController`.

**Contexto**: El cierre de chat desde panel es una acción operativa explícita, no ocurre automáticamente al completar una tarea. Esto permite que operaciones cierre el canal de comunicación cuando la intervención terminó, sin que el usuario pueda seguir enviando mensajes. Es distinto al comportamiento automático de reset de chips por cambio de estado.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`, `02_Flows/chat-state-chips-and-support-actions/`

---

## ¿Cómo se mueve un pedido a mediación?

**Respuesta corta**: El operador ejecuta la acción `to_mediation` desde panel, lo que corre el pipeline `ToMediation` y cambia el estado de la transacción.

**Contexto**: La mediación no es solo un estado — implica que hay una disputa activa que requiere revisión. El pipeline `ToMediation` puede incluir notificaciones, creación de nuevas tareas y registro de observaciones. Desde mediación, la resolución puede ser liberar el pedido de vuelta a `WAITING_PAYMENT` o `CREDITED_PAYMENT` si se determina que la recepción fue exitosa, o cancelar si no.

**Fuente**: `02_Flows/cancellation-held-mediation-recovery/`, `02_Flows/operator-interventions-and-panel-actions/`

---

## ¿Por qué a veces no es claro quién movió un pedido?

**Respuesta corta**: Porque el sistema mezcla acciones de usuarios, bots, reglas automáticas y operadores humanos sobre los mismos estados y tareas.

**Contexto**: Una transacción puede ser movida por: el usuario (acción directa), un background job (cancelación automática), un bot (tarea temporal), un listener de riesgo (HELD por PIX inválido) o un operador humano (panel). Si no se mira la secuencia completa de `States` y `Tasks`, la cadena de causas no es obvia. Para auditar correctamente hay que cruzar estados, tareas y logs de jobs.

**Fuente**: `02_Flows/operator-interventions-and-panel-actions/`, `02_Flows/cancellation-held-mediation-recovery/`
