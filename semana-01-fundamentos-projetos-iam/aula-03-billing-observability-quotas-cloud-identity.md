# Aula 3 — Billing, Observability, Quotas e Cloud Identity

## Objetivos

Ao final, você deverá:

- explicar o papel do Cloud Identity na gestão de usuários e grupos;
- entender a relação entre Billing Account, Projects e Resources;
- inspecionar a associação de faturamento de um Project;
- explicar e configurar Budgets e alertas de faturamento quando houver permissão;
- entender Billing Export e seu uso para análise de custos;
- identificar quotas relevantes e entender o processo de solicitação de aumento;
- reconhecer os produtos básicos do Google Cloud Observability exigidos pelo exame.

---

# 1. Visão geral

Esta aula conecta quatro áreas diferentes que costumam ser confundidas:

```text
Cloud Identity
→ quem são os usuários e grupos?

Billing
→ quem paga pelos recursos?

Quotas
→ quanto de um recurso/serviço pode ser usado?

Observability
→ como observar saúde, comportamento e desempenho?
```

Modelo geral:

```text
Cloud Identity users/groups
        ↓
       IAM
        ↓
     Project
        ↓
    Resources
        │
        ├── Billing Account → custos
        ├── Quotas → limites técnicos
        └── Observability → métricas, logs, dashboards e alertas
```

---

# 2. Cloud Identity

## 2.1 O que é

Cloud Identity fornece gerenciamento centralizado de identidades para organizações que usam serviços Google Cloud.

Ele permite administrar:

```text
users
groups
group memberships
```

Essas identidades podem ser usadas como principals no IAM.

Exemplo:

```text
Cloud Identity Group
devops@example.com
       ↓
IAM binding
roles/compute.viewer
       ↓
Project
```

Importante:

```text
Cloud Identity
→ gerencia identidades

IAM
→ gerencia autorização
```

Cloud Identity não substitui IAM.

IAM não substitui o diretório de usuários e grupos.

---

# 3. Usuários e grupos

Um **user** representa uma pessoa.

Exemplo:

```text
antonio@example.com
```

Um **group** reúne vários usuários.

Exemplo:

```text
cloud-viewers@example.com
```

Em vez de conceder IAM individualmente:

```text
user A → role
user B → role
user C → role
```

é normalmente melhor:

```text
users
  ↓ membership
group
  ↓ IAM role
resource
```

Isso facilita administração em escala.

---

# 4. Provisionamento manual e automatizado

## 4.1 Manual

Em ambientes pequenos, usuários e grupos podem ser administrados pelo Google Admin Console.

Modelo:

```text
Admin Console
    ↓
criar user
    ↓
criar group
    ↓
adicionar membership
```

Também é possível importar usuários em massa por CSV.

## 4.2 Automatizado

Em empresas que já utilizam Active Directory ou LDAP, manter identidades manualmente em dois lugares aumenta risco de inconsistência.

Uma opção é:

```text
Active Directory / LDAP
        ↓
Google Cloud Directory Sync
        ↓
Cloud Identity
```

O Google Cloud Directory Sync, ou GCDS, sincroniza identidades e grupos do diretório corporativo com o diretório Google.

Outra opção é automação programática:

```text
sistema corporativo
        ↓
Admin SDK Directory API
        ↓
Cloud Identity
```

### Quando escolher cada abordagem?

```text
poucos usuários
→ manual / CSV

diretório corporativo existente
→ GCDS

provisionamento controlado por aplicação
→ Admin SDK Directory API
```

> **Prática `P*`:** Cloud Identity normalmente exige domínio e privilégios administrativos. Em conta pessoal sem Organization, estude o fluxo e execute apenas o que estiver disponível.

---

# 5. Billing Account

Uma **Cloud Billing Account** representa a entidade de faturamento usada para pagar pelos recursos Google Cloud.

Modelo:

```text
Billing Account
    ├── Project A
    │     ├── VM
    │     └── Bucket
    │
    └── Project B
          └── Cloud Run
```

O custo dos Resources pertence ao Project, e o Project é associado a uma Billing Account.

Portanto:

```text
Billing Account
→ paga

Project
→ agrupa uso/custos

Resource
→ gera consumo
```

Um Billing Account pode estar associado a vários Projects.

---

# 6. Inspecionar Billing Accounts

Defina:

```bash
# Obtém o Project ID ativo.
export PROJECT_ID="$(gcloud config get-value project)"
```

Liste Billing Accounts acessíveis:

```bash
# Lista as Billing Accounts que sua identidade consegue visualizar.
gcloud billing accounts list
```

Você poderá ver campos como:

```text
ACCOUNT_ID
NAME
OPEN
```

Nem toda identidade possui permissão para listar todas as Billing Accounts de uma organização.

---

# 7. Inspecionar o vínculo de Billing de um Project

Execute:

```bash
# Mostra a Billing Account associada ao Project.
gcloud billing projects describe "$PROJECT_ID"
```

Observe principalmente:

```text
billingAccountName
billingEnabled
projectId
```

Modelo:

```text
Project
   ↓ linked to
Billing Account
```

Se:

```text
billingEnabled: true
```

o Project possui faturamento habilitado.

Se não houver Billing Account válida, muitos serviços pagos não poderão ser utilizados normalmente.

---

# 8. Budget

Um **Budget** é um mecanismo de acompanhamento financeiro.

Exemplo:

```text
Budget mensal
R$ 1.000
```

Ele permite comparar:

```text
custo acumulado
vs
valor definido para o Budget
```

A principal ideia:

```text
Budget
≠
hard limit
```

Atingir 100% do Budget **não desliga automaticamente** VMs nem bloqueia consumo.

---

# 9. Budget thresholds

Os **thresholds** definem quando uma notificação deve ser acionada.

Exemplo:

```text
Budget: R$ 1.000

50%
→ R$ 500

80%
→ R$ 800

100%
→ R$ 1.000
```

Há dois conceitos importantes:

```text
Actual spend
→ custo efetivamente acumulado até aquele momento

Forecasted spend
→ previsão de custo para o final do período
```

Exemplo:

```text
Budget: R$ 1.000
Actual threshold: 80%
→ alerta quando gasto real alcançar R$ 800

Forecast threshold: 100%
→ alerta quando previsão indicar que o período terminará acima de R$ 1.000
```

---

# 10. Criar Budget e threshold por gcloud

> **Nível:** `P*` — exige permissão adequada na Billing Account.

Primeiro obtenha a Billing Account vinculada ao projeto.

```bash
# Obtém o Project ID ativo.
export PROJECT_ID="$(gcloud config get-value project)"

# Obtém a Billing Account associada ao projeto.
# A saída costuma ter o formato billingAccounts/XXXXXX-XXXXXX-XXXXXX.
export BILLING_ACCOUNT_RESOURCE="$(gcloud billing projects describe "$PROJECT_ID" \
  --format='value(billingAccountName)')"

# Extrai somente o ID da Billing Account.
export BILLING_ACCOUNT="${BILLING_ACCOUNT_RESOURCE#billingAccounts/}"

echo "$BILLING_ACCOUNT"
```

Valide que a Billing Account foi encontrada:

```bash
# Mostra a associação de Billing do projeto.
gcloud billing projects describe "$PROJECT_ID"
```

Crie um Budget pequeno de laboratório:

```bash
# Cria um Budget mensal de laboratório.
#
# --billing-account:
#   Billing Account onde o Budget será criado.
#
# --display-name:
#   Nome amigável do Budget.
#
# --budget-amount:
#   Valor do Budget. Se a moeda não for informada,
#   a moeda da Billing Account é utilizada.
#
# --calendar-period=month:
#   Faz o Budget se repetir mensalmente.
#
# --threshold-rule:
#   percent usa escala de 0 a 1.
#   0.50 = 50%.
#
# basis=current-spend:
#   avalia gasto real acumulado.
gcloud billing budgets create \
  --billing-account="$BILLING_ACCOUNT" \
  --display-name="ACE-LAB-BUDGET" \
  --budget-amount=10 \
  --calendar-period=month \
  --threshold-rule=percent=0.50,basis=current-spend
```

A documentação atual do `gcloud billing budgets create` confirma que
`--threshold-rule` pode ser repetido e que `percent=0.50` significa 50%.
O `basis` pode ser `current-spend` ou `forecasted-spend`.

## 10.1 Criar mais de um threshold

Exemplo:

```bash
gcloud billing budgets create \
  --billing-account="$BILLING_ACCOUNT" \
  --display-name="ACE-LAB-BUDGET-2" \
  --budget-amount=10 \
  --calendar-period=month \
  --threshold-rule=percent=0.50,basis=current-spend \
  --threshold-rule=percent=0.80,basis=current-spend \
  --threshold-rule=percent=1.00,basis=forecasted-spend
```

Modelo:

```text
50% current-spend
→ alerta por gasto real

80% current-spend
→ alerta por gasto real

100% forecasted-spend
→ alerta quando a previsão atingir 100%
```

## 10.2 Listar Budgets

```bash
# Lista Budgets da Billing Account.
gcloud billing budgets list \
  --billing-account="$BILLING_ACCOUNT"
```

Guarde o nome do Budget:

```bash
# Captura o resource name do Budget criado.
export BUDGET_NAME="$(gcloud billing budgets list \
  --billing-account="$BILLING_ACCOUNT" \
  --filter='displayName=ACE-LAB-BUDGET' \
  --format='value(name)' \
  --limit=1)"

echo "$BUDGET_NAME"
```

## 10.3 Descrever o Budget

```bash
# Mostra amount, thresholdRules e demais propriedades.
gcloud billing budgets describe "$BUDGET_NAME" \
  --billing-account="$BILLING_ACCOUNT"
```

Confirme que existe algo equivalente a:

```text
amount
thresholdRules
  thresholdPercent: 0.5
  spendBasis: CURRENT_SPEND
```

## 10.4 Confirmar que Budget não desliga recursos

A criação de um Budget não altera o estado dos recursos.

Se você já possuir uma VM de laboratório:

```bash
# Lista as VMs antes/depois de criar o Budget.
gcloud compute instances list
```

O Budget não executa:

```text
stop VM
delete VM
disable API
block resource creation
```

Ele é um mecanismo de acompanhamento/notificação financeira.

Portanto:

```text
Budget atingido
≠
recursos desligados automaticamente
```

## 10.5 Cleanup do Budget de laboratório

Liste antes de excluir:

```bash
gcloud billing budgets list \
  --billing-account="$BILLING_ACCOUNT"
```

Exclua:

```bash
# Remove somente o Budget de laboratório.
gcloud billing budgets delete "$BUDGET_NAME" \
  --billing-account="$BILLING_ACCOUNT" \
  --quiet
```

> Não exclua Budgets corporativos ou compartilhados.

# 11. Billing Export

Budgets ajudam a acompanhar gasto.

Mas, para análise detalhada de custos, precisamos dos dados de Billing.

Modelo:

```text
Cloud Billing
    ↓ export
BigQuery Dataset
    ↓
Billing tables
    ↓
SQL
    ↓
FinOps / dashboards / análise
```

Billing Export permite enviar dados de faturamento para BigQuery automaticamente.

---

# 12. O que pode ser analisado com Billing Export

Dependendo do tipo de export configurado, os dados podem incluir:

```text
Billing Account
Project
Service
SKU
location
usage
cost
credits
labels
resource-level cost
```

Exemplo de pergunta:

```text
Quanto o Project X gastou este mês?
```

ou:

```text
Qual serviço gerou mais custo?
```

ou ainda:

```text
Quais recursos específicos estão aumentando o custo?
```

---

# 13. Tipos principais de Billing Export

Para ACE, não é necessário decorar todo o schema.

Entenda principalmente:

```text
Standard usage cost
→ análise geral de custos e tendências

Detailed usage cost
→ adiciona granularidade de custo por recurso

Pricing data
→ informações de preços/SKUs
```

---

# 14. Configurar Billing Export

> **Nível:** `P*` — depende de permissão na Billing Account e no BigQuery.

No Console:

```text
Billing
→ Billing export
→ BigQuery export
```

Fluxo:

```text
Billing Account
      ↓
selecionar tipo de export
      ↓
Project + BigQuery Dataset
      ↓
ativar export
      ↓
tabelas criadas automaticamente
```

Depois:

```text
BigQuery
→ Dataset
→ tabela de Billing
→ consulta SQL
```

A ativação não significa que todo o histórico anterior aparecerá obrigatoriamente; a disponibilidade dos dados depende do tipo e da localização do dataset.

---

# 15. Quotas

Uma **quota** é um limite técnico aplicado ao consumo de determinado serviço ou recurso.

Exemplos conceituais:

```text
número de CPUs
número de IPs
quantidade de recursos
taxa de requests
```

Compare:

```text
Budget
→ referência financeira

Quota
→ limite técnico
```

---

# 16. Quota, metric e dimensions

Uma quota normalmente está associada a:

```text
service
quota metric
scope/dimensions
value
```

Exemplo conceitual:

```text
Service
→ Compute Engine

Quota
→ CPUs

Dimension
→ region=us-central1

Value
→ limite disponível naquela dimensão
```

Por isso, duas regiões podem ter valores diferentes para determinada quota.

---

# 17. Inspecionar quotas

Para Compute Engine:

```bash
# Exibe quotas e uso do Compute Engine para o Project.
gcloud compute project-info describe \
  --format="yaml(quotas)"
```

No Console:

```text
IAM & Admin
→ Quotas & System Limits
```

Procure campos como:

```text
Service
Quota
Dimensions
Current usage
Current value
```

---

# 18. Solicitar aumento de quota

> **Nível:** `P*` — exige permissão e pode depender de aprovação do Google.

Fluxo no Console:

```text
IAM & Admin
→ Quotas & System Limits
→ filtrar service/quota
→ selecionar quota
→ Edit quotas
→ informar novo valor
→ Submit request
```

Nem toda solicitação é aprovada instantaneamente.

Algumas podem:

```text
ser aprovadas automaticamente
ou
entrar em análise
```

Depois você pode acompanhar o status da solicitação.

### Permissões relevantes

Para ambientes reais, existem roles específicas para visualização e administração de quotas.

Nesta semana, o importante é reconhecer que:

```text
não conseguir aumentar quota
≠ problema no recurso

pode ser:
→ falta de IAM
→ quota não ajustável
→ solicitação pendente
→ limite sujeito a análise
```

---

# 19. Google Cloud Observability

Google Cloud Observability reúne serviços que ajudam a entender:

```text
saúde
comportamento
desempenho
falhas
```

dos sistemas.

Para a Semana 1, o objetivo é reconhecer os componentes básicos.

A operação profunda fica para a Semana 6.

---

# 20. Cloud Monitoring

Cloud Monitoring trabalha principalmente com **métricas**.

Exemplos:

```text
CPU utilization
request count
latency
memory metric
custom metric
```

Modelo:

```text
Resource
   ↓ métricas
Cloud Monitoring
   ↓
Charts / Dashboards / Alerts
```

Use Monitoring quando a pergunta for:

```text
quanto?
com que frequência?
qual valor ao longo do tempo?
```

---

# 21. Cloud Logging

Cloud Logging trabalha com **logs e eventos**.

Exemplos:

```text
application log
system log
audit log
error message
request log
```

Modelo:

```text
Resource / Application
       ↓ logs
Cloud Logging
       ↓
search / filter / analysis
```

Use Logging quando precisar responder:

```text
o que aconteceu?
quando aconteceu?
qual mensagem foi registrada?
```

---

# 22. Metrics x Logs

Não confunda:

```text
Metric
→ série temporal numérica
→ CPU = 82%

Log
→ evento/registro
→ "database connection failed"
```

Exemplo de troubleshooting:

```text
Monitoring
→ mostra aumento de erros

Logging
→ mostra a mensagem concreta do erro
```

---

# 23. Dashboards

Dashboard é uma forma de visualizar informações operacionais, normalmente por meio de charts.

Modelo:

```text
Metrics
  ↓
Charts
  ↓
Dashboard
```

Exemplo:

```text
Dashboard da aplicação
├── CPU
├── request count
├── latency
└── error rate
```

Dashboard:

```text
visualiza
```

Ele não é, por si só, o mecanismo que corrige o problema.

---

# 24. Alerting

Alerting avalia uma condição e pode gerar notificações.

Modelo:

```text
Metric / condição
      ↓
Alert Policy
      ↓
Incident
      ↓
Notification
```

Exemplo:

```text
CPU > 80%
por 5 minutos
      ↓
incident
      ↓
notification
```

Não confunda:

```text
Billing Budget alert
→ condição financeira

Monitoring alert
→ condição operacional
```

---

# 25. Error Reporting e Cloud Trace

O conjunto Google Cloud Observability também inclui outros serviços.

Para reconhecimento:

```text
Error Reporting
→ agrega erros de aplicações

Cloud Trace
→ ajuda a analisar latência distribuída
```

Esses serviços serão tratados apenas no nível necessário ao roadmap; Monitoring e Logging são os componentes centrais desta primeira introdução.

---

# 26. Preparar Observability por CLI

Habilite as APIs principais:

```bash
# Habilita Cloud Monitoring e Cloud Logging.
gcloud services enable \
  monitoring.googleapis.com \
  logging.googleapis.com
```

Valide:

```bash
# Confirma que as APIs estão habilitadas.
gcloud services list \
  --enabled \
  --filter="NAME:(monitoring.googleapis.com logging.googleapis.com)"
```

---

# 27. Confirmar consulta de métricas sem Metrics Explorer

O objetivo do exercício é provar que o projeto consegue consultar dados do Cloud Monitoring.

A CLI estável atual possui:

```text
gcloud monitoring dashboards
gcloud monitoring policies
gcloud monitoring snoozes
gcloud monitoring uptime
```

Ela **não possui um subcomando estável equivalente a**:

```text
gcloud monitoring metrics list
```

nem a:

```text
gcloud monitoring time-series list
```

Por isso, para consultar métricas sem usar o Console, use:

```text
gcloud
→ autenticação

Monitoring REST API
→ consulta
```

## 27.1 Obter access token com gcloud

```bash
# Gera um access token OAuth da identidade ativa.
export ACCESS_TOKEN="$(gcloud auth print-access-token)"
```

## 27.2 Consultar metric descriptors

```bash
# Consulta a Monitoring API e lista alguns tipos de métricas
# disponíveis para o projeto.
#
# Se a chamada retornar JSON com "metricDescriptors",
# o projeto e a identidade atual conseguem consultar a API.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/metricDescriptors?pageSize=5"
```

Resultado esperado:

```json
{
  "metricDescriptors": [
    ...
  ]
}
```

Isso valida:

```text
Monitoring API habilitada
+
autenticação válida
+
autorização de leitura
+
consulta de métricas/descritores possível
```

A operação usada é:

```text
projects.metricDescriptors.list
```

## 27.3 Consultar uma métrica específica

Se você possui uma VM produzindo métricas, pode consultar séries temporais.

Defina o intervalo:

```bash
# Horário atual em UTC.
export END_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# 20 minutos atrás em UTC.
export START_TIME="$(date -u -d '20 minutes ago' +%Y-%m-%dT%H:%M:%SZ)"
```

Consulte CPU de Compute Engine:

```bash
# URL-encode do filtro é feito pelo curl com --get/--data-urlencode.
curl -sS --get \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  --data-urlencode 'filter=metric.type="compute.googleapis.com/instance/cpu/utilization"' \
  --data-urlencode "interval.startTime=$START_TIME" \
  --data-urlencode "interval.endTime=$END_TIME" \
  "https://monitoring.googleapis.com/v3/projects/$PROJECT_ID/timeSeries"
```

Se não houver VM ou amostras recentes, a resposta pode conter:

```json
{
  "timeSeries": []
}
```

Isso não significa necessariamente erro.

Significa:

```text
consulta funcionou
mas não houve série temporal correspondente no intervalo
```

## 27.4 Diferenciar acesso de ausência de dados

```text
HTTP 200 + lista com dados
→ acesso e dados OK

HTTP 200 + lista vazia
→ acesso OK, sem dados no filtro/intervalo

HTTP 403
→ problema de IAM/permissão

HTTP 404/400
→ revisar endpoint, projeto ou filtro
```

## 27.5 Alternativa simples com gcloud monitoring

Embora isso não consulte séries temporais, você pode validar que o projeto acessa a API de Monitoring com:

```bash
# Lista Alert Policies visíveis no projeto.
# Lista vazia é válida se nenhuma policy existir.
gcloud monitoring policies list
```

Este comando prova acesso ao recurso de Alerting, mas **não substitui** a consulta de métricas acima.

# 28. Teste integrado

Explique, sem consultar:

```text
Cloud Identity
→ usuários/grupos

IAM
→ autorização

Billing Account
→ paga pelos Projects

Budget
→ acompanha custo e alerta

Billing Export
→ envia dados de custo para BigQuery

Quota
→ limita consumo técnico

Monitoring
→ métricas

Logging
→ logs

Dashboard
→ visualização

Alert Policy
→ condição operacional + incident/notificação
```

Se algum desses itens ainda parece equivalente a outro, revise antes de seguir.

---

# 29. Quebrar propositalmente

Considere a afirmação:

```text
"Configurei um Budget de R$ 100.
Quando chegar a 100%, novas VMs serão bloqueadas."
```

Essa afirmação está errada.

---

# 30. Troubleshooting

## Sintoma

A equipe esperava bloqueio automático ao atingir o Budget.

## Hipótese

Budget foi confundido com quota.

## Evidência

```text
Billing
→ Budget

IAM & Admin
→ Quotas & System Limits
```

São mecanismos diferentes.

## Causa

```text
Budget
→ mecanismo financeiro

Quota
→ limite técnico
```

## Correção

Use:

```text
Budget
→ acompanhar/alertar custo

Quota
→ controlar limite técnico disponível
```

Se a empresa quiser automação de desligamento baseada em Billing notifications, isso exige arquitetura adicional e não deve ser confundido com o comportamento padrão do Budget.

---

# 31. Questões estilo ACE

## Questão 1

Uma empresa quer conceder `roles/compute.viewer` a 200 pessoas com a mesma função.

Melhor abordagem:

**Resposta:** criar/usar um Cloud Identity group e conceder a role ao grupo.

---

## Questão 2

Qual componente paga pelo consumo associado a um Project?

**Resposta:** Cloud Billing Account vinculada ao Project.

---

## Questão 3

Uma equipe quer receber aviso quando atingir 80% de um valor mensal.

**Resposta:** Budget com threshold de 80%.

---

## Questão 4

A equipe quer saber quais serviços e Projects geraram mais custos ao longo do mês.

**Resposta:** Billing Export para BigQuery.

---

## Questão 5

Uma implantação falha porque o limite de CPUs da região foi atingido.

**Resposta:** investigar quota, não Budget.

---

## Questão 6

Você precisa responder:

> “A CPU ficou acima de 80%?”

**Resposta:** Cloud Monitoring.

---

## Questão 7

Você precisa responder:

> “Qual mensagem de erro a aplicação registrou?”

**Resposta:** Cloud Logging.

---

# 32. Cleanup

Se criou um Budget somente para laboratório:

```bash
gcloud billing budgets delete "$BUDGET_NAME"   --billing-account="$BILLING_ACCOUNT"   --quiet
```

Se habilitou Billing Export apenas para teste e possui permissão, remova-o somente se tiver certeza de que não é usado por outras pessoas.

Não desabilite Monitoring e Logging se continuar usando o mesmo Project no roadmap.

---

# 33. Checklist

- [ ] Sei explicar Cloud Identity;
- [ ] Sei diferenciar user e group;
- [ ] Sei diferenciar provisionamento manual e automatizado;
- [ ] Sei explicar Billing Account;
- [ ] Sei explicar a relação Billing Account → Project → Resource;
- [ ] Sei inspecionar o vínculo de Billing de um Project;
- [ ] Sei explicar Budget;
- [ ] Sei explicar threshold;
- [ ] Sei diferenciar Actual e Forecasted spend;
- [ ] Sei que Budget não bloqueia consumo automaticamente;
- [ ] Sei explicar Billing Export;
- [ ] Sei diferenciar Standard e Detailed usage cost;
- [ ] Sei explicar quota;
- [ ] Sei reconhecer service, quota e dimension;
- [ ] Sei descrever o processo de solicitação de aumento;
- [ ] Sei diferenciar Budget e Quota;
- [ ] Sei explicar Cloud Monitoring;
- [ ] Sei explicar Cloud Logging;
- [ ] Sei diferenciar metric e log;
- [ ] Sei explicar Dashboard;
- [ ] Sei explicar Alert Policy;
- [ ] Sei diferenciar Billing alert de Monitoring alert.

---

# 34. Critério de aceite M/E/P

| Objetivo | Nível | Evidência |
|---|---:|---|
| Cloud Identity users/groups | E/P* | conceito + modelo + fluxo manual/automatizado |
| Billing Account → Project → Resource | E/P | conceito + `billing projects describe` |
| Inspecionar billing linkage | P | `gcloud billing projects describe` |
| Budget e alerts | E/P* | threshold, Actual/Forecasted + configuração guiada |
| Billing Export | E/P* | tipos + arquitetura BigQuery + configuração guiada |
| Quotas | E/P* | conceito + inspeção + fluxo de aumento |
| Google Cloud Observability | E/P | Monitoring, Logging, dashboards, alerts + APIs e inspeção |

---

## Resumo para prova

```text
Cloud Identity
→ identidade

IAM
→ autorização

Billing Account
→ paga

Budget
→ acompanha e alerta custo

Billing Export
→ dados de custo no BigQuery

Quota
→ limite técnico

Monitoring
→ métricas

Logging
→ logs

Dashboard
→ visualização

Alert Policy
→ condição operacional e notificação
```
