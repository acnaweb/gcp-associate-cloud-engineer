# Google Cloud Associate Cloud Engineer — Roadmap Prático 2026

Roadmap prático de preparação para a certificação **Google Cloud Associate Cloud Engineer (ACE)**.

O conteúdo está organizado em **8 semanas**, com aulas em Markdown, laboratórios executáveis, troubleshooting, questões estilo prova, simulados e revisão final.

---

# Índice

- [Metodologia](#metodologia)
- [Estrutura do Repositório](#estrutura-do-repositório)
- [Semana 1 — Fundamentos, Projects e IAM](#semana-1--fundamentos-projects-e-iam)
- [Semana 2 — Compute Engine](#semana-2--compute-engine)
- [Semana 3 — VPC e Networking](#semana-3--vpc-e-networking)
- [Semana 4 — Storage e Databases](#semana-4--storage-e-databases)
- [Semana 5 — Containers, Cloud Run e GKE](#semana-5--containers-cloud-run-e-gke)
- [Semana 6 — Operations, Monitoring, Logging, Billing e Terraform](#semana-6--operations-monitoring-logging-billing-e-terraform)
- [Semana 7 — Segurança e IAM Avançado](#semana-7--segurança-e-iam-avançado)
- [Semana 8 — Revisão, Simulados e Estratégia de Prova](#semana-8--revisão-simulados-e-estratégia-de-prova)
- [Ferramentas Utilizadas](#ferramentas-utilizadas)
- [Fluxo de Troubleshooting](#fluxo-de-troubleshooting)
- [Checklist de Preparação](#checklist-de-preparação)
- [Referências Oficiais](#referências-oficiais)

---

# Metodologia

As aulas práticas seguem o fluxo:

```text
Conceito
   ↓
Criar / Configurar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Troubleshooting
   ↓
Corrigir
   ↓
Questões estilo prova
   ↓
Cleanup
```

O objetivo é desenvolver três competências:

```text
Conhecer
   +
Operar
   +
Diagnosticar
```

Não basta reconhecer o nome de um serviço.

Ao concluir uma aula, o aluno deve conseguir responder:

```text
O que é?
Para que serve?
Quando usar?
Como criar?
Como inspecionar?
Como testar?
Como diagnosticar?
Como corrigir?
Como remover?
```

---

# Estrutura do Repositório

```text
gcp-associate-cloud-engineer/
│
├── README.md
├── AUDITORIA-EXAM-GUIDE.md
├── ARQUIVOS.md
│
├── semana-01-fundamentos-projetos-iam/
├── semana-02-compute-engine/
├── semana-03-vpc-networking/
├── semana-04-storage-databases/
├── semana-05-containers-cloud-run-gke/
├── semana-06-operations-monitoring-logging-billing-terraform/
├── semana-07-seguranca-iam-avancado-cenarios/
└── semana-08-revisao-simulados-estrategia-prova/
```

---

# Semana 1 — Fundamentos, Projects e IAM

Objetivo:

> Entender como o Google Cloud organiza recursos, identidades, permissões, projetos, APIs e contexto operacional.

## Conteúdo

- Resource hierarchy;
- Organization;
- Folders;
- Projects;
- Project ID;
- Project Number;
- Regions;
- Zones;
- Cloud Shell;
- `gcloud`;
- configurations;
- APIs e Services;
- Cloud Identity;
- Organization Policies;
- IAM;
- Principals;
- Permissions;
- Roles;
- Basic Roles;
- Predefined Roles;
- Custom Roles;
- Service Accounts;
- Least Privilege;
- Billing Account;
- Budgets;
- Billing Export;
- Quotas.

## Aulas

- [Aula 1 — Hierarquia, Projects, Regions, Zones e gcloud](./semana-01-fundamentos-projetos-iam/aula-01-hierarquia-projects-regions-zones-gcloud.md)
- [Aula 2 — IAM e Service Accounts](./semana-01-fundamentos-projetos-iam/aula-02-iam-service-accounts.md)

[README da Semana 1](./semana-01-fundamentos-projetos-iam/README.md)

---

# Semana 2 — Compute Engine

Objetivo:

> Criar, configurar, automatizar, escalar e diagnosticar workloads baseados em máquinas virtuais.

## Conteúdo

- Compute Engine;
- Machine Families;
- Machine Types;
- Custom Machine Types;
- VM lifecycle;
- stop;
- start;
- reset;
- Persistent Disks;
- Regional Persistent Disks;
- Snapshots;
- Snapshot Schedules;
- Images;
- Metadata;
- Startup Scripts;
- SSH;
- OS Login;
- VM Manager;
- Instance Templates;
- Managed Instance Groups;
- Regional MIGs;
- Autoscaling;
- Autohealing;
- Health Checks;
- Spot VMs.

## Aulas

- [Aula 1 — Compute Engine, Machine Types e VMs](./semana-02-compute-engine/aula-01-compute-engine-machine-types-vms.md)
- [Aula 2 — Persistent Disks, Snapshots e Images](./semana-02-compute-engine/aula-02-persistent-disks-snapshots-images.md)
- [Aula 3 — Metadata e Startup Scripts](./semana-02-compute-engine/aula-03-metadata-startup-scripts.md)
- [Aula 4 — Instance Templates e Managed Instance Groups](./semana-02-compute-engine/aula-04-instance-templates-managed-instance-groups.md)
- [Aula 5 — Autoscaling, Autohealing, Spot VMs e Troubleshooting](./semana-02-compute-engine/aula-05-autoscaling-autohealing-spot-troubleshooting.md)

[README da Semana 2](./semana-02-compute-engine/README.md)

---

# Semana 3 — VPC e Networking

Objetivo:

> Entender como recursos se comunicam dentro do Google Cloud, entre VPCs e com ambientes externos.

## Conteúdo

- VPC;
- Custom Mode;
- Auto Mode;
- Subnets;
- Regions;
- CIDR;
- RFC1918;
- IP interno;
- IP externo;
- IP estático;
- expansão de subnet;
- Firewall Rules;
- Routes;
- prioridades;
- Cloud NAT;
- Private Google Access;
- Cloud DNS;
- Load Balancing;
- Forwarding Rules;
- Target Proxies;
- URL Maps;
- Backend Services;
- Health Checks;
- Named Ports;
- Shared VPC;
- VPC Peering;
- Cloud VPN;
- HA VPN;
- Cloud Router;
- BGP;
- Cloud Interconnect;
- Dedicated Interconnect;
- Partner Interconnect;
- Network Service Tiers;
- Connectivity Tests;
- troubleshooting de rede.

## Aulas

- [Aula 1 — VPC, Subnets, CIDR e IPs](./semana-03-vpc-networking/aula-01-vpc-subnets-cidr-ips.md)
- [Aula 2 — Firewall Rules e Rotas](./semana-03-vpc-networking/aula-02-firewall-rules-e-rotas.md)
- [Aula 3 — Cloud NAT, Private Google Access e Cloud DNS](./semana-03-vpc-networking/aula-03-cloud-nat-private-google-access-cloud-dns.md)
- [Aula 4 — Load Balancing](./semana-03-vpc-networking/aula-04-load-balancing.md)
- [Aula 5 — Shared VPC, Peering, VPN, Interconnect e Troubleshooting](./semana-03-vpc-networking/aula-05-shared-vpc-peering-vpn-interconnect-troubleshooting.md)

[README da Semana 3](./semana-03-vpc-networking/README.md)

---

# Semana 4 — Storage e Databases

Objetivo:

> Selecionar, configurar e operar os principais serviços de armazenamento e bancos de dados cobrados no ACE.

## Conteúdo

### Cloud Storage

- Buckets;
- Objects;
- Locations;
- Storage Classes;
- Versioning;
- Lifecycle;
- Retention;
- IAM;
- Storage Transfer Service.

### Bancos

- Cloud SQL;
- PostgreSQL;
- MySQL;
- SQL Server;
- Users;
- Databases;
- Connections;
- Backups;
- Restore;
- HA;
- Read Replicas;
- AlloyDB;
- Spanner;
- Firestore;
- Bigtable.

### Analytics

- BigQuery;
- Datasets;
- Tables;
- Schema;
- Jobs;
- Queries;
- Dry Run;
- custo de consultas.

## Aulas

- [Aula 1 — Cloud Storage: Buckets, Objetos e Classes](./semana-04-storage-databases/aula-01-cloud-storage-buckets-objetos-classes.md)
- [Aula 2 — Lifecycle, Versioning, Retenção e Segurança](./semana-04-storage-databases/aula-02-storage-lifecycle-versioning-retencao-seguranca.md)
- [Aula 3 — Cloud SQL e AlloyDB](./semana-04-storage-databases/aula-03-cloud-sql-alloydb.md)
- [Aula 4 — Spanner, Firestore e Bigtable](./semana-04-storage-databases/aula-04-spanner-firestore-bigtable.md)
- [Aula 5 — BigQuery e Matriz de Escolha de Bancos](./semana-04-storage-databases/aula-05-bigquery-matriz-escolha-bancos.md)

[README da Semana 4](./semana-04-storage-databases/README.md)

---

# Semana 5 — Containers, Cloud Run e GKE

Objetivo:

> Empacotar, armazenar, executar e operar workloads containerizados no Google Cloud.

## Conteúdo

### Containers

- Docker;
- Images;
- Containers;
- Tags;
- Digests;
- Artifact Registry.

### Cloud Run

- Services;
- Revisions;
- Runtime Service Account;
- Environment Variables;
- Scaling;
- Min/Max Instances;
- IAM Invoker;
- Traffic Splitting;
- Jobs.

### Kubernetes e GKE

- Cluster;
- Nodes;
- Node Pools;
- Pods;
- Deployments;
- ReplicaSets;
- Services;
- Labels;
- Selectors;
- ConfigMaps;
- Secrets;
- StatefulSets;
- HPA;
- VPA;
- Cluster Autoscaling;
- Autopilot;
- Standard;
- Regional Clusters;
- Private Clusters;
- Artifact Registry + GKE;
- troubleshooting Kubernetes.

### Serverless Events

- Cloud Functions;
- Eventarc.

## Aulas

- [Aula 1 — Containers e Artifact Registry](./semana-05-containers-cloud-run-gke/aula-01-containers-artifact-registry.md)
- [Aula 2 — Cloud Run Services, Revisions e Scaling](./semana-05-containers-cloud-run-gke/aula-02-cloud-run-services-revisions-scaling.md)
- [Aula 3 — Cloud Run Jobs, IAM e Operação](./semana-05-containers-cloud-run-gke/aula-03-cloud-run-jobs-iam-operacao.md)
- [Aula 4 — Kubernetes e GKE: Pods, Deployments e Services](./semana-05-containers-cloud-run-gke/aula-04-kubernetes-gke-pods-deployments-services.md)
- [Aula 5 — GKE Autopilot, Standard, Autoscaling e Troubleshooting](./semana-05-containers-cloud-run-gke/aula-05-gke-autopilot-standard-autoscaling-troubleshooting.md)

[README da Semana 5](./semana-05-containers-cloud-run-gke/README.md)

---

# Semana 6 — Operations, Monitoring, Logging, Billing e Terraform

Objetivo:

> Operar recursos em produção, monitorar comportamento, investigar incidentes e automatizar infraestrutura.

## Conteúdo

### Cloud Monitoring

- Metrics;
- Time Series;
- Dashboards;
- Alert Policies;
- Notification Channels;
- Custom Metrics;
- Managed Service for Prometheus.

### Cloud Logging

- Logs Explorer;
- Structured Logs;
- Audit Logs;
- Log Router;
- Sinks;
- Log Buckets;
- Log Views;
- Log-based Metrics;
- Ops Agent.

### Operação

- Cloud diagnostics;
- Google Cloud Service Health;
- quotas;
- troubleshooting.

### Billing

- Billing Account;
- Budgets;
- Billing Export;
- Cost Management;
- Labels;
- FinOps básico.

### Infrastructure as Code

- Terraform;
- Provider Google;
- State;
- Plan;
- Apply;
- Destroy;
- Drift;
- Cloud Foundation Toolkit;
- Config Connector;
- Helm.

## Aulas

- [Aula 1 — Cloud Monitoring, Metrics, Dashboards e Alerts](./semana-06-operations-monitoring-logging-billing-terraform/aula-01-cloud-monitoring-metrics-dashboards-alerts.md)
- [Aula 2 — Cloud Logging e Troubleshooting](./semana-06-operations-monitoring-logging-billing-terraform/aula-02-cloud-logging-troubleshooting.md)
- [Aula 3 — Billing, Budgets, Quotas e FinOps](./semana-06-operations-monitoring-logging-billing-terraform/aula-03-billing-budgets-quotas-finops.md)
- [Aula 4 — Terraform no Google Cloud](./semana-06-operations-monitoring-logging-billing-terraform/aula-04-terraform-google-cloud.md)
- [Aula 5 — Operação Integrada e Revisão ACE](./semana-06-operations-monitoring-logging-billing-terraform/aula-05-operacao-integrada-revisao-ace.md)

[README da Semana 6](./semana-06-operations-monitoring-logging-billing-terraform/README.md)

---

# Semana 7 — Segurança e IAM Avançado

Objetivo:

> Configurar identidades e permissões com menor privilégio e diagnosticar problemas de acesso.

## Conteúdo

- Resource hierarchy;
- IAM inheritance;
- IAM Policy;
- Principals;
- Permissions;
- Basic Roles;
- Predefined Roles;
- Custom Roles;
- Least Privilege;
- Service Accounts;
- Service Account User;
- Service Account Token Creator;
- Impersonation;
- Short-lived credentials;
- IAM Conditions;
- Application Default Credentials;
- Workload Identity Federation;
- Policy Troubleshooter;
- runtime identity;
- troubleshooting de `401`;
- troubleshooting de `403`;
- Audit Logs para segurança.

## Aulas

- [Aula 1 — IAM Avançado, Herança e Roles](./semana-07-seguranca-iam-avancado-cenarios/aula-01-iam-avancado-heranca-roles.md)
- [Aula 2 — Service Accounts e Impersonation](./semana-07-seguranca-iam-avancado-cenarios/aula-02-service-accounts-impersonation.md)
- [Aula 3 — IAM Conditions, ADC e Workload Identity Federation](./semana-07-seguranca-iam-avancado-cenarios/aula-03-iam-conditions-adc-workload-identity.md)
- [Aula 4 — Segurança de Workloads e Troubleshooting de Acesso](./semana-07-seguranca-iam-avancado-cenarios/aula-04-seguranca-workloads-troubleshooting-acesso.md)
- [Aula 5 — Cenários Integrados e Questões ACE](./semana-07-seguranca-iam-avancado-cenarios/aula-05-cenarios-integrados-questoes-ace.md)

[README da Semana 7](./semana-07-seguranca-iam-avancado-cenarios/README.md)

---

# Semana 8 — Revisão, Simulados e Estratégia de Prova

Objetivo:

> Consolidar o conhecimento, identificar lacunas e treinar tomada de decisão em cenários semelhantes aos da prova.

## Conteúdo

- revisão por domínio;
- revisão de comandos;
- revisão de arquiteturas;
- questões baseadas em cenário;
- simulados;
- análise de erros;
- classificação de lacunas;
- estratégia de leitura;
- gestão do tempo;
- critérios de prontidão;
- checklist final.

## Aulas

- [Aula 1 — Revisão por Domínio Oficial](./semana-08-revisao-simulados-estrategia-prova/aula-01-revisao-por-dominio-oficial.md)
- [Aula 2 — Simulado 1](./semana-08-revisao-simulados-estrategia-prova/aula-02-simulado-01.md)
- [Aula 3 — Simulado 2](./semana-08-revisao-simulados-estrategia-prova/aula-03-simulado-02.md)
- [Aula 4 — Estratégia de Prova e Gestão do Tempo](./semana-08-revisao-simulados-estrategia-prova/aula-04-estrategia-prova-gestao-tempo.md)
- [Aula 5 — Checklist Final e Plano Pré-Prova](./semana-08-revisao-simulados-estrategia-prova/aula-05-checklist-final-plano-pre-prova.md)

[README da Semana 8](./semana-08-revisao-simulados-estrategia-prova/README.md)

---

# Ferramentas Utilizadas

Durante o roadmap serão utilizadas principalmente:

```text
Google Cloud Console
Cloud Shell
gcloud
gcloud storage
bq
Docker
kubectl
Terraform
SQL
bash
```

---

# Fluxo de Troubleshooting

Use como referência:

```text
Sintoma
   ↓
Recurso existe?
   ↓
Estado correto?
   ↓
Project / Region / Zone corretos?
   ↓
Identidade correta?
   ↓
IAM permite?
   ↓
Rede permite?
   ↓
Serviço está ouvindo?
   ↓
Quota / capacidade?
   ↓
Logs / Metrics
   ↓
Causa
   ↓
Correção mínima
```

Algumas associações úteis:

```text
401
→ autenticação / credencial

403
→ autorização / IAM

Timeout
→ rede / rota / firewall / DNS / serviço

RESOURCE_EXHAUSTED
→ quota / capacidade

ImagePullBackOff
→ image / tag / registry / credencial

CrashLoopBackOff
→ aplicação iniciando e falhando

Service sem endpoints
→ labels / selectors / readiness

Cloud SQL "database does not exist"
→ database configurado / nome usado na conexão
```

---

# Checklist de Preparação

## Fundamentos

- [ ] Projects
- [ ] Regions
- [ ] Zones
- [ ] gcloud configurations
- [ ] APIs
- [ ] Billing
- [ ] Quotas

## IAM

- [ ] Principals
- [ ] Permissions
- [ ] Basic Roles
- [ ] Predefined Roles
- [ ] Custom Roles
- [ ] Service Accounts
- [ ] Impersonation
- [ ] IAM Conditions
- [ ] ADC
- [ ] Workload Identity Federation

## Compute

- [ ] VMs
- [ ] Machine Types
- [ ] Disks
- [ ] Snapshots
- [ ] Images
- [ ] Startup Scripts
- [ ] OS Login
- [ ] MIG
- [ ] Autoscaling
- [ ] Autohealing

## Networking

- [ ] VPC
- [ ] Subnets
- [ ] CIDR
- [ ] Firewall
- [ ] Routes
- [ ] Cloud NAT
- [ ] Private Google Access
- [ ] Cloud DNS
- [ ] Load Balancing
- [ ] Shared VPC
- [ ] Peering
- [ ] VPN
- [ ] Interconnect
- [ ] Cloud Router
- [ ] BGP

## Storage e Databases

- [ ] Cloud Storage
- [ ] Lifecycle
- [ ] Versioning
- [ ] Retention
- [ ] Cloud SQL
- [ ] AlloyDB
- [ ] Spanner
- [ ] Firestore
- [ ] Bigtable
- [ ] BigQuery

## Containers

- [ ] Artifact Registry
- [ ] Cloud Run
- [ ] Cloud Run Jobs
- [ ] GKE
- [ ] Pods
- [ ] Deployments
- [ ] Services
- [ ] HPA
- [ ] VPA
- [ ] Autopilot
- [ ] Standard

## Operations

- [ ] Monitoring
- [ ] Logging
- [ ] Audit Logs
- [ ] Alerts
- [ ] Ops Agent
- [ ] Prometheus
- [ ] Billing
- [ ] Terraform

## Prova

- [ ] Simulado 1
- [ ] Simulado 2
- [ ] Análise dos erros
- [ ] Revisão de IAM
- [ ] Revisão de Networking
- [ ] Revisão de Compute
- [ ] Revisão de Operations
- [ ] Checklist final

---

# Referências Oficiais

Utilize este roadmap em conjunto com:

- Google Cloud Associate Cloud Engineer Certification;
- Exam Guide oficial;
- Google Cloud Documentation;
- Google Cloud Skills Boost;
- documentação oficial do `gcloud`;
- documentação oficial de cada serviço utilizado nos laboratórios.

---

# Objetivo Final

Ao concluir o roadmap, você deverá conseguir analisar um cenário e responder:

```text
Qual serviço utilizar?
   ↓
Qual escopo?
   ↓
Qual configuração?
   ↓
Qual identidade?
   ↓
Qual permissão?
   ↓
Como testar?
   ↓
Como operar?
   ↓
Como diagnosticar?
   ↓
Como corrigir?
```

Esse é o objetivo central deste roadmap de preparação para a certificação:

# Google Cloud Associate Cloud Engineer
