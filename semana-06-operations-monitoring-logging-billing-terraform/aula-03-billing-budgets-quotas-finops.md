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
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)

# Explicação: Lista contas de faturamento acessíveis à identidade atual.
gcloud billing accounts list
# Explicação: Mostra a associação de faturamento do projeto para verificar se há Billing Account vinculada.
gcloud billing projects describe "$PROJECT_ID"

# Explicação: Cria uma VM do Compute Engine com as opções de máquina, rede, disco e identidade informadas.
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
# Explicação: Exibe a configuração e o estado detalhado da VM para inspeção/troubleshooting.
gcloud compute instances describe ace-finops-vm \
  --zone=us-central1-a \
  --format="yaml(labels)"

# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
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
# Explicação: Exclui a VM indicada e libera os recursos associados que não foram preservados.
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

---

# Cobertura adicional — Billing Accounts, vínculo de projetos e Billing Export

O exam guide inclui:

- criar/administrar billing accounts (quando você possui permissão); 
- vincular projeto à billing account;
- budgets/alerts;
- billing export.

Inspecione:

```bash
# Explicação: Lista contas de faturamento acessíveis à identidade atual.
gcloud billing accounts list
# Explicação: Mostra a associação de faturamento do projeto para verificar se há Billing Account vinculada.
gcloud billing projects describe "$(gcloud config get-value project)"
```

Em ambientes com permissão adequada, o vínculo de billing é administrado pelo Console/CLI apropriado. Não faça isso em projeto corporativo sem autorização.

## Billing Export

No Console:

```text
Billing → Billing export → BigQuery export
```

Modelo mental:

```text
Billing Export → dados detalhados de custo em BigQuery
Budget         → thresholds/alertas
Quota          → limite técnico
Pricing Calculator → estimativa antes da implantação
```

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 1.1 | Avaliar quotas | `P` | `P` |
| 1.2 | Budgets e alerts | `P` | `P*` |
| 1.2 | Billing export | `P` | `P*` |
