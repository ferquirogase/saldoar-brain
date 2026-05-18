# Davivienda Interbank Delay

## Tipo

Comportamiento esperado del sistema bancario colombiano / fricción operativa.

## Contexto

Davivienda maneja tiempos de acreditación distintos según el banco de origen del pago:

- **Davivienda → Davivienda**: acreditación instantánea
- **Otro banco → Davivienda**: puede demorar hasta 48 horas por plazos interbancarios

Cuando el sistema asigna un destino Davivienda a un pedido en pesos colombianos y el
emisor opera desde otro banco, el receptor no confirma recepción de inmediato. Esto
bloquea al emisor, que no puede empezar a recibir lo que le corresponde hasta esa
confirmación. Para saltearse la espera, el emisor pide cambiar el destino — lo que
afecta operativamente al receptor.

## Condición disparadora

- Pedido en pesos colombianos (COP)
- Sistema asigna destino con cuenta Davivienda
- Emisor opera desde un banco distinto a Davivienda

## Comportamiento observado

- La acreditación en la cuenta Davivienda puede demorar hasta 48 horas
- El receptor no puede confirmar recepción de inmediato
- El emisor queda bloqueado esperando esa confirmación
- El emisor solicita cambiar el destino para acelerar el proceso
- El cambio de destino genera fricción operativa adicional

## Impacto

- Fricción para el emisor que espera recibir su parte del pedido
- El receptor Davivienda puede recibir consultas o quejas por "demoras"
- Aumento de solicitudes de cambio de destino en pedidos COP
- Mayor carga operativa en pedidos con esta combinación

## Copy aprobado

Mensaje a mostrar al receptor Davivienda en la pantalla de instrucciones de pago:

> **"Davivienda procesa transferencias internas al instante. Cuando el pago se realiza desde otros bancos, los tiempos pueden extenderse hasta 48 hs según los plazos interbancarios."**

## Clasificación

No es un bug de Saldoar. Es el comportamiento estándar del sistema interbancario
colombiano. La fricción surge porque el flujo de Saldoar depende de la confirmación
de recepción para avanzar, y esa confirmación puede tardar.

## Flujos relacionados

- `02_Flows/payment-instructions`
- `02_Flows/system-specific-branches`

## Preguntas que ayuda a responder

- "¿Por qué el usuario pide cambiar el destino Davivienda?"
- "¿Cuánto tarda en acreditarse un pago a Davivienda desde otro banco?"
- "El receptor dice que no recibió el pago pero el emisor ya lo envió"
- "¿Qué diferencia hay entre transferir a Davivienda desde Davivienda o desde otro banco?"
- "¿Por qué hay demoras de hasta 48 horas en pedidos de pesos colombianos?"

## Fuentes

- `02_Flows/payment-instructions/README.md`
- `02_Flows/system-specific-branches/README.md`
