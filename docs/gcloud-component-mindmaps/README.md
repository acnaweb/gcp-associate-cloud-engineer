# gcloud Component Mindmaps

Mapas mentais visuais da Google Cloud CLI (`gcloud`), organizados por **COMPONENT** e suas principais **ENTITY**.

## Objetivo

Facilitar a leitura e memorização da hierarquia:

```text
gcloud
└── COMPONENT
    └── ENTITY
```

Cada componente possui:

- `README.md` — documentação e exemplos;
- `.puml` — fonte editável PlantUML;
- `.svg` — visualização direta no GitHub.

## Padrão visual

O padrão adotado preserva o estilo aprovado para os mindmaps PlantUML:

- componente central: `#4285F4` com texto branco;
- agrupamentos de primeiro nível: `#E8F0FE`;
- entidades: `#F8F9FA`;
- texto: `#202124`;
- conexões/bordas: `#4285F4`.

## Componentes nesta versão de validação

| Prioridade | Component | Mapa |
|---:|---|---|
| 01 | `compute` | [Abrir](01-core/compute/README.md) |
| 02 | `storage` | [Abrir](01-core/storage/README.md) |

## Estrutura

```text
gcloud-component-mindmaps-plantuml/
│
├── README.md
└── 01-core/
    ├── compute/
    │   ├── README.md
    │   ├── compute.puml
    │   └── compute.svg
    └── storage/
        ├── README.md
        ├── storage.puml
        └── storage.svg
```

## Renderização local

Com Java e PlantUML instalados:

```bash
java -jar plantuml.jar -tsvg 01-core/compute/compute.puml
java -jar plantuml.jar -tsvg 01-core/storage/storage.puml
```

O arquivo `.puml` é a fonte canônica; o `.svg` é mantido no repositório para visualização imediata no GitHub.
