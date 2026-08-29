# Aula 3 — Billing, Budgets, Quotas e FinOps

## Objetivos

Ao final, você deverá:
- identificar billing account vinculada;
- entender budget x quota;
- inspecionar quotas;
- criar recurso com labels;
- diagnosticar cenário de quota sem confundir com budget.


---

# 1. Conceito

Billing account paga pelo consumo dos projetos vinculados. Budget gera acompanhamento/alertas; quota limita uso técnico de determinados recursos. Labels ajudam classificação de custos.

## Arquitetura mental

```text
Billing Account → Project → Resources
Budget → alerta financeiro
Quota → limite técnico
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)

gcloud billing accounts list
gcloud billing projects describe "$PROJECT_ID"

gcloud compute instances create ace-finops-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --labels=environment=lab,cost-center=ace \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud compute instances describe ace-finops-vm \
  --zone=us-central1-a \
  --format="yaml(labels)"

gcloud compute project-info describe \
  --format="yaml(quotas)"
```

---

# 4. Testar

No Console, Billing → Budgets & alerts:
- identifique/crie budget se sua permissão permitir;
- observe thresholds;
- confirme que budget não é quota.

Depois consulte quotas de CPUs/região.

---

# 5. Quebrar propositalmente

Falha de decisão:

> “O budget chegou a 100%, então novas VMs serão automaticamente bloqueadas.”

Marque como hipótese e valide pelos conceitos observados.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** expectativa de bloqueio automático por budget.

**Evidência:** budget é mecanismo de acompanhamento/alertas, enquanto `gcloud compute project-info describe` mostra quotas técnicas.

**Causa:** confusão entre duas funções diferentes.

**Correção mental:**
```text
Budget → custo/alerta
Quota  → limite de recurso/API
```

Use sempre:

```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```

---

# 7. Corrigir

Atualize sua folha de decisão e, se quiser testar quota real, faça isso apenas em projeto controlado; não tente consumir recursos de propósito até estourar limite.

---

# 8. Questões estilo ACE

1. Quer alerta em 80% do gasto? **Budget**.
2. `RESOURCE_EXHAUSTED` ao criar recurso? Investigue **quota/capacidade**.
3. Budget bloqueia gasto automaticamente por padrão? **Não**.

---

# 9. Cleanup

```bash
gcloud compute instances delete ace-finops-vm \
  --zone=us-central1-a --quiet
```

---

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.
