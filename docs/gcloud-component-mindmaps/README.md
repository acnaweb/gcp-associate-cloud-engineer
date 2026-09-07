# gcloud Component Mindmaps

Repositório visual para estudo da estrutura do Google Cloud CLI (`gcloud`), organizado por **COMPONENT** e suas principais **ENTITY**.

O objetivo é facilitar a memorização da hierarquia:

```text
gcloud
└── COMPONENT
    └── ENTITY
```

Os diagramas usam **Mermaid Mindmap**, renderizado automaticamente pelo GitHub.

## Prioridade atual

| Ordem | Component | Arquivo |
|---|---|---|
| 01 | `compute` | [01-core/compute.md](01-core/compute.md) |
| 02 | `storage` | [01-core/storage.md](01-core/storage.md) |

## Estrutura

```text
gcloud-component-mindmaps/
│
├── README.md
│
└── 01-core/
    ├── compute.md
    └── storage.md
```

## Como ler os mapas

O nó central representa sempre o **COMPONENT**.

Abaixo dele, os recursos são agrupados por função quando isso melhora a leitura. As folhas representam as principais **ENTITY** ou subgrupos relevantes do comando.

Exemplo:

```text
gcloud
└── compute
    └── instances
```

Comando correspondente:

```bash
gcloud compute instances list
```

## Escopo

Nesta primeira versão, o repositório contém apenas os dois componentes de maior prioridade para validação do padrão visual:

1. `compute`
2. `storage`

Depois da validação, a mesma estrutura pode ser expandida para `container`, `run`, `functions`, `sql`, `pubsub`, `dns`, `logging`, `monitoring`, `iam` e demais componentes.
