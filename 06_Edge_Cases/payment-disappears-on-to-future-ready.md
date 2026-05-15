# Payment Disappears On To Future Ready

## Tipo

Fricción UX crítica / posible gap de lógica backend.

## Contexto

Cuando un pedido tiene múltiples destinos de pago asignados (`directTransfers1`), el
usuario puede pagar a uno de ellos y luego ejecutar "no puedo pagar" sobre el otro
para pedir un destino alternativo. Si el sistema no encuentra nuevos destinos
disponibles, mueve el pedido a `TO_FUTURE_READY` ("Buscando destinos").

En ese estado, el pago ya realizado al primer destino deja de aparecer en la pantalla
de instrucciones. Verificado por simulación.

## Condición disparadora

1. Pedido en `WAITING_PAYMENT` con 2 o más `directTransfers1` asignados (A y B)
2. Usuario envía dinero al destino A (con o sin marcarlo como enviado en la app)
3. Usuario ejecuta `DestinationDontWork` sobre B ("necesito otro destino")
4. `applyDirectDirectTransfers()` no encuentra nuevos destinos disponibles
5. Pedido pasa a `TO_FUTURE_READY`

## Comportamiento observado

- La pantalla de instrucciones muestra el estado "Buscando destinos"
- El pago al destino A ya no aparece en el listado de directTransfers
- El usuario no tiene información visible sobre el pago que ya realizó
- El usuario reporta que "su pago desapareció"

## Qué hace el código

### Backend — `DestinationDontWork.handle()`

```
1. markDestinationAsFailed()
   → B recibe deleteWithBehaviour(REMOVED_READ) + deleted_at = now()

2. applyDirectDirectTransfers(preventPreviousAssigned=true)
   → busca nuevos destinos; si no encuentra, retorna false

3. Si result === false:
   → addState(TO_FUTURE_READY)
```

`applyDirectDirectTransfers()` no elimina ni modifica A. Solo crea nuevos
`directTransfers` si los encuentra, o retorna `false` sin tocar los existentes.

### Backend — visibilidad del directTransfer A

`DirectTransfer1Schema.modelBeforeGet()` filtra por `deleted_at`:

- Usuarios normales en producción: solo reciben transfers con `deleted_at IS NULL`
- Operadores: también reciben `REMOVED_READ` aunque tengan `deleted_at`

Si A sigue con `deleted_at = null`, debería llegar al frontend. La razón exacta
por la que no aparece no fue trazada completamente en código — requiere inspección
del estado de la DB durante el escenario simulado.

### Protección existente — Observer

`DirectTransferObserver.deleting()` lanza una excepción si `sent = true`:

```php
if ($transfer->sent) {
    throw new BaseException('No es posible eliminar una transferencia enviada.');
}
```

Esta protección debería impedir que A sea eliminado si el usuario lo marcó como
enviado antes de que se ejecute `DestinationDontWork`. Sin embargo, el escenario
simulado muestra que A no aparece de todas formas.

### Frontend — `getCurrentState()`

```typescript
public getCurrentState(): string {
    if (this.transaction.attributes.agreement1_id) {
        return 'agreement';
    } else {
        return 'direct-transfers';
    }
}
```

El `direct-transfer1-container` se renderiza para cualquier pedido sin `agreement1_id`,
incluidos los pedidos en `TO_FUTURE_READY`. Si A llegara desde el backend, la UI lo
mostraría.

## Impacto

- El usuario que pagó en el mundo real no tiene evidencia visual de su pago en la app
- Soporte recibe consultas del tipo "pagué y desapareció"
- El usuario puede creer que su dinero se perdió o que el pedido fue cancelado
- Alta fricción en un momento crítico del flujo (ya hay plata en juego)

## Clasificación

Edge case de severidad alta. Ocurre en condiciones reales (múltiples destinos,
usuario no puede pagar uno de ellos). El comportamiento del sistema al ir a
`TO_FUTURE_READY` no preserva la visibilidad del pago ya realizado.

## Propuesta documentada por producto

Mostrar en la pantalla de `TO_FUTURE_READY` tanto los destinos activos como los
ya enviados, permitiendo que el usuario vea su historial de pagos aunque el pedido
esté buscando nuevos destinos.

## Flujos relacionados

- `02_Flows/payment-instructions`
- `02_Flows/create-transaction-and-next-step`

## Preguntas que ayuda a responder

- "Pagué y mi pago no aparece en instrucciones"
- "El pedido está en buscando destinos pero no veo la transferencia que hice"
- "¿Por qué desapareció mi pago cuando pedí otro destino?"
- "¿Qué pasa con los pagos que ya hice si el pedido cambia de estado?"

## Unknowns

- Mecanismo exacto por el que A termina invisible: si efectivamente queda con
  `deleted_at` (violando la protección del Observer) o si la UI lo omite por
  otro motivo no trazado
- Si la protección del Observer (`sent=true` impide borrar) se cumple en este
  path o si hay algún code path que la bypasea
- Comportamiento cuando el usuario pagó en el mundo real pero no marcó como
  enviado en la app antes de ejecutar `DestinationDontWork` (en ese caso
  `sent=false` y el Observer no protege)

## Fuentes

- `saldo/app/Transactions/DirectTransfers/DirectTransferActions/Actions/DestinationDontWork.php`
- `saldo/app/Transactions/Processors/Internals/DirectTransfersApplicator.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransfer1Schema.php`
- `saldo/app/Transactions/DirectTransfers/DirectTransferObserver.php`
- `solido/apps/solido-app/src/ui/pages/instructions/instructions.component.ts`
- `solido/apps/solido-app/src/ui/pages/instructions/components/direct-transfer1-container/direct-transfer1-container.component.ts`
