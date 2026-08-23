# Google Cloud Associate Cloud Engineer — Plano de Preparação

Repositório de estudos para preparação para a certificação **Google Cloud Associate Cloud Engineer (ACE)**.

O conteúdo está organizado em **8 semanas**, com teoria, diagramas, laboratórios, comandos `gcloud`, exercícios, questões estilo prova e checklists de revisão.

---

## Objetivo

Preparar de forma prática e estruturada para o exame Associate Cloud Engineer, desenvolvendo capacidade de:

- Configurar ambientes no Google Cloud;
- Implantar soluções;
- Operar workloads;
- Trabalhar com identidade e segurança;
- Diagnosticar problemas;
- Escolher serviços adequados para diferentes requisitos.

---

## Estrutura do Repositório

```text
google-cloud-ace/
├── README.md
│
├── semana-01-fundamentos-projetos-iam/
│   ├── README.md
│   ├── aula-01-hierarquia-projects-regions-zones-gcloud.md
│   └── aula-02-iam-service-accounts.md
│
├── semana-02-compute-engine/
│   ├── README.md
│   ├── aula-01-compute-engine-machine-types-vms.md
│   ├── aula-02-persistent-disks-snapshots-images.md
│   ├── aula-03-metadata-startup-scripts.md
│   ├── aula-04-instance-templates-managed-instance-groups.md
│   └── aula-05-autoscaling-autohealing-spot-troubleshooting.md
│
├── semana-03-vpc-networking/
│   ├── README.md
│   ├── aula-01-vpc-subnets-cidr-ips.md
│   ├── aula-02-firewall-rules-rotas.md
│   ├── aula-03-cloud-nat-private-google-access-dns.md
│   ├── aula-04-load-balancing.md
│   └── aula-05-shared-vpc-peering-vpn-interconnect-troubleshooting.md
│
├── semana-04-storage-databases/
│   ├── README.md
│   ├── aula-01-cloud-storage-buckets-objetos-classes.md
│   ├── aula-02-storage-lifecycle-versioning-retencao-seguranca.md
│   ├── aula-03-cloud-sql-alloydb.md
│   ├── aula-04-spanner-firestore-bigtable.md
│   └── aula-05-bigquery-matriz-escolha-bancos.md
│
├── semana-05-containers-cloud-run-gke/
│   ├── README.md
│   ├── aula-01-containers-artifact-registry.md
│   ├── aula-02-cloud-run-services-revisions-scaling.md
│   ├── aula-03-cloud-run-jobs-iam-operacao.md
│   ├── aula-04-kubernetes-gke-pods-deployments-services.md
│   └── aula-05-gke-autopilot-standard-autoscaling-troubleshooting.md
│
├── semana-06-operations-monitoring-logging-billing-terraform/
│   ├── README.md
│   ├── aula-01-cloud-monitoring-metrics-dashboards-alerts.md
│   ├── aula-02-cloud-logging-troubleshooting.md
│   ├── aula-03-billing-budgets-quotas-finops.md
│   ├── aula-04-terraform-google-cloud.md
│   └── aula-05-operacao-integrada-revisao-ace.md
│
├── semana-07-seguranca-iam-avancado-cenarios/
│   ├── README.md
│   ├── aula-01-iam-avancado-heranca-roles.md
│   ├── aula-02-service-accounts-impersonation.md
│   ├── aula-03-iam-conditions-adc-workload-identity.md
│   ├── aula-04-seguranca-workloads-troubleshooting-acesso.md
│   └── aula-05-cenarios-integrados-questoes-ace.md
│
└── semana-08-revisao-simulados-estrategia-prova/
    ├── README.md
    ├── aula-01-revisao-por-dominio-oficial.md
    ├── aula-02-simulado-01.md
    ├── aula-03-simulado-02.md
    ├── aula-04-estrategia-prova-gestao-tempo.md
    └── aula-05-checklist-final-plano-pre-prova.md
```

---

# Roadmap de 8 Semanas

## Semana 1 — Fundamentos, Projetos e IAM

Foco:

- Organization, Folder, Project e Resource;
- Regions e Zones;
- APIs;
- Cloud Shell;
- `gcloud`;
- IAM;
- Service Accounts;
- Least Privilege.

[Ir para a Semana 1](./semana-01-fundamentos-projetos-iam/README.md)

---

## Semana 2 — Compute Engine

Foco:

- VMs;
- Machine Types;
- Persistent Disks;
- Snapshots;
- Images;
- Startup Scripts;
- Instance Templates;
- Managed Instance Groups;
- Autoscaling;
- Autohealing;
- Spot VMs.

[Ir para a Semana 2](./semana-02-compute-engine/README.md)

---

## Semana 3 — VPC e Networking

Foco:

- VPC;
- Subnets;
- CIDR;
- IPs;
- Firewall Rules;
- Routes;
- Cloud NAT;
- Private Google Access;
- Cloud DNS;
- Load Balancing;
- Shared VPC;
- Peering;
- VPN;
- Interconnect.

[Ir para a Semana 3](./semana-03-vpc-networking/README.md)

---

## Semana 4 — Storage e Bancos de Dados

Foco:

- Cloud Storage;
- Classes de armazenamento;
- Lifecycle;
- Versioning;
- Retention;
- Signed URLs;
- Cloud SQL;
- AlloyDB;
- Spanner;
- Firestore;
- Bigtable;
- BigQuery.

[Ir para a Semana 4](./semana-04-storage-databases/README.md)

---

## Semana 5 — Containers, Cloud Run e GKE

Foco:

- Containers;
- Artifact Registry;
- Cloud Run;
- Revisions;
- Traffic Splitting;
- Cloud Run Jobs;
- Kubernetes;
- GKE;
- Pods;
- Deployments;
- Services;
- Autopilot;
- Standard;
- Autoscaling.

[Ir para a Semana 5](./semana-05-containers-cloud-run-gke/README.md)

---

## Semana 6 — Operations, Monitoring, Logging, Billing e Terraform

Foco:

- Cloud Monitoring;
- Metrics;
- Dashboards;
- Alerts;
- Uptime Checks;
- Cloud Logging;
- Troubleshooting;
- Billing;
- Budgets;
- Quotas;
- FinOps básico;
- Terraform.

[Ir para a Semana 6](./semana-06-operations-monitoring-logging-billing-terraform/README.md)

---

## Semana 7 — Segurança, IAM Avançado e Cenários

Foco:

- Herança de IAM;
- Predefined e Custom Roles;
- Service Account User;
- Service Account Token Creator;
- Impersonation;
- IAM Conditions;
- ADC;
- Workload Identity Federation;
- Troubleshooting de acesso;
- Cenários integrados.

[Ir para a Semana 7](./semana-07-seguranca-iam-avancado-cenarios/README.md)

---

## Semana 8 — Revisão, Simulados e Estratégia de Prova

Foco:

- Revisão por domínio;
- Simulados;
- Gestão do tempo;
- Estratégia de prova;
- Checklist final;
- Plano pré-prova.

[Ir para a Semana 8](./semana-08-revisao-simulados-estrategia-prova/README.md)

---

# Formato de Estudo Recomendado

Sugestão diária:

```text
20 min → teoria
25 min → laboratório
10 min → comandos gcloud/kubectl/terraform
 5 min → revisão e anotações
```

Ritmo recomendado:

```text
5 a 6 dias por semana
≈ 1 hora por dia
8 semanas
```

---

# Modelo Mental Principal do ACE

O exame exige principalmente capacidade de:

```text
Configure
   ↓
Deploy
   ↓
Operate
   ↓
Secure
   ↓
Troubleshoot
```

Mais importante do que decorar serviços:

> Saber escolher a solução adequada com base nos requisitos.

---

# Regras de Ouro

## Compute

```text
Precisa controlar SO?
→ Compute Engine

Precisa Kubernetes?
→ GKE

Container serverless?
→ Cloud Run
```

## Networking

```text
VPC    → Global
Subnet → Regional
VM     → Zonal
```

## Storage

```text
Standard → frequente
Nearline → aproximadamente mensal
Coldline → aproximadamente trimestral
Archive  → muito raro
```

## Bancos

```text
Cloud SQL → relacional tradicional
AlloyDB   → PostgreSQL enterprise/performance
Spanner   → SQL distribuído/global
Firestore → documentos
Bigtable  → wide-column / time series
BigQuery  → analytics
```

## Kubernetes

```text
HPA                → Pods
Cluster Autoscaler → Nodes
```

## Compute Engine

```text
Autoscaling → capacidade
Autohealing → saúde
Snapshot    → backup
Image       → base para VMs
```

## Operations

```text
Monitoring → métricas
Logging    → eventos
Budget     → monitoramento financeiro
Quota      → limite técnico
```

## Segurança

```text
Principal + Role + Resource
```

Sempre prefira:

```text
Least Privilege
+
Managed Identity
+
Specific Scope
+
Short-lived Credentials
```

---

# Checklist Geral de Progresso

## Semana 1

- [ ] Fundamentos GCP
- [ ] Hierarquia
- [ ] Regions/Zones
- [ ] IAM
- [ ] Service Accounts

## Semana 2

- [ ] Compute Engine
- [ ] Disks
- [ ] Snapshots
- [ ] Images
- [ ] MIG
- [ ] Autoscaling
- [ ] Autohealing

## Semana 3

- [ ] VPC
- [ ] Subnets
- [ ] Firewall
- [ ] Routes
- [ ] NAT
- [ ] Load Balancing
- [ ] VPN/Interconnect

## Semana 4

- [ ] Cloud Storage
- [ ] Lifecycle
- [ ] Cloud SQL
- [ ] AlloyDB
- [ ] Spanner
- [ ] Firestore
- [ ] Bigtable
- [ ] BigQuery

## Semana 5

- [ ] Containers
- [ ] Artifact Registry
- [ ] Cloud Run
- [ ] Cloud Run Jobs
- [ ] GKE
- [ ] Kubernetes
- [ ] Autoscaling

## Semana 6

- [ ] Monitoring
- [ ] Logging
- [ ] Troubleshooting
- [ ] Billing
- [ ] Budgets
- [ ] Quotas
- [ ] Terraform

## Semana 7

- [ ] IAM avançado
- [ ] Impersonation
- [ ] IAM Conditions
- [ ] ADC
- [ ] Federation
- [ ] Segurança de workloads

## Semana 8

- [ ] Revisão final
- [ ] Simulado 1
- [ ] Simulado 2
- [ ] Estratégia de prova
- [ ] Checklist final

---

# Ferramentas Utilizadas

Durante os laboratórios, você trabalhará principalmente com:

```text
gcloud
kubectl
terraform
bash
Cloud Shell
Google Cloud Console
```

---

# Comandos Essenciais

## gcloud

```bash
gcloud auth list
gcloud config list
gcloud projects list
gcloud services list
gcloud compute instances list
gcloud compute networks list
gcloud iam service-accounts list
```

## kubectl

```bash
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

## Terraform

```bash
terraform init
terraform plan
terraform apply
terraform destroy
```

---

# Estratégia para Simulados

Para cada erro, registre:

```text
Questão:
Resposta marcada:
Resposta correta:
Tema:
Motivo do erro:
Regra correta:
```

Não faça simulados apenas para medir pontuação.

Use-os para identificar lacunas.

---

# Critério de Prontidão

Uma boa referência antes da prova:

```text
≥ 80% nos simulados
+
erros compreendidos
+
labs executados
+
modelos mentais claros
```

---

# Formato do Exame

O exame Associate Cloud Engineer normalmente envolve:

- Aproximadamente 50–60 questões;
- 2 horas;
- Múltipla escolha;
- Múltipla seleção;
- Cenários práticos;
- Forte foco em operação e configuração.

Consulte sempre a página oficial da certificação antes de agendar, pois detalhes podem mudar.

---

# Próximos Passos após o ACE

Uma possível evolução:

```text
Associate Cloud Engineer
        ↓
Professional Data Engineer
        ↓
Professional Cloud Architect
        ↓
Professional Machine Learning Engineer
```

A sequência pode ser ajustada conforme seu foco profissional.

---

# Observação

Este material foi estruturado como trilha de preparação prática. Ele não substitui a documentação oficial, os labs oficiais nem o exam guide do Google Cloud.

Use o repositório como:

```text
Guia
+
Resumo
+
Laboratório
+
Revisão
+
Simulado
```

---

# Meta Final

Ao concluir as 8 semanas, você deverá conseguir olhar para um requisito e responder:

```text
Qual serviço?
Por quê?
Como configurar?
Como proteger?
Como operar?
Como diagnosticar?
```

Esse é o raciocínio central esperado de um **Google Cloud Associate Cloud Engineer**.
