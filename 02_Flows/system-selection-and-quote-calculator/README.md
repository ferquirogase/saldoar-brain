# System Selection And Quote Calculator

## Metadata

- `flow_id`: `flow-system-selection-and-quote-calculator`
- `status`: `v1`
- `owner_area`: `transactions`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar construye la cotizacion inicial antes de crear el pedido: seleccion de `system1` y `system2`, montos por `send` o `receive`, inversion de sistemas, sincronizacion con URL, defaults por pais o landing y paso posterior al form.

## Por que importa

Este flujo condiciona casi toda la experiencia inicial del producto:

- que caminos de intercambio aparecen o no
- que valores se muestran por defecto
- cuando el usuario siente que "la calculadora esta rota"
- por que dos landings o rutas pueden abrir el mismo core con sistemas precargados distintos
- cuando el error es de UI, de validacion local o de regla real del backend

Tambien es una pieza fuerte para marketing, UX y soporte porque es el primer contacto operativo con el servicio.

## Entry Points

### Home y home-step-b

- `/b`
- `/b/{system1}/{system2}/{amount1}/{amount2}`
- `/{langCode}/b/...`
- matcher legacy `a/...` y `b/...`

### Rutas de marketing o landings con systems precargados

- `landing-marketing`
- `landing-for-systems`
- otros puntos que montan `app-transaction-calculator`

### Rehidratacion local

- `QuoteSessionService` puede volver a hidratar una cotizacion previa si no hay sistemas en URL

## Frontstage

### 1. Carga de sistemas

El componente `app-transaction-calculator` recibe `systems$` y separa:

- `systemsCanSend`
- `systemsCanReceive`

Solo toma sistemas:

- con `can_send` o `can_receive`
- sin `replacement_system_id`

Eso significa que algunos sistemas legacy o alias no se muestran directamente aunque puedan seguir existiendo en URLs viejas.

### 2. Defaults iniciales

Si la URL no trae sistemas:

- el front intenta sugerir sistemas por pais (`CountryProvider`)
- si no alcanza, cae al default clasico `banco -> palpal`

Luego define montos iniciales con `CurrencyPiorityService`, eligiendo si conviene arrancar por `amount1` o por `amount2`.

### 3. Hidratacion desde URL

En `home-step-b`, la cotizacion puede venir embebida en la ruta:

- `system1`
- `system2`
- `amount1`
- `amount2`

Eso define tambien la operacion:

- si `amount1 === 0`, la operacion es `send`
- si no, la operacion es `receive`

### 4. Reemplazo de sistemas

Si una URL trae un sistema que hoy fue reemplazado:

- `ReplaceSystemHelper` intenta sustituirlo por `replacement_system_id`
- si cambia, el front reescribe la URL

Esto ayuda a preservar links historicos sin exponer sistemas viejos en el selector principal.

### 5. Calculo de montos

La cotizacion usa `TransactionAmountCalculator` en front.

Combina:

- rate entre `system1` y `system2`
- `fixed_fee_send`
- `fixed_fee_receive`
- fee por network cuando aplica
- red crypto seleccionada o inferida
- `decimal_places` de cada sistema

La calculadora soporta dos modos:

- el usuario fija lo que envia y se calcula lo que recibe
- el usuario fija lo que quiere recibir y se calcula cuanto debe enviar

### 6. Inversion de sistemas

El usuario puede invertir origen y destino.

Pero no siempre:

- si `sendSystem` no puede recibir
- o `receiveSystem` no puede enviar

la inversion se bloquea visualmente.

Cuando si se puede:

- el front intercambia sistemas
- mueve los montos segun la operacion actual
- recalcula
- vuelve a validar

### 7. Validaciones visibles en la cotizacion

Antes del form, ya se aplican reglas de validacion local, entre ellas:

- sistemas iguales
- monto minimo de envio
- monto minimo de recepcion

Si hay error:

- la calculadora lo expone como mensaje contextual
- puede setear una recomendacion en la transaccion

### 8. Persistencia local de sesion de cotizacion

`QuoteSessionService` guarda snapshot de:

- sistema origen
- sistema destino
- montos
- operacion
- network destino

Eso permite rehidratar la experiencia si el usuario vuelve sin una URL completa.

### 9. Paso al form

Cuando la cotizacion ya esta armada, el CTA navega a una URL transaccional construida con `TransactionUrlService`.

En ruta `b`, la URL encodea:

- `system1`
- `system2`
- el monto activo

Desde ahi el usuario entra al `transaction-form`, donde ya completa:

- nombre
- email
- whatsapp
- direcciones o cuentas
- network destino si aplica
- checks especiales de ciertos sistemas

## Backstage

### Backend valida que el par exista realmente

Aunque el front filtre opciones, el backend vuelve a validar en `TransactionPublicPolicy`:

- que exista `system1`
- que `system1 !== system2`
- que el cambio `system1 -> system2` este permitido

### Backend recalcula el monto complementario

Cuando se crea el pedido publico:

- si el usuario mando `amount1`, backend calcula `amount2`
- si mando `amount2`, backend calcula `amount1`

Eso evita depender solo de la cotizacion local del navegador.

### Validacion de minimos reales

`TransactionValidator` y `TransactionSystemMinimumValuesValidator` vuelven a controlar:

- minimo de envio
- minimo de recepcion
- casos con minimo mas estricto del lado destino

### Network y crypto

Si hay `account_network2` o la direccion permite inferir red:

- backend la usa para calcular mejor el monto
- esto puede alterar el resultado frente a una cotizacion sin network bien definida

### Riesgo de `rate_dropped`

Entre la cotizacion local y el guardado real puede cambiar la tasa.

Si eso pasa:

- backend devuelve `rate_dropped`
- el front lo muestra como cambio de cotizacion

## Trazabilidad Tecnica

### Front

- calculadora principal: `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/transaction-calculator.component.ts`
- seleccion de sistemas: `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/system-select/system-select.component.ts`
- invertir sistemas: `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/invert-systems/invert-systems.component.ts`
- calculo de montos: `solido/apps/solido-app/src/app/transactions/transaction-amount-calculator.ts`
- modelo transaccion: `solido/apps/solido-app/src/app/transactions/transaction.ts`
- URL builder: `solido/apps/solido-app/src/app/transactions/transaction-url.service.ts`
- pagina step-b: `solido/apps/solido-app/src/app/home/home-step-b.component.ts`
- form de creacion publica: `solido/apps/solido-app/src/app/transactions/components/transaction-form/transaction-form.component.ts`
- helper de reemplazo: `solido/apps/solido-app/src/app/core/helpers/replace-system.helper.ts`
- validacion de minimos: `solido/apps/solido-app/src/app/transactions/transaction-validators-provider/transaction-validators/minimum-values-validator.ts`
- validacion de sistemas iguales: `solido/apps/solido-app/src/app/transactions/transaction-validators-provider/transaction-validators/system-equals-validator.ts`

### Back

- rutas principales: `solido/apps/solido-app/src/app/app-routing.module.ts`
- JSON:API transaction context: `saldo/app/Http/Controllers/JsonApiTransactionController.php`
- schema transaccion publica: `saldo/app/Transactions/Transactions/TransactionWithKeySchema.php`
- policy de creacion publica: `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- validador de minimos reales: `saldo/app/Transactions/Transactions/Validators/TransactionSystemMinimumValuesValidator.php`
- error codes: `saldo/app/Transactions/ErrorCodesEnum.php`

## Reglas de Negocio Detectadas

### La calculadora no muestra todo el catalogo crudo

El front oculta sistemas con `replacement_system_id`, y trabaja con send/receive reales, no con todo lo que exista en base.

### La URL es parte del flujo, no solo una navegacion

La cotizacion se puede:

- construir desde URL
- corregir por reemplazo de sistema
- reescribir cuando cambia el par
- rehidratar desde sesion si falta contexto

### El monto activo define el camino

No es lo mismo cotizar desde "quiero enviar X" que desde "quiero recibir Y".

Eso cambia:

- que amount se considera fuente
- como se recalcula el otro
- que valor se persiste en URL

### La red puede cambiar la cotizacion

Para crypto, la network no es solo un detalle de cuenta.
Puede afectar fees y el monto resultante.

### El backend sigue siendo autoridad final

Aunque el usuario vea una cotizacion valida en front, backend puede rechazar o ajustar por:

- par no permitido
- minimos reales
- network inferida
- cambio de tasa

## Lo que este flujo ya permite responder

- Como decide Saldoar que sistemas mostrar en la calculadora.
- Por que una URL vieja puede redirigir a otro sistema.
- Como se calculan los montos al enviar o recibir.
- Por que a veces no se puede invertir un par.
- Cuando el error aparece antes del form y cuando lo devuelve backend.
- Como se reconstruye una cotizacion desde URL o sesion.
- Por que una cotizacion puede cambiar justo al guardar.

## Edge Cases / Riesgos

- Un sistema puede existir tecnicamente pero no estar visible por `replacement_system_id`.
- `banco -> palpal` sigue apareciendo como fallback fuerte; conviene no asumir que siempre es una decision de negocio actualizada.
- La logica de default por pais puede alterar la experiencia sin que el usuario haya elegido nada.
- Network crypto mal inferida o no definida puede desalinear cotizacion y guardado.
- `rate_dropped` puede sentirse como bug si no se explica que la cotizacion era preliminar.
- La persistencia local de quote session puede rehidratar contexto viejo si no se invalida bien.

## Unknowns

- Criterio exacto de negocio detras de `CurrencyPiorityService` en todos los pares activos.
- Superficie completa de landings o modales que montan esta misma calculadora con variantes.
- Todas las fuentes que pueden cambiar `systems$` en runtime mas alla de websocket y refresh de rates.
- Cuanto peso real tienen hoy las rutas legacy `a/...` en trafico o soporte.

## Fuentes

- `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/transaction-calculator.component.ts`
- `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/system-select/system-select.component.ts`
- `solido/apps/solido-app/src/app/transactions/components/transaction-calculator/invert-systems/invert-systems.component.ts`
- `solido/apps/solido-app/src/app/transactions/transaction-amount-calculator.ts`
- `solido/apps/solido-app/src/app/transactions/transaction.ts`
- `solido/apps/solido-app/src/app/transactions/transaction-url.service.ts`
- `solido/apps/solido-app/src/app/home/home-step-b.component.ts`
- `solido/apps/solido-app/src/app/transactions/components/transaction-form/transaction-form.component.ts`
- `solido/apps/solido-app/src/app/core/helpers/replace-system.helper.ts`
- `solido/apps/solido-app/src/app/transactions/transaction-validators-provider/transaction-validators/minimum-values-validator.ts`
- `solido/apps/solido-app/src/app/transactions/transaction-validators-provider/transaction-validators/system-equals-validator.ts`
- `solido/apps/solido-app/src/app/app-routing.module.ts`
- `saldo/app/Http/Controllers/JsonApiTransactionController.php`
- `saldo/app/Transactions/Transactions/TransactionWithKeySchema.php`
- `saldo/app/Transactions/Transactions/TransactionPublicPolicy.php`
- `saldo/app/Transactions/Transactions/Validators/TransactionSystemMinimumValuesValidator.php`
- `saldo/app/Transactions/ErrorCodesEnum.php`
