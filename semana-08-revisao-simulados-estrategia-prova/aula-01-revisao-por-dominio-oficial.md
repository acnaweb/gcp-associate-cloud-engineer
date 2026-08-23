# Aula 1 — Revisão por Domínio Oficial

## Objetivos

Ao final desta aula, você deverá:

- Revisar os quatro domínios oficiais do ACE;
- Identificar pontos fracos;
- Reforçar os modelos mentais mais importantes;
- Consolidar decisões entre serviços.

---

# 1. Domínios oficiais

O exame ACE avalia quatro grandes capacidades:

```text
1. Configurar um ambiente de solução de nuvem
2. Planejar e implementar uma solução de nuvem
3. Garantir a operação de uma solução de nuvem
4. Configurar o acesso e a segurança
```

---

# 2. Configurar um ambiente de solução de nuvem

Revise:

```text
Organization
Folder
Project
Billing
IAM
APIs
gcloud
Regions
Zones
```

Perguntas que você precisa responder:

- Qual projeto está ativo?
- Qual região/zone está configurada?
- A API necessária está habilitada?
- A Billing Account está associada?
- O principal correto recebeu a role correta?

---

# 3. Planejar e implementar uma solução

Revise:

```text
Compute Engine
Cloud Run
GKE
Cloud Storage
Cloud SQL
AlloyDB
Spanner
Firestore
Bigtable
BigQuery
VPC
Load Balancing
```

---

# 4. Modelo de decisão de compute

```text
Precisa controlar SO?
  → Compute Engine

Precisa Kubernetes?
  → GKE

Container stateless sem cluster?
  → Cloud Run
```

---

# 5. Modelo de decisão de banco

```text
Relacional tradicional
  → Cloud SQL

PostgreSQL enterprise/performance
  → AlloyDB

SQL distribuído/global
  → Spanner

Documentos
  → Firestore

Wide-column/time series
  → Bigtable

Analytics
  → BigQuery
```

---

# 6. Modelo de decisão de Storage

```text
Acesso frequente
  → Standard

Mensal
  → Nearline

Trimestral
  → Coldline

Muito raro
  → Archive
```

---

# 7. Operação

Revise:

```text
Monitoring
Logging
Alerting
Uptime Checks
Quotas
Billing
Troubleshooting
Terraform
```

---

# 8. Segurança

Revise:

```text
Principal
Role
Resource
Condition
Service Account
Impersonation
Least Privilege
Workload Identity
Audit Logs
```

---

# 9. Networking

Memorize:

```text
VPC     → Global
Subnet  → Regional
VM      → Zonal
```

E diferencie:

```text
Route
  → para onde o tráfego vai

Firewall
  → se o tráfego é permitido
```

---

# 10. Alta disponibilidade

Compute:

```text
Load Balancer
      +
Regional MIG
      +
Health Checks
      +
Autoscaling
```

Database:

```text
HA configuration
Backups
Read replicas where appropriate
```

---

# 11. Identidade

Regra de ouro:

```text
Managed identity
+
Least privilege
+
Specific scope
+
Short-lived credentials
```

---

# 12. Checklist da Revisão

- [ ] Organization/Folder/Project
- [ ] Regions/Zones
- [ ] IAM
- [ ] Compute Engine
- [ ] VPC
- [ ] Cloud Storage
- [ ] Databases
- [ ] Cloud Run
- [ ] GKE
- [ ] Monitoring/Logging
- [ ] Billing/Quotas
- [ ] Terraform
