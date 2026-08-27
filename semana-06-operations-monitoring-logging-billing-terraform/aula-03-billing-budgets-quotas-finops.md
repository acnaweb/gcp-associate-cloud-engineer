# Aula 3 — Billing, Budgets, Quotas e FinOps Básico

## Objetivos

Ao final desta aula, você deverá:

- Entender billing account;
- Criar/inspecionar budget quando permitido;
- Diferenciar budget e quota;
- Usar labels para custo;

---

# 1. Modelo mental

```text
Billing Account
 └─ Project
    ├─ resources
    └─ labels

Budget → alerta
Quota  → limite técnico/consumo de recurso
```

O objetivo desta aula não é apenas reconhecer nomes de serviços. Você deve conseguir **criar, inspecionar, testar e explicar** o comportamento dos recursos.

---

# 2. Regra de estudo da aula

Use sempre este ciclo:

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
Diagnosticar
   ↓
Corrigir
   ↓
Remover
```

---

# 3. Laboratório principal

Inspecione billing:
```bash
gcloud billing accounts list
gcloud billing projects describe $(gcloud config get-value project)
```

Quotas:
```bash
gcloud compute project-info describe \
  --format="yaml(quotas)"
```

Crie recurso com labels:
```bash
gcloud compute instances create ace-finops-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --labels=environment=lab,owner=ace \
  --image-family=debian-12 --image-project=debian-cloud
```

Budget (se tiver permissão na Billing Account):
```bash
gcloud billing budgets list \
  --billing-account=BILLING_ACCOUNT_ID
```

No Console: Billing → Budgets & alerts → crie um budget pequeno de laboratório sem esperar que ele bloqueie gastos.

---

# 4. Testes e falhas propositais

- Budget alerta; não interrompe gasto automaticamente.
- Quota pode impedir criação mesmo com orçamento disponível.
- Labels ajudam alocação, mas não substituem estrutura de billing/projects.

Para cada falha, não corrija imediatamente. Primeiro registre:

```text
Sintoma:
Hipótese:
Comando/evidência:
Causa:
Correção:
```

---

# 5. Troubleshooting

Use este fluxo:

```text
1. O recurso existe e está no estado esperado?
2. O escopo (project/region/zone) está correto?
3. A identidade/principal está correta?
4. IAM permite a operação?
5. Rede/rota/firewall permitem comunicação, quando aplicável?
6. A aplicação/serviço está saudável?
7. Há quota/capacidade suficiente?
8. Logs e métricas confirmam a hipótese?
```

Comandos-base:

```bash
gcloud config list
gcloud auth list
gcloud projects describe $(gcloud config get-value project)
gcloud logging read 'severity>=ERROR' --limit=10
```

---

# 6. Pegadinhas ACE

- Budget ≠ quota.
- Billing account financia projetos vinculados.
- Cost controls combinam budgets, labels, rightsizing, schedules e arquitetura.

---

# 7. Questões estilo ACE

- Quer avisar ao atingir 80% do gasto? → budget alert.
- Erro RESOURCE_EXHAUSTED ao criar CPU? → quota.

---

# 8. Checklist

- [ ] Consigo explicar o modelo mental da aula;
- [ ] Executei o laboratório;
- [ ] Inspecionei os recursos com `describe/list`;
- [ ] Provoquei ao menos uma falha;
- [ ] Diagnostiquei antes de corrigir;
- [ ] Consigo justificar a escolha do serviço;
- [ ] Consigo explicar as pegadinhas ACE;
- [ ] Fiz o cleanup.

---

# 9. O que memorizar

Não memorize apenas comandos. Memorize a relação:

```text
Requisito
   ↓
Serviço/recurso correto
   ↓
Escopo correto
   ↓
Permissão correta
   ↓
Operação correta
   ↓
Troubleshooting com evidência
```

Essa é a forma de raciocínio mais útil para o Associate Cloud Engineer.

