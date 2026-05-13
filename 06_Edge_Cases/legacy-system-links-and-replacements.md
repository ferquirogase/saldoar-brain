# Legacy System Links And Replacements

## Tipo

Comportamiento esperado con impacto SEO, marketing y trazabilidad.

## Contexto

Un link historico, slug publico o ruta de campaña apunta a un sistema que ya no es el visible actual, pero igual termina abriendo una experiencia valida.

## Condicion disparadora

- el sistema referenciado tiene `replacement_system_id`
- el front intenta resolver sistema activo con `ReplaceSystemHelper`
- la landing por sistema o la home publica cargan ese contexto

## Comportamiento observado

- el usuario puede entrar con un slug viejo y terminar viendo otro sistema
- la URL visible puede corregirse
- una campaña vieja puede seguir “funcionando”, aunque ya no represente literalmente el sistema original

## Impacto

- confunde analisis de acquisition si no se sabe que hubo reemplazo
- puede parecer que el link esta mal, cuando en realidad esta siendo absorbido por continuidad de producto
- complica responder de donde salio exactamente el sistema visible

## Clasificacion

Esperado y util para backwards compatibility.

## Lo importante para decidir

- no es solo una decision de UI: la informacion viene del catalogo real de sistemas
- afecta SEO, marketing, soporte y lectura de funnels
- conviene distinguir “link roto” de “link absorbido por replacement”

## Flujos relacionados

- `02_Flows/landing-for-systems-and-marketing-preloads`
- `02_Flows/system-selection-and-quote-calculator`

## Preguntas que ayuda a responder

- “¿por que un link viejo abre otro sistema?”
- “¿por que una landing muestra un metodo distinto al del slug?”
- “¿de donde sale el sistema visible si la URL apunta a otro?”

## Fuentes

- `solido/apps/solido-app/src/app/core/helpers/replace-system.helper.ts`
- `solido/apps/solido-app/src/app/landing-for-systems/landing-for-systems.component.ts`
- `saldo/app/Systems/Systems/SystemSchema.php`
