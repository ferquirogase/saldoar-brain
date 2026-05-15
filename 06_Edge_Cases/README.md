# Edge Cases

Repositorio de comportamientos raros, constraints del producto y zonas grises.

Cada caso deberia registrar:

- contexto
- condicion disparadora
- comportamiento observado
- impacto
- si es bug, debt o comportamiento esperado
- fuente

## Formato recomendado

- `edge_case.yaml` para estructura consumible por agentes y retrieval
- `.md` con el mismo basename para explicacion humana

Campos minimos sugeridos en YAML:

- `edge_case_id`
- `name`
- `summary`
- `query_patterns`
- `connected_flows`
- `connected_entities`
- `connected_integrations`
- `source_of_truth`

## Casos documentados

| Edge Case | Tipo | Relacion principal |
|---|---|---|
| `simultaneous-orders-omitted` | comportamiento esperado con friccion UX | `concurrent-orders-and-omitted-transactions` |
| `stale-public-quote-session` | debt UX / continuidad ambigua | `system-selection-and-quote-calculator`, `landing-for-systems-and-marketing-preloads` |
| `legacy-system-links-and-replacements` | comportamiento esperado con impacto SEO/marketing | `landing-for-systems-and-marketing-preloads` |
| `pix-key-late-held` | comportamiento esperado con friccion alta | `accounts-and-destination-selection`, `kamipay`, `cancellation-held-mediation-recovery` |
| `instructions-read-side-effects` | comportamiento esperado poco visible | `payment-instructions`, `notifications-mails-and-background-jobs` |
| `vcc-copy-looks-like-balance-reception` | friccion UX por semantica incorrecta | `payment-instructions`, `system-specific-branches` |
| `chat-visible-but-locked` | friccion UX por control backend | `chat-state-chips-and-support-actions`, `transaction-visibility-and-status` |
| `held-disputed-without-screenshots` | comportamiento esperado dificil de explicar | `cancellation-held-mediation-recovery` |
| `to-future-ready-looks-stalled` | estado valido con apariencia de bloqueo | `create-transaction-and-next-step`, `chat-state-chips-and-support-actions` |

## Como usar esta carpeta

- Si el flow explica el recorrido normal, el edge case explica por que ese recorrido se rompe o se siente raro.
- No conviene duplicar toda la logica del flow: alcanza con la condicion disparadora, el efecto visible y el impacto.
- Si un caso borde se vuelve recurrente en soporte o producto, despues puede escalar a FAQ o a una ficha para agentes.
