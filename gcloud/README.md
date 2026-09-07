# gcloud — Component Mindmaps

Mapas mentais do Google Cloud CLI (`gcloud`) para apoio ao estudo da certificação
**Google Cloud Associate Cloud Engineer**.

A organização segue a hierarquia:

```text
gcloud
└── COMPONENT
    └── ENTITY
```

Os diagramas são mantidos em **PlantUML Mindmap** como fonte canônica.

## Estrutura

```text
gcloud/
└── 01-core/
    ├── compute/
    │   ├── README.md
    │   └── compute.puml
    └── storage/
        ├── README.md
        └── storage.puml
```

## Componentes

| Prioridade | Component | Diagrama |
|---:|---|---|
| 01 | `compute` | [01-core/compute](01-core/compute/) |
| 02 | `storage` | [01-core/storage](01-core/storage/) |

## Padrão visual

- Root: `#4285F4`
- Depth 1: `#E8F0FE`
- Depth 2: `#F8F9FA`
- Texto: `#202124`
- Bordas/conexões: `#4285F4`

## Renderização

Os arquivos `.puml` são a fonte oficial dos diagramas.

O workflow localizado em:

```text
.github/workflows/render-gcloud-plantuml.yml
```

pode gerar os arquivos `.svg` automaticamente no GitHub.
