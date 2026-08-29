# MATRIZ-CONTEUDO-ACE.md

> Fonte de verdade: guia oficial anexado.
>
> A coluna binária `✅` não é mais usada como único critério de qualidade. Para saber se um tópico foi apenas citado, explicado ou realmente praticado, consulte **[MATRIZ-MEP-ACE.md](./MATRIZ-MEP-ACE.md)**.

> Fonte de verdade desta matriz: **Associate Cloud Engineer — Guia do exame de certificação**, PDF oficial anexado pelo usuário.
>
> Esta matriz separa:
>
> - **Conteúdo oficial do guia anexado**: obrigatório para a preparação;
> - **Conteúdo complementar**: pode permanecer no roadmap, mas não deve ser apresentado como requisito explícito do guia anexado.

---

# Seção 1 — Configurar um ambiente de solução de nuvem (~20%)

## 1.1 Projetos de nuvem e contas

- [x] Hierarquia de recursos
- [x] Organization
- [x] Folders
- [x] Projects
- [x] Aplicar políticas organizacionais à hierarquia
- [x] IAM em projetos
- [x] Conceder papéis IAM a membros/principals
- [x] Cloud Identity
- [x] Gerenciar usuários no Cloud Identity
- [x] Gerenciar grupos no Cloud Identity
- [x] Ativar APIs nos projetos
- [x] Google Cloud Observability
- [x] Provisionar/configurar produtos de Observability
- [x] Quotas
- [x] Avaliar quotas
- [x] Processo de solicitação de aumento de quota

## 1.2 Faturamento

- [x] Billing Accounts
- [x] Criar/entender contas de faturamento
- [x] Vincular projetos a Billing Account
- [x] Budgets
- [x] Billing Alerts
- [x] Billing Export
- [x] Exportação de faturamento para análise

---

# Seção 2 — Planejar e configurar uma solução de nuvem (~17,5%)

## 2.1 Recursos de computação

- [x] Seleção entre Compute Engine
- [x] Seleção entre GKE
- [x] Seleção entre Cloud Run
- [x] Seleção entre Cloud Functions
- [x] Spot VMs
- [x] Custom Machine Types

## 2.2 Armazenamento de dados

### Seleção de produtos

- [x] Cloud SQL
- [x] BigQuery
- [x] Firestore
- [x] Spanner
- [x] Bigtable

### Opções de armazenamento

- [x] Persistent Disk zonal
- [x] Persistent Disk regional
- [x] Cloud Storage Standard
- [x] Cloud Storage Nearline
- [x] Cloud Storage Coldline
- [x] Cloud Storage Archive

## 2.3 Networking

- [x] Load Balancing
- [x] Disponibilidade/localização de recursos de rede
- [x] Network Service Tiers

---

# Seção 3 — Implantar e implementar uma solução de nuvem (~25%)

## 3.1 Compute Engine

- [x] Inicializar uma VM
- [x] Atribuir discos
- [x] Política de disponibilidade da VM
- [x] Chaves SSH
- [x] Instance Template
- [x] Managed Instance Group
- [x] Autoscaling
- [x] OS Login
- [x] VM Manager

## 3.2 GKE

- [x] Instalar/configurar kubectl
- [x] GKE Autopilot
- [x] GKE regional
- [x] GKE private cluster
- [x] GKE Enterprise
- [x] Implantar aplicação containerizada no GKE

## 3.3 Cloud Run e Cloud Functions

- [x] Implantar aplicação no Cloud Run
- [x] Implantar aplicação no Cloud Functions
- [x] Eventos Pub/Sub
- [x] Eventos de alteração de objetos no Cloud Storage
- [x] Eventarc
- [x] Comparar Cloud Run totalmente gerenciado
- [x] Comparar Cloud Run for Anthos, conforme terminologia do guia anexado
- [x] Comparar Cloud Functions

## 3.4 Soluções de dados

- [x] Cloud SQL
- [x] Firestore
- [x] BigQuery
- [x] Spanner
- [x] Pub/Sub
- [x] Dataflow
- [x] Cloud Storage
- [x] AlloyDB
- [x] Upload de dados via CLI
- [x] Carregar dados a partir do Cloud Storage
- [x] Storage Transfer Service

## 3.5 Networking

- [x] Criar VPC
- [x] VPC custom mode
- [x] Shared VPC
- [x] Subnets
- [x] Firewall ingress
- [x] Firewall egress
- [x] Source IP/subnet ranges
- [x] Network Tags
- [x] Service Accounts como alvo/critério de firewall
- [x] VPC Network Peering
- [x] Cloud VPN

## 3.6 Infrastructure as Code

- [x] Cloud Foundation Toolkit
- [x] Config Connector
- [x] Terraform
- [x] Helm

---

# Seção 4 — Garantir a operação bem-sucedida (~20%)

## 4.1 Compute Engine

- [x] Conectar remotamente à VM
- [x] Inventário/listagem de VMs
- [x] IDs e detalhes da instância
- [x] Snapshots: visualizar
- [x] Snapshots: excluir
- [x] Snapshot schedules
- [x] Criar snapshot a partir de VM/disco
- [x] Images: criar
- [x] Images: visualizar
- [x] Images: excluir
- [x] Criar image a partir de VM/snapshot quando aplicável

## 4.2 GKE

- [x] Inventário de clusters
- [x] Nodes
- [x] Pods
- [x] Services
- [x] Artifact Registry + GKE
- [x] Node pools: adicionar
- [x] Node pools: editar
- [x] Node pools: remover
- [x] StatefulSets
- [x] HPA
- [x] VPA

## 4.3 Cloud Run

- [x] Novas versions/revisions
- [x] Traffic splitting
- [x] Autoscaling
- [x] Parâmetros de scaling

## 4.4 Storage e databases

- [x] Gerenciar objetos em Cloud Storage
- [x] Proteger objetos em Cloud Storage
- [x] Object Lifecycle Management
- [x] Consultar Cloud SQL
- [x] Consultar BigQuery
- [x] Consultar Spanner
- [x] Consultar Firestore
- [x] Consultar AlloyDB
- [x] Estimar custos de armazenamento de dados
- [x] Backup de Cloud SQL
- [x] Restore de Cloud SQL
- [x] Backup de Firestore
- [x] Restore de Firestore
- [x] Status de jobs Dataflow
- [x] Status de jobs BigQuery

## 4.5 Networking

- [x] Adicionar subnet a VPC
- [x] Expandir subnet IPv4
- [x] Reservar IP estático interno
- [x] Reservar IP estático externo
- [x] Cloud DNS
- [x] Cloud NAT

## 4.6 Monitoring e Logging

- [x] Alertas Cloud Monitoring
- [x] Métricas de recursos
- [x] Custom Metrics
- [x] Ingestão de custom metrics
- [x] Exportar logs para sistemas externos
- [x] Exportar logs para ambiente on-premises
- [x] Exportar logs para BigQuery
- [x] Log Buckets
- [x] Log Router
- [x] Log Analytics / análise de logs
- [x] Visualizar logs
- [x] Filtrar logs
- [x] Visualizar detalhes de uma entrada de log
- [x] Cloud diagnostics / diagnóstico de nuvem
- [x] Visualizar status do Google Cloud
- [x] Ops Agent
- [x] Managed Service for Prometheus
- [x] Audit Logs

---

# Seção 5 — Configurar acesso e segurança (~17,5%)

## 5.1 IAM

- [x] Visualizar IAM Policies
- [x] Criar IAM Policies
- [x] Basic Roles
- [x] Predefined Roles
- [x] Custom Roles
- [x] Criar/definir Custom Roles

## 5.2 Service Accounts

- [x] Criar Service Accounts
- [x] Least privilege para Service Accounts
- [x] Usar Service Accounts em IAM Policies
- [x] Atribuir Service Accounts a recursos
- [x] Gerenciar IAM de uma Service Account
- [x] Identidade temporária de Service Account
- [x] Impersonation
- [x] Credenciais de curta duração

---

# Conteúdo complementar do roadmap

Os tópicos abaixo podem ser úteis profissionalmente, mas **não aparecem explicitamente no guia anexado** e não devem ser tratados como requisitos oficiais dessa versão do exame:

- Cloud Asset Inventory
- Workforce Identity Federation
- Hyperdisk
- GPU / TPU
- Agent Runtime
- Workbench
- Cloud Workstations
- Cloud NGFW
- Secure Tags
- Interconnect / BGP / Cloud Router (além do necessário ao cenário de VPN)
- Autoclass
- CMEK
- Filestore
- NetApp Volumes
- Managed Lustre
- Managed Kafka
- Memorystore
- Database Center
- Cloud Run Jobs
- Workload Identity Federation
- ADC
- Policy Troubleshooter
- VPC Flow Logs / Firewall Logs
- Trace / Profiler / Query Insights / Index Advisor
- Personalized Service Health / Active Assist / Cloud Hub
- Fabric FAST
- ferramentas de IA assistida

Esses tópicos podem permanecer como **aprofundamento opcional**, mas a preparação principal deve priorizar os itens das Seções 1–5 acima.
