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


---

# Cobertura ACE ampliada — billing, observability, quotas e Cloud Identity

## Billing accounts e linkage

```bash
gcloud billing accounts list
gcloud billing projects describe $PROJECT_ID
```

Conceito:

```text
Billing Account
  └─ linked Project
      └─ billable resources
```

## Budgets e alerts

Budget **não bloqueia automaticamente** o consumo. Ele acompanha gasto e dispara alertas/integrações configuradas.

## Billing export

O exam guide inclui configuração de billing export. O cenário mais comum é exportar dados detalhados para BigQuery para análises de custo.

```text
Cloud Billing
   ↓ export
BigQuery dataset
   ↓
SQL / dashboards / FinOps
```

A ativação é normalmente feita em **Billing → Billing export** no Console, pois exige permissão na Billing Account.

## Quotas e aumento

```bash
gcloud compute project-info describe --format='yaml(quotas)'
```

Diferencie:

```text
Budget → limite financeiro de referência/alerta
Quota  → limite técnico de uso
```

## Google Cloud Observability

O guia cobra provisioning/setup dos produtos de observabilidade. Nesta etapa identifique:

- Cloud Monitoring;
- Cloud Logging;
- dashboards;
- alerts;
- métricas;
- logs.

O aprofundamento operacional ocorre na Semana 6.

## Cloud Identity

Cloud Identity gerencia usuários e grupos associados à organização. Para ACE, entenda:

- usuários;
- grupos;
- associação de grupos a IAM roles;
- provisionamento manual ou automatizado.

Exemplo mental:

```text
Cloud Identity Group: devops@example.com
       ↓ IAM binding
roles/compute.viewer
       ↓
Project
```


---

## Práticas guiadas obrigatórias — Cloud Identity, Billing e Quotas

### Cloud Identity — usuários e grupos

**Nível:** `P*` — requer privilégios administrativos do domínio/Cloud Identity.

No Admin Console de uma organização de laboratório:

1. crie um usuário de laboratório;
2. crie um grupo, por exemplo `ace-viewers`;
3. adicione o usuário ao grupo;
4. no Google Cloud IAM, conceda uma role de leitura ao **grupo**, não ao usuário individual;
5. remova o usuário do grupo e observe que o modelo de autorização passa a depender da associação ao grupo.

Modelo:

```text
Cloud Identity user
      ↓ membership
Cloud Identity group
      ↓ IAM binding
Project / Resource
```

Automação de provisionamento deve ser reconhecida como alternativa ao gerenciamento manual quando a organização utiliza integração/provisionamento de identidade.

### Billing Account e vinculação de projeto

**Nível:** `P*` — exige permissões de Billing Account.

Inspecione:

```bash
gcloud billing accounts list
gcloud billing projects describe "$PROJECT_ID"
```

Se possuir uma Billing Account de laboratório, pratique o fluxo no Console:

```text
Billing → Account management → My projects
→ selecionar projeto
→ Change billing
→ escolher Billing Account autorizada
```

Não altere vínculo de billing de projeto corporativo.

### Billing Export

**Nível:** `P*`.

No Console:

```text
Billing → Billing export → BigQuery export
```

Pratique:

1. selecionar/criar dataset de laboratório;
2. identificar export de uso/custos disponível;
3. configurar o dataset quando tiver permissão;
4. depois verificar as tabelas criadas no BigQuery.

O objetivo é sair de:

```text
Billing export = “sei que existe”
```

para:

```text
Billing Account → BigQuery dataset → tabelas de custo → consulta SQL
```

### Solicitar aumento de quota

**Nível:** `P*` — o pedido real pode exigir autorização e aprovação.

Primeiro inspecione quotas:

```bash
gcloud compute project-info describe --format='yaml(quotas)'
```

No Console:

```text
IAM & Admin → Quotas & System Limits
```

Pratique o fluxo:

1. filtre por serviço/métrica;
2. selecione a quota;
3. abra **Edit quotas**;
4. observe limite atual e região/escopo;
5. não envie aumento desnecessário em projeto corporativo.

### Critério de prova

```text
Budget → alerta financeiro
Quota → limite técnico
Billing Export → análise detalhada de custo
Cloud Identity Group → administração de acesso em escala
```
