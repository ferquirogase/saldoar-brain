# Saldoar Brain — AGENTS.md

## Propósito del repositorio

Base de conocimiento operativa de Saldoar. Responde preguntas sobre el producto con trazabilidad desde la experiencia del usuario hasta el código fuente.

Audiencia: soporte, marketing, UX, producto, operaciones y agentes de IA.

## Estructura

| Carpeta | Contenido | Estado |
|---|---|---|
| `00_Index/` | Índice general y convenciones de documentación | Activo |
| `01_Domains/` | Dominios de negocio y código | En construcción |
| `02_Flows/` | Flujos end-to-end — fuente primaria de verdad | Activo |
| `03_Entities/` | Entidades clave del dominio | En construcción |
| `04_Integrations/` | Servicios externos y puntos de contacto | En construcción |
| `05_FAQ_By_Area/` | Preguntas frecuentes por equipo | En construcción |
| `06_Edge_Cases/` | Comportamientos inesperados y zonas grises | En construcción |
| `07_Agent_Context/` | Contexto listo para inyectar en agentes | Activo |
| `99_Templates/` | Plantillas para nuevos documentos | Activo |

## Flujos disponibles

| ID | Carpeta | Descripción |
|---|---|---|
| `flow-transaction-visibility-and-status` | `02_Flows/transaction-visibility-and-status/` | Consulta de estado por mid+email, deep links, validaciones pendientes, cancelación, redirects legacy |
| `flow-payment-instructions` | `02_Flows/payment-instructions/` | Instrucciones de pago por tipo de operación, mecanismo de lectura dual, helpers contextuales |
| `flow-identity-validations` | `02_Flows/identity-validations/` | Validaciones de identidad: DNI, selfie, Facebook, biométrica (Veriff), screenshot |

## Instrucciones de uso

- Para responder sobre comportamiento del producto: leer `02_Flows/{flow}/flow.yaml` primero, luego el `README.md`
- Para responder a soporte o marketing: traducir lógica técnica a lenguaje operativo
- Indicar siempre el nivel de evidencia: `confirmed`, `inferred`, `unknown`
- Ruta pública (`/t/...`) y ruta dashboard (`/my/...`) tienen comportamientos distintos — no asumir equivalencia
- Si la pregunta no tiene respuesta en el brain: decirlo claramente, sin inventar

## Bootstrap completo

Ver `07_Agent_Context/saldoar-brain-bootstrap.md` para contexto extendido del producto, vocabulario completo y protocolo de consulta.
