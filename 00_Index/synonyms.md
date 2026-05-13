# Synonyms — Vocabulario usuario → sistema

Mapa de términos en lenguaje natural hacia conceptos internos del producto.
Usar para mejorar la recuperación semántica y evitar vocabulary mismatch en consultas.

## Transacciones y estados

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| pedido, orden, solicitud | transaction | todos los flows de transactions |
| pedido parado, no avanza, en espera | TO_FUTURE_READY, TO_FUTURE | flow-create-transaction-and-next-step |
| pedido bloqueado, retenido | HELD, MEDIATION | flow-cancellation-held-mediation-recovery |
| pedido cancelado sin razón | cancelación automática por tiempo o concurrencia | flow-cancellation-held-mediation-recovery, flow-concurrent-orders-and-omitted-transactions |
| pedido que desapareció | pedido omitido, TO_NEW_TICKET | flow-concurrent-orders-and-omitted-transactions |
| estado del pedido | transaction state, state_chip | flow-transaction-visibility-and-status |
| confirmar pago, marcar como pagado | marked_as_sent, direct_transfer_action | flow-payment-instructions |
| disputa, reclamo | HELD_DISPUTED, mediation | flow-cancellation-held-mediation-recovery |

## Pagos e instrucciones

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| datos bancarios, cuenta para pagar | directTransfers1 | flow-payment-instructions |
| comprobante, voucher, recibo | directTransfers2, screenshot | flow-payment-instructions, flow-identity-validations |
| código QR, pago por QR | transfer-agreement-container, MercadoPago QR | flow-payment-instructions, flow-system-specific-branches |
| instrucciones de pago | instructions page, MarkInstructionsReadUseCase | flow-payment-instructions |
| pago con cripto, bitcoin, crypto | crypto branch, waiting-payment-crypto | flow-system-specific-branches |
| pago con PIX | pix-destination branch, ValidatePixAddressOrHeldUseCase | flow-system-specific-branches |
| tarjeta virtual, VCC | vcc-destination branch | flow-system-specific-branches |
| saldo, balance | balance-instructions | flow-payment-instructions |

## Validaciones de identidad

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| foto del DNI, documento, cédula | identity validation, ValidationTypeIdEnum | flow-identity-validations |
| selfie, foto de cara | selfie validation | flow-identity-validations |
| verificación biométrica, reconocimiento facial | biometric_id, Veriff | flow-identity-validations |
| pantalla externa de verificación | Veriff iframe | flow-identity-validations |
| validación rechazada | validation status REJECTED | flow-identity-validations |
| validación en revisión | validation status PENDING, PROCESSING | flow-identity-validations |
| screenshot de transacción | screenshot validation, transaction-scoped validation | flow-identity-validations |

## Cuentas y destinos

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| cuenta de destino, a dónde mando | account2, destination account | flow-accounts-and-destination-selection |
| cuenta de origen, desde dónde mando | account1 | flow-accounts-and-destination-selection |
| datos adicionales de cuenta | account_detail | flow-accounts-and-destination-selection |
| cambio de destino | ChangeDestinationAddress | flow-accounts-and-destination-selection |
| red de pago | network (en account) | flow-accounts-and-destination-selection |

## Deals

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| oferta, tasa publicada | public_deal | flow-deals-and-direct-transfer-matching |
| carrito de deals, selección de ofertas | deals_bag | flow-deals-and-direct-transfer-matching |
| oferta expirada | deals_bag expirado (15 minutos) | flow-deals-and-direct-transfer-matching |
| bloqueado para operar | payment hygiene block, expired bags limit | flow-deals-and-direct-transfer-matching |
| cotizacion vencida al guardar, tasa que expira antes de confirmar | rate_dropped | flow-system-selection-and-quote-calculator |

## Soporte y acciones in-app

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| botones en la pantalla del pedido | state chips | flow-chat-state-chips-and-support-actions |
| chat del pedido | StateChatService, is-chat-available | flow-chat-state-chips-and-support-actions |
| ayuda contextual, banner de ayuda | transaction_helper, helpers container | flow-chat-state-chips-and-support-actions |
| tarea de operador, ticket interno | task, TaskTypesEnum | flow-operator-interventions-and-panel-actions |
| mensaje del usuario que termina en tarea, escalar mensaje a operador | MergePublicTextAndCreateAnOperatorTaskJob, task | flow-chat-state-chips-and-support-actions, flow-operator-interventions-and-panel-actions |

## Contextos de acceso

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| link de transacción, acceso sin login | public transaction context, /t/... | flow-transaction-visibility-and-status, flow-public-order-creation-and-identity-bootstrap |
| dashboard, panel del usuario | dashboard context, /my/... | flow-transaction-visibility-and-status |
| beforepath | prefijo de API: t (público) o users/{id} (dashboard) | todos los flows con rutas duales |
| link de usuario sin login | user key context, /u/... | flow-public-order-creation-and-identity-bootstrap |

## Notificaciones

| Lo que dice el usuario / soporte | Término interno | Flow relevante |
|---|---|---|
| no me llegó el email | StateNotificationsRepository, TransactionFirstEmailJob | flow-notifications-mails-and-background-jobs |
| recordatorio de pago | DirectTransferVisitedButDontPaidJob | flow-notifications-mails-and-background-jobs |
| notificación tardía | debounce, throttle, working-hour logic | flow-notifications-mails-and-background-jobs |
