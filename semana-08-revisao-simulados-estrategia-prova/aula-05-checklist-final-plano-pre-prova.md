# Aula 5 — Checklist Final e Plano Pré-Prova

## Objetivos

Ao final desta aula, você deverá:

- Fazer revisão final;
- Saber se está pronto;
- Organizar os últimos dias;
- Evitar estudo desorganizado na véspera.

---

# 1. Checklist Técnico Final

## Fundamentos

- [ ] Organization
- [ ] Folder
- [ ] Project
- [ ] Billing
- [ ] APIs
- [ ] Regions
- [ ] Zones
- [ ] `gcloud`

## IAM

- [ ] Principal
- [ ] Role
- [ ] Permission
- [ ] Resource
- [ ] Inheritance
- [ ] Service Account
- [ ] Impersonation
- [ ] IAM Conditions
- [ ] Least privilege

## Compute

- [ ] Compute Engine
- [ ] Machine Types
- [ ] Persistent Disks
- [ ] Snapshots
- [ ] Images
- [ ] Templates
- [ ] MIG
- [ ] Autoscaling
- [ ] Autohealing
- [ ] Spot

## Networking

- [ ] VPC global
- [ ] Subnet regional
- [ ] CIDR
- [ ] Firewall
- [ ] Routes
- [ ] Cloud NAT
- [ ] Private Google Access
- [ ] Load Balancer
- [ ] Shared VPC
- [ ] Peering
- [ ] VPN
- [ ] Interconnect

## Storage

- [ ] Standard
- [ ] Nearline
- [ ] Coldline
- [ ] Archive
- [ ] Lifecycle
- [ ] Versioning
- [ ] Retention
- [ ] Signed URL

## Databases

- [ ] Cloud SQL
- [ ] AlloyDB
- [ ] Spanner
- [ ] Firestore
- [ ] Bigtable
- [ ] BigQuery

## Containers

- [ ] Artifact Registry
- [ ] Cloud Run
- [ ] Revisions
- [ ] Jobs
- [ ] GKE
- [ ] Pod
- [ ] Deployment
- [ ] Service
- [ ] Autopilot
- [ ] Standard
- [ ] HPA
- [ ] Cluster Autoscaler

## Operations

- [ ] Monitoring
- [ ] Logging
- [ ] Metrics
- [ ] Alerts
- [ ] Uptime Checks
- [ ] Billing
- [ ] Budget
- [ ] Quota
- [ ] Terraform

---

# 2. Teste de Prontidão

Você está próximo de estar pronto quando:

```text
≥ 80% nos simulados
+
erros compreendidos
+
labs básicos executados
+
modelos mentais claros
```

Mais importante que decorar:

```text
saber decidir
```

---

# 3. Últimos 7 dias

## Dia -7

Simulado completo.

## Dia -6

Revisar IAM e Networking.

## Dia -5

Revisar Compute e Storage.

## Dia -4

Revisar Databases e Containers.

## Dia -3

Revisar Operations, Billing e Terraform.

## Dia -2

Simulado final + análise dos erros.

## Dia -1

Revisão leve.

Não tente aprender dezenas de serviços novos.

---

# 4. Véspera

Faça apenas:

```text
IAM
VPC
Compute
Storage
Databases
Cloud Run/GKE
Monitoring
```

em revisão visual.

---

# 5. Folha Mental

Memorize:

```text
VPC → Global
Subnet → Regional
VM → Zonal
```

```text
HPA → Pods
Cluster Autoscaler → Nodes
```

```text
Autoscaling → Capacity
Autohealing → Health
```

```text
Budget → Money monitoring
Quota → Technical limit
```

```text
Snapshot → Backup
Image → VM template/base
```

```text
Cloud NAT → Outbound internet for private VM
```

```text
Cloud SQL → Traditional relational
Spanner → Distributed relational
BigQuery → Analytics
```

```text
Cloud Run → Serverless containers
GKE → Kubernetes
Compute Engine → VM control
```

---

# 6. Segurança Mental

Em questões de IAM:

```text
Who?
What role?
Which resource?
Which scope?
Can I reduce privilege?
Can I avoid long-lived key?
```

---

# 7. Diagnóstico Mental

```text
403
→ IAM/Auth

Timeout
→ Network/Firewall/DNS

Quota exceeded
→ Quota

500
→ Application/Dependency

High latency
→ Monitoring + Logs
```

---

# 8. Objetivo Final

Não tente decorar o Google Cloud inteiro.

O ACE avalia sua capacidade de:

```text
Configure
Deploy
Operate
Secure
Troubleshoot
```

---

# 9. Próximo passo após aprovação

Uma sequência natural de certificação pode ser:

```text
Associate Cloud Engineer
        ↓
Professional Data Engineer
        ↓
Professional Cloud Architect
```

ou ajustar conforme foco profissional.

---

# 10. Checklist Final

- [ ] Fiz simulados
- [ ] Analisei erros
- [ ] Executei labs
- [ ] Revisei IAM
- [ ] Revisei Networking
- [ ] Revisei Compute
- [ ] Revisei Storage
- [ ] Revisei Databases
- [ ] Revisei Containers
- [ ] Revisei Operations
- [ ] Estou confortável com `gcloud`
- [ ] Estou confortável com cenários
