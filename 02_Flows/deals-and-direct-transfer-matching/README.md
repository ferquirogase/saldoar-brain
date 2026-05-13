# Deals And Direct Transfer Matching

## Metadata

- `flow_id`: `flow-deals-and-direct-transfer-matching`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar pasa de "ver ofertas" a "armar una bolsa", y de ahi a una transaccion con destinos asignados. Este flujo ayuda a entender por que algunos pedidos nacen ya con instrucciones concretas y otros no.

## Por que importa

Este flujo cruza producto, operacion, soporte y marketing:

- explica que significan realmente las ofertas visibles
- muestra que la `deals bag` es un pre-pedido con vida propia
- aclara cuando una bolsa se transforma en transaccion real
- conecta discovery publico con operacion autenticada

Si esto no esta claro, es facil confundir:

- oferta publica
- bolsa de ofertas
- transaccion creada
- instruccion de pago

## Entry Points

### Discovery publico

- landing con `public deals`
- wiki de deals
- landings por sistema

### Dashboard autenticado

- `/my/dashboard/deals`

### Salida del flujo

- `/my/dashboard/transactions/v3/{transactionId}/instructions`

## Frontstage

### 1. Capa publica: ver que hay disponibilidad

El front muestra `public_deals` como una capa de discovery.

Esa capa:

- sirve para comunicar oportunidad
- no crea una transaccion por si sola
- puede derivar a login si el usuario no esta autenticado
- empuja al dashboard de deals para operar de verdad

### 2. Dashboard de deals: armar una bolsa

En dashboard aparece la `deals bag`.

La bolsa funciona como un contenedor temporal de ofertas seleccionadas:

- el usuario agrega uno o varios `deals`
- el sistema fija `group_id`
- se eligen cuentas de envio y recepcion si hacen falta
- se calcula cuanto envia y cuanto recibe
- hay un timer de expiracion

La bolsa no es todavia la transaccion operativa final, pero ya guarda estado en backend.

### 3. Confirmacion: pagar la bolsa

Cuando el usuario confirma:

- la bolsa pasa a `filled`
- el front envia `amount2`
- si hay una sola oferta, puede aparecer un modal para sugerir agregar mas
- si backend acepta, el front navega directo a instrucciones de la transaccion creada

## Backstage

### La bolsa es un recurso persistido

`DealsBag` no es un estado local del navegador.

Backend la trata como un recurso con:

- `filling`
- `filled`
- `completed`
- `expired`
- `canceled`

Tambien tiene:

- `transaction_id`
- `instructions_url`
- `expired_at`
- relaciones con `deals`, `account` y `send_account`

### Restricciones antes de crear o seguir usando una bolsa

Al crear o guardar una bolsa, backend controla:

- demasiadas bolsas expiradas recientes
- demasiadas bolsas canceladas o expiradas en 24 horas
- pagos anteriores sin marcar correctamente
- que no haya otra bolsa `filling` o `filled` en proceso para ese usuario
- que el estado inicial valido sea `filling`
- que la cuenta de recepcion pertenezca al usuario
- que una bolsa `filled` sin balance tenga cuenta de recepcion

Hay una idea importante aca: Saldoar no deja operar bolsas paralelas libremente.

### Penalizaciones y bloqueos detectados

#### 1. Exceso de bolsas expiradas en ventana de 3 dias

En la creacion de `DealsBag`, backend cuenta bolsas del usuario con estado `EXPIRED` cuyo `expired_at` sea mayor a `now()->subDays(3)`.

Si el total es mayor a `3`, bloquea con `deals_bag_too_many_expired`.

Esto funciona como una penalizacion por intentos que no llegaron a concretarse dentro de una ventana corta.

#### 2. Exceso de bolsas canceladas o expiradas en 24 horas

En `MaxCanceledDealsBags`, backend cuenta `DealsBag` del usuario con estado `CANCELED` o `EXPIRED` creadas despues de `now()->subDay()`.

Si el total es mayor a `10`, bloquea con `max_canceled_deal_bags`.

Esto no mide solo expiraciones: tambien contempla cancelaciones recientes y opera como freno anti-abuso o anti-friccion repetida.

#### 3. Pagos anteriores no marcados

Antes de dejar crear una bolsa, `PreviousDirectTransfersAreMarked` busca transacciones recientes del usuario que:

- fueron creadas en los ultimos `5` dias
- tienen `received = true`
- tienen `directTransfers2.received = UNKNOWN`
- tienen `sent_at` anterior a `15` minutos
- y `directTransfers2.created_at` dentro de los ultimos `3` dias

Si encuentra una, bloquea con `previous_payments_unmarked`.

La logica de fondo es: si el usuario ya tiene pagos previos sin cerrar o sin marcar correctamente, Saldoar puede impedirle seguir operando ofertas.

#### 4. Bloqueos adicionales que impactan el flujo

Al crear una bolsa tambien pasan pipes que pueden cortar el flujo por:

- transacciones en `held` o `disputed`
- validaciones en progreso
- exceso de bolsas canceladas / expiradas
- pagos anteriores sin marcar

No todo esto es una "penalizacion" en sentido estricto, pero si son frenos reales para operar deals.

### Expiracion y liberacion

La bolsa tiene un tiempo de vida de 15 minutos.

Si vence:

- si tenia deals, pasa a `expired`
- si estaba vacia, pasa a `canceled`

Ademas, si una bolsa quedo `filled` pero su transaccion no prospero o fue cancelada, un comando de release la puede mover a `expired`.

### Conversion de bolsa a transaccion

Cuando la bolsa pasa de `filling` a `filled`, un observer crea la transaccion.

Ese proceso:

- construye una `Transaction`
- toma `system1` segun el `group_id`
- define `system2` segun cuenta destino o balance
- asocia `sendAccount` y `account`
- convierte cada `hunted_deal` en un `direct_transfer`
- calcula `amount1` y `amount2`
- corre evaluacion de riesgo
- valida caida de tasa y monto minimo

Si todo cierra:

- guarda la transaccion
- guarda `directTransfers1`
- vincula la bolsa a `transaction_id`
- mueve la transaccion a `WAITING_PAYMENT`
- notifica al usuario

O sea: en este flujo la transaccion no pasa por "buscar destino mas tarde". Nace ya con destinos concretos.

### Relacion con instrucciones

Cuando la conversion sale bien:

- el front termina en la pantalla de instrucciones
- la transaccion ya esta en `WAITING_PAYMENT`
- las instrucciones vienen de los `directTransfers1` creados desde la bolsa

Esto explica por que el flujo de deals se siente mas directo que otros pedidos: llega a instrucciones con matching ya resuelto.

### Sincronizacion de estado bolsa <-> transaccion

Cuando cambia el estado de la transaccion, un listener actualiza la bolsa asociada.

Reglas detectadas:

- `SENT`, `PRE_APPROVED_SENT`, `MEDIATION` => `completed`
- `CANCELED`, `TO_NEW_TICKET` => `expired` o `canceled` segun si se habian leido instrucciones

Entonces la bolsa funciona como un espejo resumido del estado del pedido que genero.

## Trazabilidad Tecnica

### Front

- offers publicas: `solido/apps/solido-app/src/app/landing-page/components/public-deals/public-deals.component.ts`
- recurso `deals_bags`: `solido/apps/solido-app/src/app/core/resources/deals-bag.ts`
- recurso `deal`: `solido/apps/solido-app/src/app/core/resources/deal.ts`
- modulo dashboard deals: `solido/apps/solido-app/src/app/dashboard/deals/deals.module.ts`
- vista de bolsas: `solido/apps/solido-app/src/app/dashboard/deals/deals-bags/deals-bags.component.ts`
- servicio principal de bolsa: `solido/apps/solido-app/src/app/dashboard/deals/deals-bag-filling.service.ts`

### Back

- observer de creacion de transaccion: `saldo/app/Transactions/Deals/DealsBag/DealsBagCreateTransactionWhenIsFilledObserver.php`
- processor bolsa -> transaccion: `saldo/app/Transactions/Deals/DealsBag/DealsBagToTransactionProcessor.php`
- observer de validaciones generales: `saldo/app/Transactions/Deals/DealsBag/DealsBagObserver.php`
- estados de bolsa: `saldo/app/Transactions/Deals/DealsBag/DealsBagStatusEnum.php`
- comando de release: `saldo/app/Transactions/Deals/DealsBag/DealsBagsReleaseCommand.php`
- sincronizacion por estado de transaccion: `saldo/app/Transactions/Deals/DealsBag/UpdateDealsBagStatusListener.php`
- punto de llegada posterior: `saldo/app/Transactions/Jobs/TransactionNextStepUseCase.php`

## Reglas de Negocio Detectadas

### Oferta publica no implica reserva real

`public_deals` sirve para mostrar oportunidad, pero la operacion real empieza cuando el usuario arma una `deals bag`.

### La bolsa es una reserva operativa temporal

La `deals bag` ya representa una intencion operativa seria:

- ocupa ofertas
- tiene expiracion
- puede bloquear nuevas bolsas
- exige consistencia de cuentas y riesgo
- hereda bloqueos por comportamiento reciente del usuario

### El matching viene antes de instrucciones

En este flujo los destinos se fijan al crear la transaccion desde la bolsa.

Por eso el usuario cae a instrucciones ya con `directTransfers1` listos.

### No todas las transacciones siguen el mismo camino

Este flujo no es el mismo que un pedido generico que luego intenta encontrar `agreement` o `direct transfer`.

En deals, el matching ya viene "prearmado" desde los `hunted_deals`.

### El tiempo importa

Hay logica de expiracion y recuperacion.
Si el usuario deja la bolsa abierta o el pedido no avanza, el sistema limpia y libera.

## Lo que este flujo ya permite responder

- Que diferencia hay entre una oferta publica y una operacion real.
- Que es una `deals bag`.
- Cuando se crea de verdad una transaccion desde ofertas.
- Por que el flujo de deals puede llegar directo a instrucciones.
- Que restricciones tiene un usuario para abrir o mantener bolsas.
- Que penalizaciones por comportamiento reciente pueden bloquear el flujo.
- Como se relacionan los estados de la bolsa con la transaccion final.

## Edge Cases / Riesgos

- El front trata la bolsa como experiencia fluida, pero backend la corta por riesgo, expiracion o conflictos de estado.
- Hay desalineacion potencial entre lo que el usuario "ve disponible" en publico y lo que realmente puede cerrar al confirmar.
- Una bolsa `filled` puede terminar expirada si la transaccion no prospera.
- El flujo mezcla discovery, reserva temporal y pedido real; eso puede confundir copy y soporte.
- Usuarios con bajo nivel no parecen entrar al dashboard deals de la misma forma que niveles mas altos.
- Los bloqueos usan ventanas temporales distintas: 24 horas, 3 dias, 5 dias y 15 minutos.
- Algunas restricciones se sienten para el usuario como "no me deja operar", aunque tecnicamente provengan de pagos anteriores o validaciones en curso.

## Unknowns

- Documentar mejor como se construyen exactamente los `hunted_deals`.
- Mapear el origen preciso de `public_deals` y su relacion con disponibilidad real.
- Confirmar todas las reglas de nivel de usuario para acceso y visibilidad de deals.
- Entender mejor cuando `instructions_url` de la bolsa se usa frente a la navegacion directa por `transaction_id`.

## Fuentes

- `solido/apps/solido-app/src/app/landing-page/components/public-deals/public-deals.component.ts`
- `solido/apps/solido-app/src/app/dashboard/deals/deals-bags/deals-bags.component.ts`
- `solido/apps/solido-app/src/app/dashboard/deals/deals-bag-filling.service.ts`
- `solido/apps/solido-app/src/app/core/resources/deals-bag.ts`
- `solido/apps/solido-app/src/app/core/resources/deal.ts`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagObserver.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagPassPipesWhenIsCreatingObserver.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagCreateTransactionWhenIsFilledObserver.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagToTransactionProcessor.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagsReleaseCommand.php`
- `saldo/app/Transactions/Deals/DealsBag/DealsBagStatusEnum.php`
- `saldo/app/Transactions/Jobs/EvaluatorPipes/MaxCanceledDealsBags.php`
- `saldo/app/Transactions/Jobs/EvaluatorPipes/PreviousDirectTransfersAreMarked.php`
- `saldo/app/Transactions/Deals/DealsBag/UpdateDealsBagStatusListener.php`
