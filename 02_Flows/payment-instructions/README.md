# Payment Instructions

## Metadata

- `flow_id`: `flow-payment-instructions`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar muestra al usuario las instrucciones para completar un pedido, como se estructuran segun el tipo de operacion y que acciones o efectos internos se disparan cuando el usuario entra, marca envios o no puede pagar.

## Por que importa

Este flujo es uno de los mas sensibles para UX y operacion porque concentra:

- comprension del paso a paso
- carga cognitiva del pago
- confirmacion de "ya envie"
- recuperacion cuando el usuario no puede pagar
- disparadores internos de seguimiento

Tambien es una fuente directa de informacion para soporte, porque aca nacen muchas dudas de "que tengo que hacer ahora".

## Entry Points

### Publico por deep link

- `/t/transactions/v3/{transactionId}/{transactionKey}/{transactionMid}/instructions`

### Dashboard autenticado

- `/my/dashboard/transactions/v3/{transactionId}/instructions`

### Redirecciones internas desde otras funciones

- balances / withdraw / deposit / transfer / swap redirigen a la ruta de instrucciones de la transaccion creada

## Frontstage

La pantalla principal vive en `ui/pages/instructions` y se arma sobre el `Transaction` actual.

La composicion visual depende del contenido de la transaccion:

- helpers superiores e inferiores
- sector de envio
- sector de recepcion
- bonus por lado si aplica

### Variantes del sector de envio

#### 1. Balance

Si `system1.id === balance`, el flujo usa `balance-instructions`.

#### 2. Agreement / QR

Si la transaccion tiene `agreement1_id`, el flujo entra por `transfer-agreement-container` y muestra QR de pago.

El QR se pide con `mercadopagoqr`.
Cuando el usuario indica que ya pago (`qrPaid`), el front oculta el QR y marca localmente ese estado con `MarketAtSendService`.

#### 3. Direct transfers fiat

Si no hay acuerdo, el front entra por `direct-transfer1-container`.

Ese contenedor:

- pide `direct_transfers1` de la transaccion
- incluye `direct_transfer_actions`
- filtra comportamientos visibles
- identifica la tarjeta activa pendiente
- emite la cantidad de transferencias para ajustar copy y layout

Dentro de cada direct transfer, el usuario puede:

- marcarla como enviada
- abrir ayuda si no puede pagar
- seguir un link legacy de PayPal en ciertos casos
- proponer accion alternativa via `direct_transfer_actions`

#### 4. Crypto

Para sistemas crypto existe un componente especifico que:

- resuelve direcciones de envio
- construye QR a partir de address, currency y amount
- permite abrir QR fullscreen
- permite marcar como enviado
- hace polling periodico de la transaccion para refrescar `marked_as_sent`

### Sector de recepcion

El sector de recepcion usa `direct-transfer2-container`.

Ese bloque:

- carga `direct_transfers2`
- incluye `files`
- arma subtitulos distintos segun cantidad y estado de recepcion
- muestra feedback distinto para fiat, crypto y VCC

### Lectura UX para VCC en recepcion

Cuando el destino es `VCC`, el sector de recepcion no deberia prometer una "recepcion de saldo" en la tarjeta.

Lo confirmado por las otras ramas del sistema es:

- VCC tiene una etapa propia de generacion de tarjeta
- despues muestra instrucciones para cargar esa tarjeta en PayPal
- luego puede mostrar o pedir un codigo de verificacion

Por eso, si en `direct-transfer2-container` o en el stepper aparecen textos como:

- `Recibiras tu saldo en tu cuenta`
- `Recibes tu saldo en tu cuenta`
- `Enviando tu saldo`

esa semantica entra en conflicto con el flujo real de VCC.

Lectura operativa recomendada:

- la VCC funciona como instrumento de verificacion para PayPal
- Saldoar no le acredita saldo al usuario dentro de la VCC como si fuera un destino final comun
- el copy de esta rama deberia hablar de generar, entregar, cargar o verificar la tarjeta, no de "enviar saldo a la tarjeta"

## Backstage

### Lectura de instrucciones

Hay dos mecanismos relevantes cuando el usuario entra a instrucciones:

#### Pixel oculto

La UI renderiza una imagen de 1x1 con `pixelUrl`.

El backend atiende eso en `TransactionPixelController` y trata de ejecutar `MarkInstructionsReadUseCase`.

#### Lectura al pedir direct transfers

Cuando se listan `direct_transfers1`, el `DirectTransfer1Policy` tambien intenta ejecutar `MarkInstructionsReadUseCase` si:

- `instructions_read_at` es `null`
- el estado de la transaccion es `WAITING_PAYMENT`

Esto sugiere que leer instrucciones no depende solo de la pagina abierta, sino tambien de tocar recursos concretos del flujo.

### Efectos de `MarkInstructionsReadUseCase`

Cuando aplica:

- setea `instructions_read_at`
- guarda un state interno oculto para el usuario
- agenda `DirectTransferVisitedButDontPaidJob` con debounce

Eso es importante porque "ver instrucciones" tiene consecuencias operativas y potencialmente de remarketing o seguimiento.

### Helpers dinamicos

La pantalla consulta `transaction_helpers` para mostrar mensajes contextuales con severidad, titulo y mensaje.

Los helpers salen de `HelpersContainerRepository` en backend y agrupan distintas reglas, por ejemplo:

- screenshots requeridos
- validacion requerida
- confirmacion de pago recibido
- destinos no disponibles
- accion requerida por operador

### Datos temporales y URLs

El backend tambien tiene piezas ligadas a instrucciones:

- `TransactionTemporalValuesService`: expone `instructions_url` para casos crypto y falla si hay validacion en progreso
- `transaction_instructions_redirect_urls`
- `transaction_link_instructions`

Eso indica que el flujo de instrucciones no es una sola vista fija; tambien puede depender de URLs generadas o temporales.

## Trazabilidad Tecnica

### Front

- pantalla principal: `solido/apps/solido-app/src/ui/pages/instructions/instructions.component.ts`
- template principal: `solido/apps/solido-app/src/ui/pages/instructions/instructions.component.html`
- helpers y formateo: `solido/apps/solido-app/src/ui/pages/instructions/instructions-view-model.service.ts`
- agreement QR: `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement.component.ts`
- agreement QR VM: `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement-view-model.service.ts`
- direct transfers de envio: `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1-container/direct-transfer1-container.component.ts`
- accion sobre transfer pendiente: `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1/direct-transfer1-active/direct-transfer1-active-view-model.service.ts`
- direct_transfers1 fetch: `solido/apps/solido-app/src/domain/use-cases/search-all-direct-transfer1-use-case.ts`
- direct_transfers2 fetch: `solido/apps/solido-app/src/domain/use-cases/list-direct-transfer2-use-case.ts`
- accion alternativa: `solido/apps/solido-app/src/domain/use-cases/send-direct-transfer-action-use-case.ts`
- crypto: `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-crypto/transfer-crypto.component.ts`
- QR agreement: `solido/apps/solido-app/src/domain/use-cases/search-qr-agreement-use-case.ts`

### Back

- API principal: `saldo/routes/api.php`
- `direct_transfer_actions`: `saldo/app/Transactions/DirectTransfers/DirectTransferController.php`
- pixel de lectura: `saldo/app/Transactions/Http/TransactionPixelController.php`
- politica de lectura al listar direct transfers: `saldo/app/Transactions/DirectTransfers/DirectTransfer1Policy.php`
- marcar instrucciones leidas: `saldo/app/Transactions/Transactions/UseCases/MarkInstructionsReadUseCase.php`
- temporal values / `instructions_url`: `saldo/app/Transactions/TransactionTemporalValues/TransactionTemporalValuesService.php`
- helpers: `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperService.php`

## Reglas de Negocio Detectadas

### `beforepath`

El flujo usa dos namespaces de API:

- dashboard: `users/{userId}`
- publico: `t`

Luego algunos casos agregan `/transactions/{transactionId}` arriba del recurso concreto.

### Los helpers son parte de la experiencia, no decoracion

La pantalla no solo muestra instrucciones transaccionales.
Tambien muestra mensajes condicionados por reglas backend.

Eso significa que dos usuarios con el "mismo" paso pueden ver ayudas distintas.

### Leer instrucciones dispara seguimiento interno

`instructions_read_at` no es un detalle pasivo.
Se usa en backend para:

- jobs de seguimiento
- pipes de cancelacion
- ETL de marketing
- oportunidades smart

### Direct transfer 1 filtra comportamientos

No todo `direct_transfer1` se muestra igual.
El front filtra por comportamientos como:

- `READ`
- `UNREAD`
- `REMOVED_READ`
- `LEGACY_UNREAD`

Y separa los removidos del resto.

### "No puedo pagar" no es solo un mensaje

Cuando el usuario abre ayuda y elige una accion alternativa:

- el front manda `transfer_id`
- manda `direct_transfer_action`
- opcionalmente `new_remaining_amount`
- backend aplica `ApplyDirectTransferActionUseCase`

## Lo que este flujo ya permite responder

- Que variantes de instrucciones puede ver un usuario segun el tipo de pedido.
- Como se diferencia una instruccion por acuerdo, fiat directo, balance o crypto.
- Donde se marca que el usuario leyo las instrucciones.
- Que consecuencias internas tiene esa lectura.
- Como se obtienen los helpers contextuales.
- Como funciona el camino de "ya envie" y el de "no puedo pagar".
- Por que soporte puede ver fricciones distintas aunque el pedido este en el mismo paso.

## Edge Cases / Riesgos

- La lectura de instrucciones puede dispararse por pixel y tambien por acceso a `direct_transfers1`; hay doble camino.
- El estado de "mark as sent" en agreement/crypto parece tener parte de persistencia local en front; conviene validar la persistencia real end-to-end.
- Hay mezcla de recursos JSON:API, endpoints custom y servicios legacy.
- El flujo usa muchos componentes especializados; pequeños cambios pueden romper solo una variante sin afectar las otras.
- `transaction_helpers` puede cambiar mucho la UX sin que el diseño base cambie.

## Unknowns

- Confirmar la persistencia exacta de `MarketAtSendService` y su relacion con backend.
- Documentar el catalogo real de `direct_transfer_action`.
- Mapear la salida exacta de `ApplyDirectTransferActionUseCase`.
- Entender cuando se usa `transaction_instructions_redirect_urls` versus la UI principal de instrucciones.
- Documentar mejor el branch de `balance-instructions`.

## Fuentes

- `solido/apps/solido-app/src/ui/pages/instructions/instructions.component.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/instructions.component.html`
- `solido/apps/solido-app/src/ui/pages/instructions/instructions-view-model.service.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement.component.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-agreement/transfer-agreement-view-model.service.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1-container/direct-transfer1-container.component.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1/direct-transfer1-active/direct-transfer1-active-view-model.service.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/transfer-crypto/transfer-crypto.component.ts`
- `solido/apps/solido-app/src/domain/use-cases/search-all-direct-transfer1-use-case.ts`
- `solido/apps/solido-app/src/domain/use-cases/list-direct-transfer2-use-case.ts`
- `solido/apps/solido-app/src/domain/use-cases/send-direct-transfer-action-use-case.ts`
- `solido/apps/solido-app/src/domain/use-cases/search-qr-agreement-use-case.ts`
- `saldo/routes/api.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransferController.php`
- `saldo/app/Transactions/Http/TransactionPixelController.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransfer1Policy.php`
- `saldo/app/Transactions/Transactions/UseCases/MarkInstructionsReadUseCase.php`
- `saldo/app/Transactions/TransactionTemporalValues/TransactionTemporalValuesService.php`
- `saldo/app/Transactions/TransactionHelpers/TransactionHelperJsonApi/TransactionHelperService.php`
