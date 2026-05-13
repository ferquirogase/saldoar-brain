# Landing For Systems And Marketing Preloads

## Metadata

- `flow_id`: `flow-landing-for-systems-and-marketing-preloads`
- `status`: `v1`
- `owner_area`: `growth`
- `evidence_level`: `confirmed`

## Objetivo

Explicar como Saldoar usa rutas publicas, landings SEO y links de marketing para llevar al usuario a una cotizacion ya contextualizada: idioma, sistema, par sugerido, copy, canonical y metadatos.

No es el mismo problema que la calculadora en si. Aca importa el paso anterior: como entra el usuario al core y con que contexto.

## Por que importa

Este flujo ayuda a responder preguntas que suelen quedar difusas entre UX, marketing y producto:

- por que un link abre una cotizacion ya precargada
- por que ciertas landings no van directo al dashboard ni al form
- por que una ruta publica cambia de idioma o canonical
- por que un sistema viejo puede terminar mostrando otro slug
- por que dos entradas publicas distintas terminan usando la misma calculadora

## Entry Points

### Home publica y matchers

- `/`
- `/a/{system1}/{system2}/{amount1}/{amount2}`
- `/b/{system1}/{system2}/{amount1}/{amount2}`
- versiones localizadas con `/{langCode}/...`

Los matchers `homeUrlMatcher` y `homeStepBUrlMatcher` permiten tratar esas variantes como parte del mismo journey.

### Landing por sistema

- `/comprar-vender/{system}`

Esta ruta carga una landing SEO alrededor de un unico sistema y despues deriva al core de intercambio con contexto de ese metodo.

### Landing marketing curada

- `/retirar-cobrar-paypal-a-pesos-argentina`
- `/comprar-recargar-saldo-paypal-argentina`

Estas rutas no son un resolvedor generico. Son piezas curadas con copy y pares fijos.

## Frontstage

### 1. La URL publica es parte del producto

En `home.component` y `home-step-b.component` la transaccion puede hidratarse desde:

- segmentos de ruta
- idioma incluido en la ruta
- query params como referral o source
- snapshot previo en `QuoteSessionService`

No es solo navegacion: la URL define sistemas, montos y a veces el idioma publico del flujo.

### 2. La sesion de cotizacion rellena huecos

Si no vienen `system1` y `system2` en la ruta, el front intenta rehidratar desde `QuoteSessionService`.

Eso conserva:

- sistema origen
- sistema destino
- monto activo
- operacion `send` o `receive`
- `account_network2`

Esto ayuda a continuidad UX, pero tambien significa que una ruta incompleta puede “recordar” un contexto previo.

### 3. Los links publicos pueden corregirse solos

`ReplaceSystemHelper` revisa si un sistema visible fue reemplazado por otro usando `replacement_system_id`.

Si pasa:

- el front resuelve el sistema activo
- actualiza la transaccion con ese sistema
- puede reescribir la URL para mostrar el slug nuevo

Esto sostiene compatibilidad con links historicos y con campañas viejas.

### 4. Landing por sistema: SEO primero, exchange despues

`LandingForSystemsComponent` hace varias cosas:

- recibe un solo `system` desde la ruta
- carga el sistema con `system_information`
- si tiene `replacement_system_id`, redirige al slug actual
- arma titulo, keywords, canonical y OG
- carga sistemas alternativos
- difiere parte del detalle de mercado hasta que entra en viewport

O sea: es una landing publica viva, no una pagina estatica separada del core.

### 5. Landing marketing: copy fijo con par fijo

`LandingMarketingComponent` toma la URL y decide entre dos modelos curados:

- `palpal_banco`
- `banco_palpal`

Con eso define:

- `system1_id`
- `system2_id`
- copy y bloques de contenido
- canonical y open graph de esa pieza

Despues hidrata la transaccion con `SystemsService` para que la experiencia siga conectada al mismo catalogo real.

### 6. Header, pais e idioma tambien precargan contexto

El header:

- sincroniza idioma desde la ruta
- cambia pais visible
- genera `href` por locale
- puede mostrar links o banners publicos que llevan a calculadoras ya prearmadas

Eso significa que parte del “preload” no vive solo en campañas pagas: tambien vive en navegacion publica, banderas y country switch.

### 7. Public socket mantiene frescas algunas superficies

Las pantallas publicas escuchan el canal `solido` y empujan eventos de:

- `systems`
- `best_rates`

Entonces una landing publica puede cambiar sin refresh completo si backend publica actualizaciones.

## Backstage

### Backend define el catalogo visible

`SystemSchema` expone `replacement_system_id` y relaciones que estas pantallas usan para resolver sistemas activos, rates, networks y `system_information`.

### Rates y mejores pares no son estaticos

Las superficies publicas dependen de:

- `JsonRatesController`
- `BestRateService`
- eventos `SystemsUpdatedEvent`
- eventos `BestRatesUpdatedEvent`

Por eso marketing puede armar un buen entry point, pero el contenido operativo final sigue siendo dinamico.

### El backend sigue siendo autoridad final

Aunque una landing deje listo un par o una ruta publica hidrate una cotizacion:

- el catalogo real viene de backend
- los reemplazos vienen de backend
- las tasas vienen de backend
- la validez del par sigue siendo real y no solo de front

## Trazabilidad Tecnica

### Front

- rutas publicas: `solido/apps/solido-app/src/app/app-routing.module.ts`
- bootstrap home: `solido/apps/solido-app/src/app/home/home.component.ts`
- bootstrap step-b: `solido/apps/solido-app/src/app/home/home-step-b.component.ts`
- matcher step-a: `solido/apps/solido-app/src/app/home/home-url.matcher.ts`
- matcher step-b: `solido/apps/solido-app/src/app/home/home-step-b-url.matcher.ts`
- URL builder: `solido/apps/solido-app/src/app/transactions/transaction-url.service.ts`
- sesion de cotizacion: `solido/apps/solido-app/src/app/core/services/quote-session.service.ts`
- reemplazo de sistemas: `solido/apps/solido-app/src/app/core/helpers/replace-system.helper.ts`
- header publico: `solido/apps/solido-app/src/app/core/components/header/header.component.ts`
- landing SEO por sistema: `solido/apps/solido-app/src/app/landing-for-systems/landing-for-systems.component.ts`
- landing marketing: `solido/apps/solido-app/src/app/wiki/landing-marketing/landing-marketing.component.ts`

### Back

- schema de sistemas: `saldo/app/Systems/Systems/SystemSchema.php`
- rates publicos: `saldo/app/Systems/Rates/Rates/JsonRatesController.php`
- best rates: `saldo/app/Systems/Rates/BestRates/BestRateService.php`
- evento de systems: `saldo/app/Core/Events/Solido/SystemsUpdatedEvent.php`
- evento de best rates: `saldo/app/Core/Events/Solido/BestRatesUpdatedEvent.php`

## Reglas De Negocio Detectadas

### No toda landing resuelve pares del mismo modo

- `landing-for-systems` parte de un solo sistema y construye contenido alrededor de ese metodo
- `landing-marketing` usa pares fijos curados
- `home` y `step-b` aceptan pares explicitos en URL

Conviene no tratarlas como una sola pieza aunque compartan calculadora o servicios.

### `replacement_system_id` es una capa de continuidad publica

No sirve solo para esconder sistemas viejos en selectores.
Tambien sostiene:

- links historicos
- slugs SEO
- campañas viejas
- rutas guardadas por usuarios

### El contexto publico puede sobrevivir sin URL completa

`QuoteSessionService` permite continuidad, pero tambien puede conservar una cotizacion previa mas alla de una ruta vacia o incompleta.

### SEO y operacion estan acoplados

Canonical, OG, idioma y copy visible se recalculan junto con el sistema o el par. No es una capa puramente editorial separada del producto.

## Casos Borde

- un slug publico puede abrir otro sistema visible porque el original fue reemplazado
- una landing puede parecer estatica, pero seguir cambiando por rates o systems actualizados en vivo
- una ruta incompleta puede recuperar una cotizacion previa y confundir a quien esperaba un estado neutro
- una pieza de marketing puede seguir viva aunque su par original ya no sea el mismo visible en producto

## Preguntas Que Este Flujo Ya Puede Responder

- “¿por que este link ya entra con un par elegido?”
- “¿de donde sale el canonical de esta landing?”
- “¿por que un slug viejo ahora muestra otro sistema?”
- “¿la landing de PayPal es generica o esta curada?”
- “¿por que una home publica recuerda la cotizacion anterior?”
