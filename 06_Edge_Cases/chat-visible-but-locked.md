# Chat Visible But Locked

## Tipo

Friccion UX por control backend.

## Contexto

El usuario entra al area de chat o soporte dentro de una transaccion, ve la interfaz conversacional, pero no puede escribir libremente.

## Condicion disparadora

- el estado actual todavia prioriza `state_chips`
- `StateChatService` no marco la transaccion como chat disponible
- backend ofrece ayuda guiada, pero no conversacion libre

## Comportamiento observado

- el area de chat esta visible
- el input queda deshabilitado
- pueden aparecer chips como `SUPPORT` o caminos guiados
- solo despues de ciertas acciones o eventos el chat se abre de verdad

## Impacto

- sensacion de interfaz rota o “no me dejan hablar”
- soporte puede asumir que el usuario ya podia escribir cuando no era asi
- dos pedidos con estados parecidos pueden verse muy distintos

## Clasificacion

Esperado desde la logica del producto, pero confuso desde la percepcion del usuario.

## Lo importante para decidir

- ver el chat no equivale a tener conversacion libre
- esta capa depende de cache, estado, chips y listeners backend
- es un punto fino entre UX guiada y soporte humano

## Flujos relacionados

- `02_Flows/chat-state-chips-and-support-actions`
- `02_Flows/transaction-visibility-and-status`
- `02_Flows/operator-interventions-and-panel-actions`

## Preguntas que ayuda a responder

- “¿por que veo el chat pero no puedo escribir?”
- “¿cuando se habilita de verdad el chat?”
- “¿por que a un usuario le aparecen chips y a otro input libre?”

## Fuentes

- `saldo/app/Transactions/StateChips/StateChatService.php`
- `saldo/app/Transactions/StateChips/ChatController.php`
- `solido/apps/solido-app/src/app/transactions/components/state-chat/state-chat.component.ts`

