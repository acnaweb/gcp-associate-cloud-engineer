# Aula 5 — Operação Integrada e Revisão ACE

## Objetivos

Ao final desta aula, você deverá:

- Integrar Monitoring, Logging, Billing e Terraform;
- Resolver cenários de operação;
- Revisar decisões típicas do ACE;
- Trabalhar com diagnóstico orientado por sintomas.

---

# 1. Operação não é só deployment

Uma solução em produção precisa de:

```text
Provision
   ↓
Monitor
   ↓
Detect
   ↓
Troubleshoot
   ↓
Recover
   ↓
Optimize
```

---

# 2. Arquitetura operacional

```text
Application
   │
   ├── Metrics → Monitoring
   ├── Logs    → Logging
   ├── Cost    → Billing
   └── IaC     → Terraform
```

---

# 3. Cenário 1 — API lenta

Sintoma:

```text
Latency increased
```

Fluxo:

```text
Monitoring
   ↓
Check latency metric
   ↓
CPU / memory / request count
   ↓
Logging
   ↓
Backend dependency
   ↓
Root cause
```

---

# 4. Cenário 2 — VM não cria

Erro:

```text
Quota exceeded
```

Resposta:

```text
Check regional quota
↓
Request increase or reduce demand
```

Não confunda com budget.

---

# 5. Cenário 3 — custo disparou

Fluxo:

```text
Billing reports
   ↓
Project/service
   ↓
Labels
   ↓
Identify resource
   ↓
Resize/delete/optimize
```

---

# 6. Cenário 4 — endpoint fora do ar

```text
Uptime Check
    ↓
Alert
    ↓
Incident
    ↓
Logs
    ↓
Fix
```

---

# 7. Cenário 5 — mudança precisa ser reproduzível

```text
Manual configuration
      ↓
Risk
```

Melhor:

```text
Terraform
   ↓
Git
   ↓
Review
   ↓
Apply
```

---

# 8. Método ACE para troubleshooting

Use esta ordem mental:

```text
1. Scope
   What resource/project/region?

2. State
   Is resource running?

3. Monitoring
   What metric changed?

4. Logging
   What error happened?

5. Network
   Route/firewall/DNS/NAT?

6. IAM
   Permission denied?

7. Quota
   Limit reached?

8. Change
   What changed recently?
```

---

# 9. Monitorar x Alertar

```text
Monitor
→ observe

Alert
→ notify when condition happens
```

---

# 10. Budget x Quota

```text
Budget → dinheiro
Quota  → capacidade técnica
```

---

# 11. Logging x Monitoring

```text
Logging
→ detailed events

Monitoring
→ aggregated behavior
```

---

# 12. Terraform x gcloud

```text
gcloud
→ operational command
→ imperative

Terraform
→ desired infrastructure
→ declarative
```

---

# 13. Questões Estilo ACE

## Questão 1

API está indisponível e você quer aviso automático.

**Resposta:** uptime check + alerting policy.

## Questão 2

Você recebeu "permission denied".

**Resposta:** revisar IAM, principal e role.

## Questão 3

Você recebeu "quota exceeded".

**Resposta:** revisar quota apropriada.

## Questão 4

Precisa reproduzir a mesma VPC em vários ambientes.

**Resposta:** Terraform/IaC.

## Questão 5

Quer saber exatamente qual erro ocorreu às 14:31.

**Resposta:** Cloud Logging.

---

# 14. Revisão Visual

```text
OPERATIONS
│
├── Monitoring
│   ├── Metrics
│   ├── Dashboards
│   ├── Alerts
│   └── Uptime Checks
│
├── Logging
│   ├── Logs Explorer
│   ├── Severity
│   └── Log-based Metrics
│
├── Billing
│   ├── Budgets
│   ├── Alerts
│   ├── Quotas
│   └── Labels
│
└── Terraform
    ├── init
    ├── plan
    ├── apply
    └── destroy
```

---

# 15. Checklist Final

- [ ] Sei identificar métrica adequada
- [ ] Sei identificar log adequado
- [ ] Sei criar raciocínio de alerting
- [ ] Entendo uptime checks
- [ ] Sei investigar erros
- [ ] Sei diferenciar budget e quota
- [ ] Entendo FinOps básico
- [ ] Entendo Terraform
- [ ] Consigo combinar ferramentas na operação
