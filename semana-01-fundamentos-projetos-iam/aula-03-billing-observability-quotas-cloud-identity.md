# Aula 3 — Billing, Observability, Quotas e Cloud Identity

## Cobertura no exam guide

Exam Guide 1.1 e 1.2: Cloud Identity, produtos de Observability, quotas, billing accounts, vínculo de projetos, budgets e billing export.

**Pré-requisito:** algumas operações de billing/Cloud Identity dependem de permissões administrativas. Quando indisponíveis, faça inspeção e decisão, não tente contornar permissões.

## 1. Conceito

Esta aula fecha os itens de configuração do ambiente que não cabem apenas em Project/gcloud/IAM. Cloud Identity organiza usuários/grupos; billing define quem paga; quotas limitam capacidade técnica; Observability fornece operação inicial.

### Arquitetura / modelo mental

```text
Cloud Identity users/groups → IAM
Billing Account → Project → Resources
Quota → limite técnico
Observability → Monitoring + Logging
```

## 2. Criar / Configurar

Use um projeto de laboratório.

```bash
export PROJECT_ID=$(gcloud config get-value project)
gcloud billing accounts list
gcloud billing projects describe "$PROJECT_ID"
gcloud compute project-info describe --format='yaml(quotas)'
gcloud services enable monitoring.googleapis.com logging.googleapis.com
```

Se sua conta tiver Organization, liste-a; caso contrário, documente por que Cloud Identity/Org management não é executável na conta pessoal.

## 3. Inspecionar

```bash
gcloud organizations list
gcloud billing projects describe "$PROJECT_ID"
gcloud services list --enabled --filter='monitoring.googleapis.com OR logging.googleapis.com'
```

No Console visite Billing → Budgets & alerts e Billing export. Não altere billing de projeto corporativo.

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

No Console, crie um budget de laboratório se possuir permissão e configure um threshold. Confirme que a criação não desliga recursos. No Metrics Explorer, confirme que o projeto pode consultar métricas.

## 5. Quebrar propositalmente

Falha conceitual controlada: trate um budget como se fosse quota e tente explicar por que “100% do budget bloqueará novas VMs” está errado.

## 6. Troubleshooting

**Sintoma:** expectativa de bloqueio automático ao atingir budget.

**Hipótese:** confusão entre mecanismo financeiro e limite técnico.

**Evidência:** quotas aparecem em `compute project-info`; budget aparece no Billing.

**Causa:** conceitos diferentes.

**Correção:** budget alerta/acompanha; quota limita capacidade.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Registre um quadro: `Budget != Quota != IAM`. Se criou budget apenas para o lab, remova no Console.

## 8. Questões estilo ACE

1. Quer alertar em 80% do custo? **Budget**.
2. Quer detalhamento para análise de custos? **Billing export para BigQuery**.
3. Muitos usuários com mesma função? **Grupo Cloud Identity + IAM binding**.
4. `RESOURCE_EXHAUSTED`? **Quota/capacidade**, não budget.

## 9. Cleanup

Remova budgets de laboratório e recursos criados. APIs podem permanecer habilitadas.

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.
