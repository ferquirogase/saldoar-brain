# VCC Copy Looks Like Balance Reception

## Tipo

Friccion UX por semantica incorrecta.

## Contexto

En pedidos con destino `VCC`, parte del copy del sector de recepcion o del stepper puede hablar de "recibir saldo" o de "enviar saldo" como si la tarjeta fuera un destino final comun.

## Condicion disparadora

- `system2` cae en la rama `VCC`
- la UI reutiliza copy generico de recepcion o de envio de saldo
- aparecen textos del estilo `Recibiras tu saldo en tu cuenta` o `Enviando tu saldo`

## Comportamiento observado

- el titulo puede hablar de `Tarjeta VCC para verificar`
- pero el subtitulo o el stepper hablan de saldo enviado o recibido
- eso mezcla dos modelos mentales incompatibles dentro de la misma pantalla

## Impacto

- el usuario puede creer que la VCC es una cuenta donde se le acredita saldo
- soporte o marketing pueden explicar mal el producto
- el flujo real de verificar PayPal queda oculto detras de copy de "recepcion"

## Clasificacion

Debt UX / copy inconsistente con el comportamiento real del sistema.

## Lo importante para decidir

- VCC no se documenta como destino comun de acreditacion
- la rama confirmada habla de generar tarjeta, cargarla en PayPal y usar codigo de verificacion
- conviene que el copy hable de tarjeta, verificacion y carga en PayPal; no de enviar saldo a la VCC

## Flujos relacionados

- `02_Flows/payment-instructions`
- `02_Flows/system-specific-branches`

## Preguntas que ayuda a responder

- "por que en VCC dice recibir saldo si solo sirve para verificar PayPal"
- "VCC recibe saldo o solo verifica la cuenta"
- "por que el stepper dice enviando tu saldo en una operacion VCC"

## Fuentes

- `02_Flows/payment-instructions/README.md`
- `02_Flows/system-specific-branches/README.md`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionPreApprovedSentStateNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/SpecialMethod/CreditedVcc.php`
- `saldo/app/Transactions/Notifications/InstructionsToLoadVccNotification.php`
- `saldo/app/Transactions/Notifications/StateNotifications/TransactionSentStateNotification.php`
