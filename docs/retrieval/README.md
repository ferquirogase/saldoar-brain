# Retrieval

Esta carpeta prepara el brain para RAG sin depender todavia de un framework pesado.

## Objetivo

Tener un corpus:

- regenerable desde el brain
- estable para embeddings o BM25
- explicable para debugging
- extensible cuando sumemos mas flows, dominios, entidades o integraciones

## Estrategia actual

La unidad logica exportada es el documento del brain:

- flow
- domain
- entity
- integration
- edge_case

Cada registro sale de:

- su YAML estructurado
- su `README.md` asociado, si existe
- sus referencias tecnicas
- o, para `edge_case`, preferentemente de `edge_case.yaml` + markdown asociado
- si un edge case todavia no tiene YAML, usa fallback al markdown puro

## Script

- `docs/scripts/build-retrieval-corpus.ps1`
- `docs/scripts/query-brain-retrieval.ps1`
- `docs/scripts/evaluate-brain-retrieval.ps1`

Salida default:

- `docs/retrieval/brain-retrieval-corpus.jsonl`

## Que exporta cada record

- `doc_id`
- `kind`
- `name`
- `status`
- `priority`
- `query_patterns`
- `doc_paths`
- `source_paths`
- `linked_ids`
- `structured_text`
- `narrative_text`
- `retrieval_text`

## Para que sirve cada campo

- `structured_text`
  Texto corto y limpio para routing semantico.

- `narrative_text`
  Cuerpo humano del `README`, util para expansion de contexto.

- `retrieval_text`
  Mezcla de nombre, abstract/summary, query patterns y narrativa. Es el mejor candidato para indexacion inicial.

## Uso recomendado

V1 del retriever:

1. indexar `retrieval_text`
2. recuperar top 1-3 records
3. abrir sus `doc_paths`
4. si hace falta, expandir a codigo usando `source_paths`

## Query local

El query script no usa un framework externo. Sirve para:

- probar routing semantico rapido
- entender por que un documento rankeo arriba
- validar `query_patterns`
- medir ruido antes de montar embeddings o rerankers

Uso:

```powershell
powershell -ExecutionPolicy Bypass -File .\docs\scripts\query-brain-retrieval.ps1 -Query "por que no me aparece el qr"
powershell -ExecutionPolicy Bypass -File .\docs\scripts\query-brain-retrieval.ps1 -Query "complete biometria y no se aprobo" -TopK 3
powershell -ExecutionPolicy Bypass -File .\docs\scripts\evaluate-brain-retrieval.ps1
```

El script:

- lee `brain-retrieval-corpus.jsonl`
- expande sinonimos desde `00_Index/synonyms.md`
- puntua por `doc_id`, `name`, `query_patterns` y overlap textual
- aplica un rerank liviano sobre el top inicial usando n-grams y terminos internos
- prioriza flows cuando hay empate funcional
- permite que edge cases rankeen cuando la pregunta apunta a una casuistica concreta
- resuelve `linked_ids` contra el corpus y devuelve `contexto_secundario` cuando encuentra docs relacionados
- devuelve score, razones, docs y fuentes tecnicas sugeridas

## Orden de retrieval recomendado

1. correr `build-retrieval-corpus.ps1`
2. usar `query-brain-retrieval.ps1` para routing inicial
3. abrir `flow.yaml`, `domain.yaml`, `entity.yaml` o `integration.yaml` candidatos
4. expandir a `README.md`
5. si hace falta, abrir codigo con `source_paths`

## Evaluacion

Hay una capa simple de evaluación en `docs/retrieval/evaluation/`.

Sirve para:

- medir baseline antes de tocar scoring
- comparar mejoras del retriever
- detectar qué área cae peor
- evitar optimizar “a ojo”

Métricas iniciales:

- `top1_accuracy`
- `hit@3`
- `mean_precision@3`

## Decision importante

No usar el bootstrap completo como documento principal del index.

El corpus se genera por documento logico del brain, lo que baja ruido y hace mas facil:

- enrutar preguntas
- explicar por que algo se recupero
- mantener el corpus cuando el brain crece
