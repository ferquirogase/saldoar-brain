# Identity Validations

## Metadata

- `flow_id`: `flow-identity-validations`
- `status`: `v1`
- `owner_area`: `validations`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar solicita, muestra, procesa y reconsulta validaciones de identidad o respaldo, tanto a nivel usuario como a nivel transaccion.

Este flujo cubre especialmente:

- `id`
- `selfie`
- `facebook`
- `biometric_id`
- `screenshot`

## Por que importa

Las validaciones son una interseccion entre seguridad, soporte, UX y operaciones.

Definen:

- si el usuario puede seguir operando
- que evidencia debe subir
- que copy y estado ve
- si el pedido queda bloqueado o en revision
- que enlace debe recibir por dashboard o por link con key

## Entry Points

### Dashboard autenticado

- `/my/dashboard/validations/{validationTypeId}`

### Link publico/firmado por usuario

- `/u/users/{userId}/{userKey}/{validationTypeId}`

### Disparadores desde flujo de transaccion

- `has-pending-validation`
- links de validacion devueltos por backend
- helpers o states que empujan al usuario a validar

### Ejemplos de documentacion

- `GET /v3/validation_examples/{system_id}/{validation_type_id}`

## Frontstage

El modulo Angular de validaciones vive en `ui/features/validations`.

El componente principal es `app-create-validation`, que recibe:

- `validableType`
- `validableId`
- `validationTypeId`
- `beforepathCreate`
- `beforepath`

Con eso:

- busca validacion existente
- escucha updates por websocket
- decide que UI mostrar segun tipo y estado
- permite subir archivos o iniciar flujos especiales

### Dos contextos de validable

#### 1. `USER`

Para validaciones de perfil/identidad, como `id`, `selfie`, `facebook`, `biometric_id`.

#### 2. `TRANSACTION`

Para validaciones ligadas al pedido, especialmente `screenshot`.

### Estados que cambian la UI

Cuando la validacion esta en:

- `APPROVED`
- `PRE_APPROVED`
- `PENDING`
- `PROCESSING`

el front deja de mostrar el uploader y pasa a mostrar estado.

### Tipos con flujo de archivos

Los tipos normales con carga de archivos usan:

- uploader
- previews
- create pending validation
- examples gallery

Esto aplica a `id`, `selfie` y `screenshot`.

### Tipos especiales

#### `facebook`

No usa uploader.
Muestra instrucciones especificas para agregar/contactar a Saldoar por Facebook.

#### `biometric_id`

No usa uploader.
El front pide una URL biometrica, incrusta un frame Veriff y, al terminar o cancelar, redirige usando `transaction_instructions_redirect_urls`.

## Backstage

### Busqueda de validaciones

El front busca validaciones con filtro por `validation_type.id` y `beforepath`.

Eso devuelve la validacion mas reciente del tipo solicitado.

### Creacion de validaciones pendientes

Cuando el usuario envia archivos:

- el front crea una `Validation`
- la manda inicialmente como `PENDING`
- adjunta relaciones `files`

Pero el backend no toma ese estado tal cual: la `ValidationPolicy` recalcula el estado inicial con `ValidatorProcessingService`.

### Reglas de creacion

Antes de crear una validacion, el backend:

- exige que el status recibido sea `PENDING`
- resuelve el `validable` real (`USER` o `TRANSACTION`)
- bloquea creacion si ya hay validaciones en revision
- valida archivos minimos
- deduplica archivos repetidos por `md5`

### Regla especial para `screenshot`

Si es la primera validacion `screenshot` de una transaccion:

- la cantidad enviada debe ser al menos igual a `directTransfers1`
- si la cantidad unica por `md5` es menor a la requerida, falla por duplicados

Esta es una regla muy importante para soporte y UX porque explica por que el usuario puede haber subido archivos y aun asi recibir error.

### Links de validacion

El backend puede construir links de validacion de dos formas:

#### Link con key publica

- base: `/u/users/{userId}/{userKey}/{validationTypeId}`

#### Link con token/dashboard

- base: `/my/dashboard/validations/{validableId}`

`UserLinkValidationHelper` devuelve la primera validacion del usuario en estado:

- `REQUESTED`
- `REJECTED`
- `PENDING`

Si no hay ninguna, devuelve vacio.

### Biometria

Para `biometric_id`, el backend crea una sesion Veriff con datos del usuario y devuelve `verification_url`.

Tambien dispara un job que actualiza observaciones privadas con el `verification_id`.

## Trazabilidad Tecnica

### Front

- modulo: `solido/apps/solido-app/src/ui/features/validations/README.md`
- servicio principal: `solido/apps/solido-app/src/ui/features/validations/services/create-validation.service.ts`
- componente principal: `solido/apps/solido-app/src/ui/features/validations/components/create-validation/create-validation.component.ts`
- contenido segun tipo: `solido/apps/solido-app/src/ui/features/validations/components/validation-type-content/validation-type-content.component.ts`
- biometria: `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric.component.ts`
- VM biometria: `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric-view-model.service.ts`
- busqueda: `solido/apps/solido-app/src/domain/use-cases/validation/search-validation.usecase.ts`
- creacion: `solido/apps/solido-app/src/domain/use-cases/validation/create-pending-validation.usecase.ts`
- redirect url: `solido/apps/solido-app/src/ui/features/transactions/services/transaction-instructions-redirect-url-view-model.service.ts`
- get biometric id: `solido/apps/solido-app/src/domain/use-cases/get-biometric-id-use-case.ts`

### Back

- ruta de ejemplos: `saldo/routes/api.php`
- helper de links: `saldo/app/Validations/UserValidationLinks/UserLinkValidationHelper.php`
- entidad central: `saldo/app/Validations/Validations/Validation.php`
- policy de creacion: `saldo/app/Validations/Validations/ValidationPolicy.php`
- ejemplos: `saldo/app/Validations/ValidationExamples/ValidationExampleController.php`
- biometria: `saldo/app/Validations/Validations/BiometricIdValidation/BiometricIdValidationService.php`
- tipos: `saldo/app/Validations/ValidationTypes/ValidationTypeIdEnum.php`
- urls key: `saldo/app/Core/Urls/Validations/ValidationKeyUrls.php`
- urls token: `saldo/app/Core/Urls/Validations/ValidationTokenUrls.php`

## Reglas de Negocio Detectadas

### Una validacion en revision bloquea nuevas del mismo flujo

El backend evita crear nuevas validaciones si el `validable` ya tiene una para evaluacion.

### El estado inicial real lo define backend

Aunque el front crea con `PENDING`, la policy lo reemplaza con el valor que determine `ValidatorProcessingService`.

### `screenshot` es una validacion transaccional

No es solo "subir comprobantes". Esta atada a:

- la transaccion
- la cantidad de `directTransfers1`
- la unicidad real de archivos

### La UX depende del tipo

El mismo contenedor `create-validation` puede terminar mostrando:

- uploader
- instrucciones Facebook
- frame Veriff
- estado de revision/aprobacion

### Biometria retorna a instrucciones

El flujo de `biometric_id` no termina en la validacion misma.
Despues del evento `FINISHED` o `CANCELED`, el front usa una redirect URL para volver al flujo correspondiente.

## Lo que este flujo ya permite responder

- Como entra un usuario a una validacion desde dashboard o desde link firmado.
- Que diferencia hay entre validacion de usuario y validacion de transaccion.
- Cuando una validacion usa archivos y cuando usa un flujo especial.
- Por que una validacion `screenshot` puede fallar aunque el usuario haya subido archivos.
- Como se construyen los links de validacion para usuarios no autenticados.
- Como se integra Veriff en biometria.
- Que estados hacen que el front deje de permitir subida y solo muestre revision.

## Edge Cases / Riesgos

- `UserLinkValidationHelper` devuelve la primera validacion en progreso/rechazada/pending, no necesariamente la mas "conveniente" para UX.
- El flujo mezcla links publicos con key y flujos autenticados con token/dashboard.
- `screenshot` tiene reglas de conteo y duplicados que pueden resultar opacas si el copy no las explica bien.
- `facebook` y `biometric_id` rompen el modelo mental de "subir archivo", lo que puede complicar consistencia.
- La redirect URL posterior a biometria depende de otro servicio y puede ser critica para no dejar al usuario colgado.

## Unknowns

- Confirmar el comportamiento exacto de `ValidatorProcessingService` para cada `validable_type`.
- Mapear todos los estados posibles de `ValidationStatusEnum` en la experiencia completa.
- Documentar como llegan las decisiones externas de Veriff al objeto `Validation`.
- Ver si hay diferencias de copy o reglas entre validacion de usuario por dashboard y por key publica.
- Entender mejor el flujo `audit` y `video_call`, que aparecen en backend pero no quedaron profundizados aca.

## Fuentes

- `solido/apps/solido-app/src/ui/features/validations/README.md`
- `solido/apps/solido-app/src/ui/features/validations/services/create-validation.service.ts`
- `solido/apps/solido-app/src/ui/features/validations/components/create-validation/create-validation.component.ts`
- `solido/apps/solido-app/src/ui/features/validations/components/validation-type-content/validation-type-content.component.ts`
- `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric.component.ts`
- `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric-view-model.service.ts`
- `solido/apps/solido-app/src/domain/use-cases/validation/search-validation.usecase.ts`
- `solido/apps/solido-app/src/domain/use-cases/validation/create-pending-validation.usecase.ts`
- `solido/apps/solido-app/src/domain/use-cases/get-biometric-id-use-case.ts`
- `solido/apps/solido-app/src/ui/features/transactions/services/transaction-instructions-redirect-url-view-model.service.ts`
- `saldo/routes/api.php`
- `saldo/app/Validations/UserValidationLinks/UserLinkValidationHelper.php`
- `saldo/app/Validations/Validations/Validation.php`
- `saldo/app/Validations/Validations/ValidationPolicy.php`
- `saldo/app/Validations/ValidationExamples/ValidationExampleController.php`
- `saldo/app/Validations/Validations/BiometricIdValidation/BiometricIdValidationService.php`
- `saldo/app/Validations/ValidationTypes/ValidationTypeIdEnum.php`
- `saldo/app/Core/Urls/Validations/ValidationKeyUrls.php`
- `saldo/app/Core/Urls/Validations/ValidationTokenUrls.php`
