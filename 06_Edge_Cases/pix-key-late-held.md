# PIX Key Late HELD

## Tipo

Comportamiento esperado con friccion alta y apariencia de fallo tardio.

## Contexto

Una operacion con destino `PIX` puede parecer bien encaminada durante buena parte del flujo y despues terminar retenida.

## Condicion disparadora

- el destino requiere clave `PIX`
- la validacion externa de la clave ocurre tarde en el lifecycle
- Kamipay devuelve que la clave no es valida o no pasa la verificacion esperada

## Comportamiento observado

- el usuario ya siente que el pedido estaba avanzado
- despues la transaccion puede pasar a `HELD`
- el problema visible no se percibe como simple error de formulario, sino como retencion posterior

## Impacto

- mucha confusion para soporte
- frustracion UX porque el rechazo aparece tarde
- riesgo de interpretar que la retencion es arbitraria o manual

## Clasificacion

Esperado por validacion operativa, pero con costo alto de claridad.

## Lo importante para decidir

- no todo destino bancario se comporta como `PIX`
- parte del control depende de integracion externa, no solo de validacion local
- este caso cruza cuentas, integracion, estados y recovery

## Flujos e integraciones relacionadas

- `02_Flows/accounts-and-destination-selection`
- `02_Flows/cancellation-held-mediation-recovery`
- `02_Flows/system-specific-branches`
- `04_Integrations/kamipay`

## Preguntas que ayuda a responder

- “¿por que una clave pix invalida termina en held?”
- “¿por que un pedido pix se retuvo despues de parecer valido?”
- “¿por que no fallo antes si la clave pix estaba mal?”

## Fuentes

- `saldo/app/Transactions/Transactions/UseCases/ValidatePixAddressOrHeldUseCase.php`
- `saldo/app/Transactions/Listeners/ValidatePixAddressListener.php`
- `saldo/app/External/Kamipay/KamipayService.php`
