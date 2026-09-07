# gcloud — Component Mindmaps

Mapas mentais dos principais grupos do Google Cloud CLI (`gcloud`), organizados por prioridade para estudo da certificação **Google Cloud Associate Cloud Engineer** e trilhas relacionadas.

Cada componente possui:

- `README.md`
- arquivo fonte PlantUML `.puml`
- SVG gerado automaticamente pelo GitHub Actions após o push

## Estrutura conceitual

```text
gcloud
└── COMPONENT
    └── ENTITY
```

## Componentes

### 01-core

| Ordem | Component | Mapa |
|---:|---|---|
| 01 | `compute` | [compute](01-core/compute/) |
| 02 | `storage` | [storage](01-core/storage/) |
| 03 | `container` | [container](01-core/container/) |
| 04 | `run` | [run](01-core/run/) |
| 05 | `functions` | [functions](01-core/functions/) |
| 06 | `sql` | [sql](01-core/sql/) |
| 07 | `pubsub` | [pubsub](01-core/pubsub/) |
| 08 | `dns` | [dns](01-core/dns/) |
| 09 | `logging` | [logging](01-core/logging/) |
| 10 | `monitoring` | [monitoring](01-core/monitoring/) |
| 11 | `iam` | [iam](01-core/iam/) |
| 12 | `projects` | [projects](01-core/projects/) |
| 13 | `services` | [services](01-core/services/) |
| 14 | `auth` | [auth](01-core/auth/) |
| 15 | `config` | [config](01-core/config/) |
| 16 | `artifacts` | [artifacts](01-core/artifacts/) |

### 02-operations

| Ordem | Component | Mapa |
|---:|---|---|
| 17 | `scheduler` | [scheduler](02-operations/scheduler/) |
| 18 | `secrets` | [secrets](02-operations/secrets/) |
| 19 | `builds` | [builds](02-operations/builds/) |
| 20 | `deploy` | [deploy](02-operations/deploy/) |
| 21 | `resource-manager` | [resource-manager](02-operations/resource-manager/) |
| 22 | `asset` | [asset](02-operations/asset/) |
| 23 | `billing` | [billing](02-operations/billing/) |
| 24 | `tasks` | [tasks](02-operations/tasks/) |
| 25 | `workflows` | [workflows](02-operations/workflows/) |
| 26 | `app` | [app](02-operations/app/) |

### 03-data

| Ordem | Component | Mapa |
|---:|---|---|
| 27 | `dataproc` | [dataproc](03-data/dataproc/) |
| 28 | `dataflow` | [dataflow](03-data/dataflow/) |
| 29 | `bigtable` | [bigtable](03-data/bigtable/) |
| 30 | `spanner` | [spanner](03-data/spanner/) |
| 31 | `datastream` | [datastream](03-data/datastream/) |
| 32 | `dataplex` | [dataplex](03-data/dataplex/) |
| 33 | `composer` | [composer](03-data/composer/) |
| 34 | `database-migration` | [database-migration](03-data/database-migration/) |
| 35 | `alloydb` | [alloydb](03-data/alloydb/) |
| 36 | `biglake` | [biglake](03-data/biglake/) |
| 37 | `redis` | [redis](03-data/redis/) |
| 38 | `bq` | [bq](03-data/bq/) |

### 04-network-security

| Ordem | Component | Mapa |
|---:|---|---|
| 39 | `network-management` | [network-management](04-network-security/network-management/) |
| 40 | `network-security` | [network-security](04-network-security/network-security/) |
| 41 | `network-connectivity` | [network-connectivity](04-network-security/network-connectivity/) |
| 42 | `scc` | [scc](04-network-security/scc/) |
| 43 | `access-context-manager` | [access-context-manager](04-network-security/access-context-manager/) |
| 44 | `access-approval` | [access-approval](04-network-security/access-approval/) |
| 45 | `beyondcorp` | [beyondcorp](04-network-security/beyondcorp/) |
| 46 | `api-gateway` | [api-gateway](04-network-security/api-gateway/) |
| 47 | `apigee` | [apigee](04-network-security/apigee/) |
| 48 | `service-directory` | [service-directory](04-network-security/service-directory/) |

### 05-ai-ml

| Ordem | Component | Mapa |
|---:|---|---|
| 49 | `ai` | [ai](05-ai-ml/ai/) |
| 50 | `ai-platform` | [ai-platform](05-ai-ml/ai-platform/) |
