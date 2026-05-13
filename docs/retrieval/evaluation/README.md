# Retrieval Evaluation

Esta carpeta sirve para medir si el retriever realmente encuentra los documentos correctos antes de confiar en el RAG para uso más serio.

## Objetivo

Tener un set de preguntas reales con documento esperado para poder medir:

- `top1_accuracy`
- `hit@3`
- `mean_precision@3`

## Archivos

- `retrieval-eval-set.jsonl`
  Dataset de evaluación. Un JSON por línea.

## Formato del dataset

Cada caso tiene este shape:

```json
{"case_id":"support-001","area":"support","query":"por que un pedido desaparecio cuando hice dos al mismo tiempo","expected_doc_ids":["flow-concurrent-orders-and-omitted-transactions","simultaneous-orders-omitted"]}
```

Campos:

- `case_id`
- `area`
- `query`
- `expected_doc_ids`

`expected_doc_ids` admite más de un documento correcto. Esto sirve para preguntas donde puede ser aceptable un `flow` troncal o un `edge_case` más específico.

## Script

- `docs/scripts/evaluate-brain-retrieval.ps1`

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\evaluate-brain-retrieval.ps1
powershell -ExecutionPolicy Bypass -File .\docs\scripts\evaluate-brain-retrieval.ps1 -TopK 5
```

## Cómo usar esta capa

1. arrancar con el set inicial
2. sumar preguntas reales de soporte, marketing, UX, producto y operaciones
3. correr baseline
4. ajustar retrieval
5. volver a medir

## Criterio práctico

- si `top1_accuracy` sube, mejora el routing principal
- si `hit@3` sube, mejora la recuperación asistida
- si `precision@3` sube, baja el ruido de contexto secundario

## Próximo umbral razonable

Antes de confiar mucho en el RAG:

- llevar el set a `20-30` casos
- cubrir al menos `support`, `marketing`, `ux`, `product`, `operations`
- revisar especialmente los fallos de `top1`
