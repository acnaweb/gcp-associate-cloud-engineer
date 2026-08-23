# Aula 3 — Billing, Budgets, Quotas e FinOps Básico

## Objetivos

Ao final desta aula, você deverá:

- Entender Billing Account;
- Entender vínculo entre projeto e billing;
- Entender budgets;
- Entender alertas de orçamento;
- Entender quotas;
- Diferenciar budget de quota;
- Entender labels para organização.

---

# 1. Billing Account

Billing Account é a conta de faturamento.

```text
Billing Account
      │
      ├── Project A
      ├── Project B
      └── Project C
```

---

# 2. Project e Billing

Para consumir recursos pagos, um projeto normalmente precisa estar associado a uma Billing Account ativa.

---

# 3. Budget

Budget define um valor de referência para monitoramento de custo.

Exemplo:

```text
Monthly Budget = US$ 1,000
```

Alertas podem ser configurados para percentuais como:

```text
50%
90%
100%
```

---

# 4. Atenção: Budget não bloqueia gastos

Ponto importante:

> Um budget, por si só, não interrompe automaticamente o consumo quando o limite é atingido.

Ele serve principalmente para acompanhamento e alertas.

---

# 5. Budget Alert

Modelo:

```text
Spend
  ↓
50%
  ↓
Notification

90%
  ↓
Notification

100%
  ↓
Notification
```

---

# 6. Quota

Quota limita consumo técnico de recursos ou APIs.

Exemplos:

```text
vCPU quota
API requests
IP addresses
resources per region
```

---

# 7. Budget x Quota

```text
Budget
→ financial monitoring

Quota
→ technical usage limit
```

---

# 8. Exemplo

Uma equipe tenta criar mais 100 VMs e recebe erro.

Possível causa:

```text
CPU quota exceeded
```

Não necessariamente falta de budget.

---

# 9. Labels

Labels ajudam a organizar recursos.

Exemplo:

```text
environment=prod
team=data
cost-center=1234
application=orders
```

São úteis para:

- Inventário;
- Busca;
- Análise de custo;
- Governança.

---

# 10. FinOps básico

Perguntas que você deve saber fazer:

```text
Quem está gastando?
Em qual projeto?
Em qual serviço?
Qual ambiente?
Existe recurso ocioso?
Existe quota inadequada?
```

---

# 11. Comandos úteis

Ver projeto atual:

```bash
gcloud config get-value project
```

Ver quotas de Compute Engine por região:

```bash
gcloud compute regions describe southamerica-east1
```

---

# 12. Boas práticas

- Definir budgets;
- Criar alertas;
- Usar labels;
- Revisar recursos ociosos;
- Evitar overprovisioning;
- Revisar quotas antes de grandes deployments.

---

# 13. Questões Estilo ACE

## Questão 1

Você quer receber aviso quando o gasto mensal chegar a 90%.

**Resposta:** Budget Alert.

## Questão 2

Deployment falha porque limite de CPUs regionais foi atingido.

**Resposta:** Quota.

## Questão 3

Você quer identificar custos por equipe.

**Resposta:** Labels e organização adequada de projetos/faturamento.

---

# 14. Pegadinhas ACE

- Budget não é hard limit automático.
- Quota não representa valor financeiro.
- Quota pode ser regional ou global dependendo do recurso.
- Labels ajudam muito em FinOps, mas não substituem arquitetura de billing adequada.

---

# 15. Checklist

- [ ] Entendo Billing Account
- [ ] Entendo Budget
- [ ] Entendo Budget Alert
- [ ] Sei que budget não bloqueia gasto automaticamente
- [ ] Entendo quota
- [ ] Sei diferenciar budget e quota
- [ ] Entendo labels
