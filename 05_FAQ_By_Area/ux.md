# FAQ — UX

Preguntas sobre comportamiento visible de la interfaz, decisiones de componentes y estados que el usuario experimenta.

---

## ¿Por qué las instrucciones de pago se ven diferente según el tipo de operación?

**Respuesta corta**: Porque la página de instrucciones se arma dinámicamente según el tipo de destino de la transacción, no es una pantalla fija.

**Contexto**: Hay cuatro variantes visuales: transferencia directa (lista de cuentas bancarias), QR de MercadoPago (acuerdo), crypto (dirección + polling de confirmación) y balance. Cada variante usa un componente distinto. El selector es `agreement1_id` y el tipo de `directTransfers1` asignados.

**Fuente**: `02_Flows/payment-instructions/`

---

## ¿Cuándo la pantalla de validación deja de mostrar el uploader y pasa a mostrar estado?

**Respuesta corta**: Cuando la validación ya está en `APPROVED`, `PRE_APPROVED`, `PENDING` o `PROCESSING` — es decir, cuando ya fue enviada y está en proceso.

**Contexto**: El componente `create-validation` siempre busca primero si existe una validación reciente. Si la encuentra en esos estados, muestra la vista de estado en lugar del formulario de carga. El usuario no puede subir una nueva mientras hay una en revisión — el backend también lo bloquea.

**Fuente**: `02_Flows/identity-validations/`

---

## ¿Por qué el chat aparece visible pero no se puede escribir?

**Respuesta corta**: Porque la disponibilidad del chat la controla el backend de forma independiente a si el área de chat se renderiza o no.

**Contexto**: `StateChatService` decide si el chat está habilitado. El front puede mostrar el área de chat (por estado de la transacción) pero el input permanece bloqueado hasta que el backend devuelva `is-chat-available = true`. Son dos condiciones independientes.

**Fuente**: `02_Flows/chat-state-chips-and-support-actions/`

---

## ¿Qué ve el usuario cuando su pedido queda en TO_FUTURE_READY?

**Respuesta corta**: Ve el pedido en un estado de espera sin instrucciones de pago disponibles todavía. En algunos casos se le ofrece chat con alternativas accionables.

**Contexto**: `TO_FUTURE_READY` significa que el backend no encontró ni acuerdo ni destinos disponibles al momento de la creación. No es un error — es un estado operativo válido. Si hay alternativas, `ToFutureReadyOptionsHelper` las arma y `StateChatService` abre el chat. El copy de este estado es crítico para que el usuario no lo interprete como una falla del sistema.

**Fuente**: `02_Flows/create-transaction-and-next-step/`

---

## ¿Por qué los botones (state chips) de un pedido cambian según su estado?

**Respuesta corta**: Porque los chips son seleccionados dinámicamente por el backend según el estado actual de la transacción, el grupo de sistema y un posible chip padre activo.

**Contexto**: No hay un conjunto fijo de chips. `TransactionStateChipsService` selecciona los chips aplicables en cada momento. El mismo estado puede generar chips diferentes si el grupo de sistema o el chip padre cambian. Además, cuando el estado de la transacción cambia, la navegación de chips se resetea.

**Fuente**: `02_Flows/chat-state-chips-and-support-actions/`

---

## ¿Por qué al validar identidad se abre una pantalla externa (Veriff)?

**Respuesta corta**: Porque la validación biométrica (`biometric_id`) usa el servicio Veriff, que corre en su propio iframe y no puede integrarse como un formulario estándar de Saldoar.

**Contexto**: El backend crea una sesión en Veriff y devuelve una `verification_url`. El front incrusta esa URL en un frame. Cuando Veriff termina o el usuario cancela, dispara un evento y el front redirige usando `transaction_instructions_redirect_urls` para volver al flujo de Saldoar. El usuario puede percibir esto como "salir de la app".

**Fuente**: `02_Flows/identity-validations/`

---

## ¿Por qué la validación de screenshot puede fallar aunque el usuario haya subido archivos?

**Respuesta corta**: Porque el backend exige que la cantidad de archivos sea al menos igual a la cantidad de `directTransfers1` activos, y además rechaza archivos duplicados por contenido (MD5).

**Contexto**: Si el usuario subió 2 archivos pero hay 3 destinos de pago, falla por cantidad. Si subió 3 pero 2 son el mismo archivo con distinto nombre, falla por duplicados. Ambas reglas aplican solo a la primera validación `screenshot` de la transacción. Es uno de los errores más difíciles de entender para el usuario sin copy claro.

**Fuente**: `02_Flows/identity-validations/`

---

## ¿Por qué la validación de Facebook no pide subir archivos?

**Respuesta corta**: Porque `facebook` es un tipo de validación especial que no usa el uploader — muestra instrucciones para contactar o agregar a Saldoar en Facebook.

**Contexto**: El componente `create-validation` adapta su contenido según el tipo de validación. Para `facebook` y `biometric_id` se omite el uploader completamente y se muestran flujos alternativos. Esto rompe la expectativa de que "validar" siempre significa "subir un archivo".

**Fuente**: `02_Flows/identity-validations/`

---

## ¿Por qué en el flujo público aparecen datos del usuario pre-completados si nunca se registró?

**Respuesta corta**: Porque Saldoar puede crear o reutilizar silenciosamente una identidad de usuario por email normalizado durante la creación de un pedido público.

**Contexto**: El flujo de creación pública no requiere un registro previo. Si el email ya existe en el sistema, se reutiliza la identidad. Si no, se crea. Esto implica que el usuario puede tener un perfil en Saldoar sin haber pasado por un onboarding explícito. Puede generar confusión cuando el usuario "nunca se registró" pero sus datos aparecen pre-completados.

**Fuente**: `02_Flows/public-order-creation-and-identity-bootstrap/`

---

## ¿Cuándo el helper/banner contextual dentro de la transacción cambia de contenido?

**Respuesta corta**: Cuando cambia el estado de la transacción — el backend devuelve hasta dos helpers priorizados según el estado actual.

**Contexto**: `HelpersContainerRepository` selecciona los helpers aplicables por estado de transacción. Los helpers pueden cambiar completamente el tono y las acciones sugeridas al usuario sin que el diseño de la pantalla cambie. Un mismo pedido puede mostrar helpers muy distintos antes y después de marcar el pago como enviado.

**Fuente**: `02_Flows/payment-instructions/`, `02_Flows/chat-state-chips-and-support-actions/`
