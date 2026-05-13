# Sockets and Websocket

## Simple Definition
`Sockets / Websocket` es la capa de tiempo real que Saldoar usa para empujar cambios desde backend hacia `solido`.

No es una fuente paralela de negocio. Es una capa de entrega:

- anuncia cambios de transacciones
- anuncia cambios de validaciones
- anuncia cambios de usuario
- anuncia cambios publicos como `systems` y `best_rates`

El front despues decide si muta el recurso recibido, refresca partes de la UI o vuelve a consultar.

## Why It Matters
Importa porque muchas cosas del producto parecen “magicas” si no se ve esta capa:

- el estado del pedido cambia sin refresh manual
- una validacion puede verse aprobada mientras la pantalla sigue abierta
- el dashboard puede reaccionar a cambios de usuario
- systems y mejores cotizaciones pueden cambiar en vivo

Sin esta lectura, soporte o UX pueden confundir:

- bug visual
- estado demorado
- falta de refresh
- desconexion de socket

## Channel Model
En lo mapeado aparecen tres familias principales:

1. canal publico `solido`
2. canal privado de usuario `users.{user_id}`
3. canal privado de transaccion `t.{transaction_id}`

Tambien aparece `u.{user_id}` en backend, aunque la superficie principal de `solido` hoy usa `users.{id}`.

## Main Backend Surface

- `saldo/routes/channels.php`
- `saldo/app/Core/Broadcasting/Internal/BroadcastableEvent.php`
- `saldo/app/Core/Events/Solido/TransactionPrivateEvent.php`
- `saldo/app/Core/Events/Solido/SystemsUpdatedEvent.php`
- `saldo/app/Core/Events/Solido/BestRatesUpdatedEvent.php`
- `saldo/routes/api-guest.php`

## Main Frontend Surface

- `solido/apps/solido-app/src/app/socket/web-socket.ts`
- `solido/apps/solido-app/src/app/socket/services/jsonapi-websocket.service.ts`
- `solido/apps/solido-app/src/app/socket/services/transaction-socket.service.ts`
- `solido/apps/solido-app/src/app/socket/services/user-socket.service.ts`
- `solido/apps/solido-app/src/app/socket/services/public-socket.service.ts`

Superficies consumidoras importantes:

- `transaction-details`
- `instructions`
- `dashboard`
- `transaction-list`
- `create-validation`
- `home` y `home-step-b`

## How It Works

### Public channel
`PublicSocketService` escucha el canal `solido`.

Eventos publicos ya visibles:

- `systems`
- `best_rates`

En SSR, `SSrSocketService` incluso cachea esos payloads para hidratar mejor ciertas vistas.

### User private channel
`UserSocketService` se autentica contra `broadcasting/auth` con `Bearer access_token` y escucha `users.{user_id}`.

Se usa sobre todo desde `dashboard`, donde eventos de usuario se empujan a `JsonapiWebsocketService`.

### Transaction private channel
`TransactionSocketService` se autentica contra `t/broadcasting/auth` usando:

- `transaction-key`
- `transaction-mid`

y escucha `t.{transaction_id}`.

Esto explica por que una transaccion publica puede actualizarse en vivo sin login tradicional.

## Payload Model
La pieza central del front es `JsonapiWebsocketService`.

Esa capa:

- recibe eventos crudos
- distingue recurso individual vs coleccion
- convierte payloads a recursos JSON:API
- expone observables como `onResource()` y `onDocumentCollection()`

Eso hace que componentes distintos reaccionen sin conocer Pusher o Echo directamente.

## What It Triggers

- cambio live de transacciones abiertas
- cambio live de validaciones
- cambio live de listas de transacciones
- actualizacion live de systems y best rates
- reconexion automatica si el socket cae o entra en error

## Important Product / Ops Reading

- La UI en tiempo real no siempre “calcula”: muchas veces solo refleja un evento ya procesado en backend.
- Si el socket falla, algunas pantallas siguen funcionando, pero con informacion mas vieja hasta próximo fetch manual.
- En transaccion publica, la autorizacion no usa token de usuario sino `transaction-key` y `transaction-mid`.
- `BroadcastableEvent` puede mandar el mismo recurso a `t.{id}` y `users.{id}`; eso reduce desalineaciones entre vista publica y dashboard.
- `systems` y `best_rates` viajan por canal publico; por eso calculadora y home pueden actualizarse sin login.

## Failure Or Friction Modes

- auth fallida del canal privado
- desconexion del websocket
- reconexion tardia y UI desfasada
- evento emitido pero no escuchado por el componente actual
- payload live que actualiza un recurso pero no toda la UI derivada
- subscripcion al contexto equivocado, por ejemplo dashboard vs transaccion publica

## Questions This Integration Helps Answer

- por que una transaccion cambia sola sin refrescar
- como se actualiza en vivo el estado del pedido
- que canal usa una transaccion publica
- por que systems o best rates cambian sin reload
- como entra una validacion aprobada al front
- que pasa si se corta el websocket

## Main References

- `saldo/routes/channels.php`
- `saldo/app/Core/Broadcasting/Internal/BroadcastableEvent.php`
- `saldo/app/Core/Events/Solido/TransactionPrivateEvent.php`
- `saldo/app/Core/Events/Solido/SystemsUpdatedEvent.php`
- `saldo/app/Core/Events/Solido/BestRatesUpdatedEvent.php`
- `solido/apps/solido-app/src/app/socket/web-socket.ts`
- `solido/apps/solido-app/src/app/socket/services/jsonapi-websocket.service.ts`
- `solido/apps/solido-app/src/app/socket/services/transaction-socket.service.ts`
- `solido/apps/solido-app/src/app/socket/services/user-socket.service.ts`

## Evidence Level

- `confirmed`
