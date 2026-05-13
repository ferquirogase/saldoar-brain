# Traceability and Drift

Esta capa conecta el brain con `saldo` y `solido` para reducir riesgo de obsolescencia.

## Objetivo

No intenta autodocumentar todo. Intenta detectar rapido:

- que documentos podrian haber quedado viejos
- que cambio tecnico los impacta
- que zonas del brain no tienen suficiente trazabilidad

## Fuentes de trazabilidad

El detector reutiliza primero los campos ya presentes en los YAML:

- `02_Flows/*/flow.yaml`
  - `frontend_sources`
  - `backend_sources`
  - `source_of_truth`

- `03_Entities/*/entity.yaml`
  - `backend_model`
  - `frontend_surface`
  - `source_of_truth`

- `01_Domains/*/domain.yaml`
  - `backend_surface`
  - `frontend_surface`
  - `source_of_truth`

## Metadata recomendada

Cuando se revise un documento importante, conviene agregar:

```yaml
review:
  owner: ux
  confidence: high
  last_reviewed_at: 2026-05-13
  reviewed_against:
    saldo: abc1234
    solido: def5678
```

Y cuando haga falta agregar trazabilidad extra que no entra en `backend_sources` o `frontend_surface`:

```yaml
source_of_truth:
  - saldo/app/Transactions/...
  - solido/apps/solido-app/src/app/...
```

## Overrides manuales

Para documentos que no tienen YAML propio o para relaciones especiales, usar:

- `docs/traceability/manual-links.json`

Formato:

```json
{
  "version": 1,
  "manual_docs": [
    {
      "doc_id": "doc-id",
      "kind": "index",
      "docs": ["README.md"],
      "source_paths": [
        "saldo/app/Transactions",
        "solido/apps/solido-app/src/app/transactions"
      ],
      "notes": "Opcional"
    }
  ]
}
```

## Script disponible

Archivo:

- `docs/scripts/brain-impact-report.ps1`

Hace esto:

- lee flujos, entidades y dominios con trazabilidad
- suma overrides manuales
- lee cambios de git en `saldo` y `solido`
- cruza archivos cambiados con rutas documentadas
- devuelve documentos impactados

## Modos de uso

Cambios sin commitear:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\brain-impact-report.ps1
```

Ultimo rango de commits:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\brain-impact-report.ps1 -Mode head_range -CommitRange HEAD~1..HEAD
```

Guardar reporte:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\brain-impact-report.ps1 -OutputPath .\docs\traceability\last-impact-report.md
```

## Lectura del resultado

- `exact_file`: cambio directo en un archivo fuente documentado
- `within_directory`: cambio dentro de una carpeta que el brain declara como superficie del dominio o del flujo

## Limites

- detecta impacto probable, no verdad funcional garantizada
- no reemplaza revision humana
- si una doc no declara fuentes, no puede ser detectada automaticamente
- si el codigo cambia de comportamiento sin mover archivos relevantes, el reporte puede quedar corto

## Siguiente mejora sugerida

- agregar `review` a flows y entidades mas criticas
- generar issue o tarea automaticamente cuando haya drift
- integrar este chequeo en CI o rutina de release
