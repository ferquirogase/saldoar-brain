# FAQ — Producto

Preguntas sobre reglas de negocio, decisiones de diseño del sistema y por qué las cosas funcionan como funcionan.

---

## ¿Por qué hay un límite de pedidos concurrentes en WAITING_PAYMENT?

**Respuesta corta**: Para reducir el riesgo operativo de que un usuario tenga múltiples pagos en curso simultáneamente sin capacidad de seguimiento.

**Contexto**: El límite es dinámico: `max(2, user.level + 1)`. Usuarios con más historial tienen mayor tolerancia. Cuando se supera, el sistema preserva el pedido más reciente (o el que tuvo instrucciones leídas más recientemente) y mueve los otros a `TO_NEW_TICKET`. El usuario ve el copy de "pedido omitido" sin necesariamente entender la causa técnica.

**Fuente**: `02_Flows/concurrent-orders-and-omitted-transactions/`

---

## ¿Por qué el sistema puede cancelar un pedido sin que el usuario lo pida?

**Respuesta corta**: Porque el backend tiene comandos automáticos que evalúan pedidos viejos sin actividad y los cancelan o retienen según criterios de tiempo y actividad reciente.

**Contexto**: Hay dos pipelines: uno para pedidos sin `directTransfers1` y otro para pedidos con `directTransfers1`. Ambos evalúan ventanas de tiempo, variación de tasas y actividad reciente (lectura de instrucciones, transferencias recientes). Si el pedido cumple las condiciones de inactividad, puede pasar a `CANCELED` o `HELD` automáticamente sin acción del usuario.

**Fuente**: `02_Flows/cancellation-held-mediation-recovery/`

---

## ¿Por qué cambiar la cuenta de destino puede generar un pedido nuevo en vez de editar el existente?

**Respuesta corta**: Porque `ChangeDestinationAddress` en algunos casos divide el flujo operativo en una nueva transacción en lugar de modificar la existente en el lugar.

**Contexto**: Esto ocurre cuando el cambio de destino implica reorganizar los `directTransfers` de forma que no sea posible hacerlo sobre el pedido original sin perder consistencia. Desde el punto de vista del usuario se ve como "crear otro pedido", pero técnicamente es una reorganización operativa. Es uno de los edge cases más difíciles de comunicar.

**Fuente**: `02_Flows/accounts-and-destination-selection/`

---

## ¿Por qué el mismo tipo de pedido se comporta diferente según el sistema (crypto, PIX, VCC, PayPal)?

**Respuesta corta**: Porque Saldoar es una interfaz única que opera sobre múltiples sub-productos con reglas, notificaciones y flujos distintos según el mercado o método de pago.

**Contexto**: El `system1` y `system2` de cada transacción determinan qué rama del core se activa. Crypto tiene confirmación de red y screenshot diferente. PIX valida la clave externamente y puede ir a HELD si es inválida. VCC tiene una etapa de pre-aprobación y código de carga. PayPal tiene fricción extra para cuentas nuevas. Tratar todos los sistemas como un flujo genérico produce respuestas de soporte incorrectas.

**Fuente**: `02_Flows/system-specific-branches/`

---

## ¿Por qué los deals tienen expiración de 15 minutos?

**Respuesta corta**: Para garantizar que las tasas y disponibilidades de las ofertas sigan siendo válidas cuando se ejecuta la transacción.

**Contexto**: Los deals representan tasas publicadas en un momento específico. Un `deals_bag` tiene 15 minutos para completarse antes de expirar. Además, el backend bloquea a usuarios con más de 3 bags expirados en los últimos 3 días o más de 10 cancelados/expirados en 24 horas. Esto combina protección de tasa con control de abuso.

**Fuente**: `02_Flows/deals-and-direct-transfer-matching/`

---

## ¿Por qué hay dos mecanismos para marcar instrucciones como leídas (píxel + política de acceso)?

**Respuesta corta**: Para maximizar la cobertura de registro — el píxel captura la apertura por email y la política de acceso captura la apertura directa en la app.

**Contexto**: `MarkInstructionsReadUseCase` se dispara cuando el usuario accede a `directTransfers1` (política de acceso). El píxel (1x1 imagen) se carga cuando el email de instrucciones es abierto. Ambos setean `instructions_read_at`. Tener los dos mecanismos garantiza que el timestamp se registre incluso si el usuario entra por distintos canales. Ese timestamp después dispara el job de recordatorio.

**Fuente**: `02_Flows/payment-instructions/`

---

## ¿Por qué un pedido puede quedar en TO_FUTURE_READY en vez de ir directo a WAITING_PAYMENT?

**Respuesta corta**: Porque en el momento de creación no había ni acuerdo disponible ni destinos de pago asignables para esa transacción.

**Contexto**: `TransactionNextStepUseCase` corre un pipeline: primero verifica si ya está recibido, luego intenta acuerdo, luego intenta `directTransfers`. Si ninguno funciona, la manda a `TO_FUTURE_READY`. Las causas pueden ser validación pendiente, riesgo, variación de tasas o simplemente falta de disponibilidad operativa en ese momento. No es un error — es el estado de espera diseñado.

**Fuente**: `02_Flows/create-transaction-and-next-step/`

---

## ¿Por qué una validación aprobada puede "destrabar" un pedido que estaba parado?

**Respuesta corta**: Porque `ApproveValidationAndSendInstructionsUseCase` reinyecta el pedido al pipeline de siguiente paso cuando se aprueba la validación que lo bloqueaba.

**Contexto**: Hay pedidos que llegaron a `TO_FUTURE_READY` o quedaron bloqueados porque el usuario tenía una validación pendiente requerida. Cuando esa validación se aprueba, el backend devuelve el pedido a `TO_FUTURE` y vuelve a correr `TransactionNextStepUseCase`. Si ahora hay destinos disponibles, el pedido puede pasar directo a `WAITING_PAYMENT`.

**Fuente**: `02_Flows/create-transaction-and-next-step/`

---

## ¿Qué determina si una validación es de usuario o de transacción?

**Respuesta corta**: El tipo de validación. La mayoría son de usuario (`id`, `selfie`, `facebook`, `biometric_id`). Solo `screenshot` es de transacción.

**Contexto**: La diferencia importa porque cambia el `validable` al que se asocia la validación, el scope de bloqueo (bloquea al usuario completo vs. solo esa transacción) y las reglas de creación. Para `screenshot`, las reglas de cantidad de archivos dependen del número de `directTransfers1` de esa transacción específica.

**Fuente**: `02_Flows/identity-validations/`

---

## ¿Por qué existe la abstracción `beforepath`?

**Respuesta corta**: Para que el frontend use el mismo código de comunicación con el backend sin importar si el usuario está autenticado o accede por link público.

**Contexto**: Las rutas públicas (`/t/...`) y las rutas de dashboard (`/my/...`) llaman a endpoints distintos con prefijos distintos. `beforepath` abstrae esa diferencia: en contexto público vale `t`, en contexto dashboard vale `users/{userId}`. Sin esta abstracción, habría que bifurcar la lógica front en múltiples lugares. El riesgo es que oculta diferencias reales de comportamiento entre los dos contextos.

**Fuente**: `02_Flows/transaction-visibility-and-status/`, `02_Flows/payment-instructions/`

---

## ¿Por qué un movimiento de balance aparece en la lista pero no suma al total disponible?

**Respuesta corta**: Porque el depósito está en `PENDING_DEPOSIT` — ese estado está excluido deliberadamente del cálculo del balance general hasta que la transacción sea confirmada.

**Contexto**: El balance general (`BalanceUpdateService`) solo suma entries con status `APPROVED` o `PENDING_WITHDRAWAL`. Un depósito recién creado empieza en `PENDING_DEPOSIT` y pasa a `APPROVED` recién cuando la transacción asociada llega a `CREDITED_PAYMENT` o `SENT`. La lista de movimientos muestra el Entry desde el momento de creación, pero el total disponible no lo refleja hasta que está confirmado. Esto previene que el usuario vea saldo que todavía no fue verificado.

**Fuente**: `02_Flows/balance-entries-and-general-balance/`

---

## ¿Por qué el saldo disponible cae de inmediato al crear un retiro?

**Respuesta corta**: Porque el retiro crea un Entry en `PENDING_WITHDRAWAL`, que sí descuenta del balance general desde el momento de creación — actúa como reserva inmediata.

**Contexto**: A diferencia del depósito, `PENDING_WITHDRAWAL` está incluido en el cálculo del balance general. El saldo queda reservado aunque el retiro todavía no haya sido procesado. Si el retiro se cancela o falla, el Entry pasa a `REJECTED` y el saldo se libera en el próximo recálculo. El recálculo no es periódico — ocurre en cada `save()` de cualquier Entry del usuario para ese sistema.

**Fuente**: `02_Flows/balance-entries-and-general-balance/`

---

## ¿Por qué un slug de landing viejo puede mostrar un sistema diferente al esperado?

**Respuesta corta**: Porque el sistema original fue marcado con `replacement_system_id` y el front lo reemplaza automáticamente al cargar la landing.

**Contexto**: `ReplaceSystemHelper` verifica si el sistema de la URL tiene un `replacement_system_id` activo. Si lo tiene, resuelve el sistema vigente, actualiza la transacción con ese sistema y puede reescribir la URL para mostrar el slug nuevo. Esto mantiene operativos links históricos y campañas viejas sin que el usuario perciba el cambio. La fuente de verdad del reemplazo es siempre el backend — el frontend solo aplica la regla que backend expone en `SystemSchema`.

**Fuente**: `02_Flows/landing-for-systems-and-marketing-preloads/`

---

## ¿Por qué hay notificaciones que llegan con mucho retraso después del evento que las dispara?

**Respuesta corta**: Porque muchas notificaciones pasan por jobs en background con debounce, throttle o lógica de horario laboral antes de enviarse.

**Contexto**: El sistema tiene múltiples familias de notificación: por estado, por evidencia, por CRM/recordatorio y por casos especiales. Cada familia tiene sus propias reglas de timing. Algunos jobs se encolan y se procesan en batch. El `DirectTransferVisitedButDontPaidJob` por ejemplo se scheduleа después de que el usuario lee instrucciones, no inmediatamente. Esto puede hacer que el usuario reciba un email "fuera de contexto".

**Fuente**: `02_Flows/notifications-mails-and-background-jobs/`
