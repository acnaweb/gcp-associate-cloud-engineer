# Google Cloud Associate Cloud Engineer — Roadmap Prático 2026

Repositório completo de preparação prática para a certificação **Google Cloud Associate Cloud Engineer (ACE)**, estruturado em **8 semanas de estudo**, com foco em:

- conceitos essenciais;
- configuração real no Google Cloud;
- prática com `gcloud`;
- laboratórios executáveis;
- troubleshooting;
- falhas propositais;
- questões estilo prova;
- simulados;
- estratégia de exame.

A proposta deste repositório não é apenas estudar serviços do Google Cloud.

O objetivo é desenvolver o raciocínio esperado de um **Associate Cloud Engineer**:

```text
Entender
   ↓
Criar
   ↓
Configurar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar
   ↓
Diagnosticar
   ↓
Corrigir
   ↓
Operar
```

---

# Objetivo

Ao concluir este roadmap, você deverá ser capaz de:

- Configurar projetos e ambientes Google Cloud;
- Trabalhar com `gcloud` e Cloud Shell;
- Criar e operar máquinas virtuais;
- Configurar discos, snapshots e imagens;
- Criar VPCs, subnets, rotas e regras de firewall;
- Configurar Cloud NAT, Private Google Access e Cloud DNS;
- Criar Load Balancers com MIGs e Health Checks;
- Entender Shared VPC, VPC Peering, VPN e Interconnect;
- Trabalhar com Cloud Storage;
- Diferenciar os principais bancos gerenciados do Google Cloud;
- Implantar containers com Cloud Run e GKE;
- Utilizar Monitoring e Logging para operação;
- Trabalhar com billing, budgets e quotas;
- Criar infraestrutura com Terraform;
- Trabalhar com IAM, Service Accounts e impersonation;
- Diagnosticar problemas de acesso, rede, compute e aplicações;
- Resolver questões baseadas em cenários;
- Desenvolver estratégia para a prova ACE.

---

# Metodologia

Todas as aulas práticas seguem o mesmo padrão:

```text
Conceito
   ↓
Criar
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

A ideia é simples:

> Não basta saber o que um serviço faz. Você deve entender como ele se comporta, como configurá-lo e como diagnosticar quando algo dá errado.

---

# Estrutura do Repositório

```text
gcp-associate-cloud-engineer/
│
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
│   ├── aula-02-firewall-rules-e-rotas.md
│   ├── aula-03-cloud-nat-private-google-access-cloud-dns.md
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

## Semana 1 — Fundamentos, Projects e IAM

Foco:

- Resource hierarchy;
- Projects;
- Project ID e Project Number;
- Regions e Zones;
- `gcloud` e configurations;
- APIs e Services;
- IAM;
- Service Accounts;
- Roles;
- Least Privilege.

```text
gcloud configuration
      ↓
Project
      ↓
APIs
      ↓
IAM
      ↓
Service Account
```

[Ir para a Semana 1](./semana-01-fundamentos-projetos-iam/README.md)

---

## Semana 2 — Compute Engine

Foco:

- Compute Engine;
- Machine Types;
- VMs;
- Persistent Disks;
- Snapshots;
- Images;
- Metadata;
- Startup Scripts;
- Instance Templates;
- Managed Instance Groups;
- Autoscaling;
- Autohealing;
- Spot VMs;
- Troubleshooting.

```text
Instance Template
       ↓
Managed Instance Group
       ↓
VMs
       ↓
Autoscaling
+
Autohealing
```

[Ir para a Semana 2](./semana-02-compute-engine/README.md)

---

## Semana 3 — VPC e Networking

Foco:

- VPC;
- Subnets;
- CIDR;
- IP interno e externo;
- Firewall Rules;
- Routes;
- Cloud NAT;
- Private Google Access;
- Cloud DNS;
- Load Balancing;
- Health Checks;
- MIG;
- Shared VPC;
- VPC Peering;
- Cloud VPN;
- Cloud Router;
- BGP;
- Interconnect;
- Troubleshooting.

```text
VPC
= global

Subnet
= regional

VM
= zonal
```

```text
ROTA
= por onde o tráfego vai

FIREWALL
= se o tráfego pode passar
```

[Ir para a Semana 3](./semana-03-vpc-networking/README.md)

---

## Semana 4 — Storage e Databases

Foco:

- Cloud Storage;
- Buckets e Objects;
- Storage Classes;
- Lifecycle;
- Versioning;
- Retention;
- Cloud SQL;
- AlloyDB;
- Spanner;
- Firestore;
- Bigtable;
- BigQuery.

```text
Cloud SQL
→ banco relacional tradicional

AlloyDB
→ PostgreSQL compatível de alto desempenho

Spanner
→ relacional distribuído/global

Firestore
→ documentos

Bigtable
→ wide-column / alta escala

BigQuery
→ analytics / data warehouse
```

[Ir para a Semana 4](./semana-04-storage-databases/README.md)

---

## Semana 5 — Containers, Cloud Run e GKE

Foco:

- Containers;
- Docker;
- Artifact Registry;
- Cloud Run;
- Services;
- Revisions;
- Scaling;
- Cloud Run Jobs;
- Kubernetes;
- GKE;
- Pods;
- Deployments;
- Services;
- Autopilot;
- Standard;
- HPA;
- Troubleshooting.

```text
Container Image
      ↓
Artifact Registry
      ↓
Cloud Run
ou
GKE
```

[Ir para a Semana 5](./semana-05-containers-cloud-run-gke/README.md)

---

## Semana 6 — Operations, Monitoring, Logging, Billing e Terraform

Foco:

- Cloud Monitoring;
- Metrics;
- Dashboards;
- Alerts;
- Cloud Logging;
- Logs Explorer;
- Audit Logs;
- Troubleshooting;
- Billing;
- Budgets;
- Quotas;
- FinOps básico;
- Terraform;
- State;
- Drift.

```text
Métrica
   ↓
Monitoring
   ↓
Alert

Log
   ↓
Logging
   ↓
Troubleshooting
```

```text
Terraform
   ↓
plan
   ↓
apply
   ↓
Google Cloud
```

[Ir para a Semana 6](./semana-06-operations-monitoring-logging-billing-terraform/README.md)

---

## Semana 7 — Segurança e IAM Avançado

Foco:

- IAM inheritance;
- Predefined Roles;
- Custom Roles;
- Service Account User;
- Service Account Token Creator;
- Impersonation;
- IAM Conditions;
- ADC;
- Workload Identity Federation;
- Policy Troubleshooter;
- Segurança de workloads;
- Troubleshooting de acesso.

```text
Principal
   ↓
Role
   ↓
Permissions
   ↓
Resource
```

```text
Who?
What role?
Which resource?
Which scope?
Can I reduce privilege?
Can I avoid a long-lived key?
```

[Ir para a Semana 7](./semana-07-seguranca-iam-avancado-cenarios/README.md)

---

## Semana 8 — Revisão, Simulados e Estratégia de Prova

Foco:

- Revisão por domínio;
- Simulado 1;
- Simulado 2;
- Análise de erros;
- Estratégia de prova;
- Gestão do tempo;
- Checklist final;
- Plano pré-prova.

```text
Simulado
   ↓
Erro
   ↓
Classificação
   ↓
Revisão
   ↓
Laboratório
   ↓
Novo simulado
```

[Ir para a Semana 8](./semana-08-revisao-simulados-estrategia-prova/README.md)

---

# Checklist de Progresso

## Semana 1

- [ ] Projects
- [ ] Regions
- [ ] Zones
- [ ] gcloud
- [ ] Configurations
- [ ] APIs
- [ ] IAM
- [ ] Service Accounts

## Semana 2

- [ ] Compute Engine
- [ ] Machine Types
- [ ] Persistent Disks
- [ ] Snapshots
- [ ] Images
- [ ] Metadata
- [ ] Startup Scripts
- [ ] MIG
- [ ] Autoscaling
- [ ] Autohealing
- [ ] Spot VMs

## Semana 3

- [ ] VPC
- [ ] Subnets
- [ ] CIDR
- [ ] Firewall
- [ ] Routes
- [ ] Cloud NAT
- [ ] Private Google Access
- [ ] Cloud DNS
- [ ] Load Balancing
- [ ] Health Checks
- [ ] Shared VPC
- [ ] VPC Peering
- [ ] Cloud VPN
- [ ] Cloud Router
- [ ] BGP
- [ ] Interconnect

## Semana 4

- [ ] Cloud Storage
- [ ] Storage Classes
- [ ] Lifecycle
- [ ] Versioning
- [ ] Retention
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
- [ ] Revisions
- [ ] Scaling
- [ ] Cloud Run Jobs
- [ ] Kubernetes
- [ ] GKE
- [ ] Pods
- [ ] Deployments
- [ ] Services
- [ ] Autopilot
- [ ] Standard
- [ ] HPA

## Semana 6

- [ ] Monitoring
- [ ] Metrics
- [ ] Dashboards
- [ ] Alerts
- [ ] Logging
- [ ] Audit Logs
- [ ] Troubleshooting
- [ ] Billing
- [ ] Budgets
- [ ] Quotas
- [ ] Terraform
- [ ] State
- [ ] Drift

## Semana 7

- [ ] IAM inheritance
- [ ] Predefined Roles
- [ ] Custom Roles
- [ ] Service Account User
- [ ] Service Account Token Creator
- [ ] Impersonation
- [ ] IAM Conditions
- [ ] ADC
- [ ] Workload Identity Federation
- [ ] Policy Troubleshooter

## Semana 8

- [ ] Revisão final
- [ ] Simulado 1
- [ ] Simulado 2
- [ ] Análise de erros
- [ ] Estratégia de prova
- [ ] Gestão do tempo
- [ ] Checklist final

---

# Ferramentas Utilizadas

Durante os laboratórios, você trabalhará principalmente com:

```text
Google Cloud Console
Cloud Shell
gcloud
bq
gcloud storage
kubectl
Docker
Terraform
bash
```

---

# Comandos Essenciais

## gcloud

```bash
gcloud auth list
gcloud config list
gcloud config configurations list
gcloud projects list
gcloud services list --enabled
```

## Compute Engine

```bash
gcloud compute instances list
gcloud compute disks list
gcloud compute snapshots list
gcloud compute instance-templates list
gcloud compute instance-groups managed list
```

## Networking

```bash
gcloud compute networks list
gcloud compute networks subnets list
gcloud compute firewall-rules list
gcloud compute routes list
gcloud compute forwarding-rules list
gcloud compute backend-services list
gcloud compute health-checks list
```

## Storage

```bash
gcloud storage buckets list
gcloud storage ls
```

## IAM

```bash
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
gcloud iam roles describe ROLE
```

## Cloud Run

```bash
gcloud run services list
gcloud run jobs list
gcloud run revisions list
```

## GKE

```bash
gcloud container clusters list
kubectl get nodes
kubectl get pods
kubectl get deployments
kubectl get services
kubectl describe pod POD_NAME
kubectl logs POD_NAME
```

## Logging

```bash
gcloud logging read 'severity>=ERROR' --limit=20
```

## Terraform

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
terraform state list
terraform destroy
```

---

# Estratégia de Troubleshooting

Uma das habilidades mais importantes para o ACE é saber investigar problemas.

```text
Sintoma
   ↓
Recurso existe?
   ↓
Estado correto?
   ↓
Escopo correto?
   ↓
IAM?
   ↓
Rede?
   ↓
Quota?
   ↓
Aplicação?
   ↓
Logs / Metrics
   ↓
Correção
```

Regra importante:

> Não altere várias configurações ao mesmo tempo. Primeiro obtenha evidências.

---

# Folha Mental de Diagnóstico

```text
403
→ IAM / autorização

401
→ autenticação / credencial

Timeout
→ rota / firewall / DNS / serviço

RESOURCE_EXHAUSTED
→ quota / capacidade

500
→ aplicação / dependência

ImagePullBackOff
→ imagem / tag / credencial

CrashLoopBackOff
→ aplicação inicia e falha
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
Laboratório que preciso repetir:
```

Não faça simulados apenas para medir pontuação.

Use-os para identificar lacunas.

O objetivo não é decorar a resposta.

O objetivo é conseguir explicar:

```text
Por que a correta está correta?
+
Por que as demais estão erradas?
```

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
troubleshooting praticado
+
modelos mentais claros
```

Mais importante do que decorar comandos:

```text
saber decidir
```

---

# Estratégia de Estudo

```text
Conceito
   ↓
Laboratório
   ↓
Falha proposital
   ↓
Troubleshooting
   ↓
Questões
   ↓
Revisão
```

Ritmo sugerido:

```text
45–90 minutos por sessão
5–6 dias por semana
8 semanas
```

Uma aula só está concluída quando você consegue:

```text
1. explicar o recurso;
2. criar;
3. inspecionar;
4. testar;
5. quebrar;
6. diagnosticar;
7. corrigir;
8. remover.
```

---

# Regras de Ouro para o ACE

```text
VPC → global
Subnet → regional
VM → zonal
```

```text
Route → caminho
Firewall → permissão
```

```text
Cloud NAT → saída para internet sem IP externo
Private Google Access → acesso privado às APIs Google
```

```text
Health Check → saúde do backend
Autoscaling → capacidade
Autohealing → recuperação da instância
```

```text
Shared VPC → uma rede compartilhada entre projetos
VPC Peering → conecta VPCs diferentes
```

```text
Cloud VPN → IPsec pela internet
Interconnect → conectividade dedicada / via parceiro
```

```text
Cloud SQL → relacional tradicional
Spanner → relacional distribuído
BigQuery → analytics
```

```text
Cloud Run → serverless containers
GKE → Kubernetes
Compute Engine → controle de VM
```

```text
Budget → monitoramento financeiro
Quota → limite técnico
```

```text
Service Account → identidade de workload
Impersonation → credencial temporária
Long-lived key → evitar quando possível
```

---

# Critério de Escolha de Serviço

Durante a prova, pergunte:

```text
Qual é o requisito principal?
```

Depois:

```text
É compute?
É storage?
É banco?
É networking?
É container?
É IAM?
É observabilidade?
É operação?
```

E finalmente:

```text
Qual solução atende o requisito
com menor complexidade operacional,
menor privilégio
e configuração nativa do Google Cloud?
```

---

# Formato Mental da Prova

O ACE não exige apenas:

```text
"Você sabe o que é Cloud NAT?"
```

Ele tende a avaliar algo mais próximo de:

```text
Uma VM não possui IP externo.
Ela precisa baixar atualizações da internet.

Qual configuração deve ser utilizada?
```

Ou:

```text
Uma aplicação está recebendo HTTP 403.

Qual é a primeira configuração que você deve verificar?
```

Portanto:

```text
Decisão
>
Decoração
```

---

# Últimos 7 Dias

## Dia -7

Simulado completo.

## Dia -6

```text
IAM
+
Service Accounts
```

## Dia -5

```text
VPC
+
Firewall
+
Routes
+
NAT
+
Load Balancing
```

## Dia -4

```text
Compute Engine
+
MIG
+
Autoscaling
```

## Dia -3

```text
Storage
+
Databases
+
BigQuery
```

## Dia -2

```text
Cloud Run
+
GKE
+
Monitoring
+
Logging
```

Executar simulado final.

## Dia -1

Revisão leve.

Não tente aprender dezenas de serviços novos.

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

A sequência deve ser ajustada conforme seu objetivo profissional.

---

# Observação

Este material foi estruturado como uma trilha de preparação **prática**.

Ele não substitui:

- documentação oficial;
- exam guide oficial;
- Cloud Skills Boost;
- experiência real com Google Cloud.

Use o repositório como:

```text
Roadmap
+
Resumo
+
Laboratório
+
Troubleshooting
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
Qual escopo?
Como configurar?
Como proteger?
Como testar?
Como operar?
Como diagnosticar?
Como corrigir?
```

Esse é o raciocínio central esperado de um:

# Google Cloud Associate Cloud Engineer
