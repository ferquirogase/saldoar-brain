# Veriff

## Simple Definition
`Veriff` es la integracion que Saldoar usa para la validacion biometrica de identidad.

No es un uploader comun ni una validacion interna simple: crea una sesion externa, devuelve una `verification_url`, recibe decisiones por webhook y puede sincronizar media o datos derivados a Saldoar.

## Why It Matters
Es una integracion de alto impacto porque cruza:

- validacion de identidad
- riesgo y aprobacion operativa
- experiencia embebida en iframe
- retorno al flujo transaccional
- evidencia externa que despues influye en estados o revisiones

## Main Product Role
En Saldoar, `Veriff` aparece sobre todo en `biometric_id`.

El flujo base es:

1. backend crea sesion con datos del usuario
2. front recibe `verification_url`
3. usuario completa o abandona la experiencia externa
4. Veriff envia decision por webhook
5. listeners y handlers internos actualizan validacion, observaciones y datos asociados

## Main Flows Connected

- `identity-validations`
- `public-order-creation-and-identity-bootstrap`

## Main Backend Surface

- `saldo/app/Validations/Validations/BiometricIdValidation/BiometricIdValidationService.php`
- `saldo/app/External/Veriff/VeriffCreateVerificationSessionService.php`
- `saldo/app/External/Veriff/Webhooks/VeriffDecisionWebhookController.php`
- `saldo/app/External/Veriff/VeriffWebhookValidationService.php`
- `saldo/app/Validations/Validations/ExternalDecisionListener.php`
- `saldo/app/Validations/Validations/BiometricIdValidation/Listeners/`
- `saldo/app/Validations/Validations/BiometricIdValidation/Commands/SynchronizeUserFilesCommand.php`

## Main Frontend Surface

- `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric.component.ts`
- `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric-view-model.service.ts`
- `solido/apps/solido-app/src/domain/use-cases/get-biometric-id-use-case.ts`
- `solido/apps/solido-app/src/domain/services/biometric-id-validation.service.ts`

## What It Triggers

- creacion de sesion biometrica
- persistencia de `verification_id` en observaciones privadas
- decision externa via webhook
- posible actualizacion del estado de la validacion
- posible sincronizacion de archivos o media de evidencia

## Failure Or Friction Modes

- falla al crear sesion: el usuario no entra a biometria
- webhook invalido o no procesado: la decision externa no aterriza bien en Saldoar
- media externa no sincronizada: soporte ve decision pero no suficiente evidencia
- retorno pobre al flujo: el usuario siente que salio de la app y no sabe que sigue

## UX / Support Reading

- Si el usuario dice "me saco de la app", probablemente esta hablando de Veriff.
- Si la biometria se completo pero Saldoar no refleja el resultado, hay que mirar decision webhook o listeners.
- Si falta contexto visual sobre por que se abre una experiencia externa, el problema es de copy y framing, no solo tecnico.

## Questions This Integration Helps Answer

- por que se abre una pantalla externa para validar identidad
- como vuelve el usuario al flujo despues de biometria
- donde se crea la URL de verificacion
- como entra la decision de Veriff al sistema
- por que una biometria completada todavia puede no verse aprobada

## Main References

- `saldo/app/Validations/Validations/BiometricIdValidation/BiometricIdValidationService.php`
- `saldo/app/External/Veriff/Webhooks/VeriffDecisionWebhookController.php`
- `saldo/app/Validations/Validations/ExternalDecisionListener.php`
- `saldo/app/Validations/Validations/BiometricIdValidation/Commands/SynchronizeUserFilesCommand.php`
- `solido/apps/solido-app/src/ui/features/validations/components/validation-biometric/validation-biometric.component.ts`
- `solido/apps/solido-app/src/domain/use-cases/get-biometric-id-use-case.ts`

## Evidence Level

- `confirmed`
