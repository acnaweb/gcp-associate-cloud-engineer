# Aula 1 — Hierarquia, Projects, Regions, Zones e gcloud

## Objetivos

Ao final, você deverá:

- distinguir Organization, Folder, Project e Resource;
- distinguir Project ID, Project Number e nome;
- entender region e zone;
- criar e alternar `gcloud configurations`;
- habilitar uma API e validar o contexto ativo.

---

# 1. Conceito — como o Google Cloud organiza recursos

O Google Cloud organiza recursos em uma hierarquia.

```text
Organization
   ↓
Folder
   ↓
Project
   ↓
Resources
```

Essa hierarquia não serve apenas para “organizar pastas”. Ela influencia:

```text
IAM inheritance
Organization Policies
visibilidade
delegação administrativa
billing
quotas
APIs
```

---

# 2. Organization, Folder, Project e Resource

## 2.1 Organization

A **Organization** é o nível administrativo mais alto da hierarquia.

Modelo:

```text
Organization
   ├── Folder
   ├── Folder
   └── Project
```

Ela normalmente representa:

```text
empresa
instituição
domínio administrativo
```

É um ponto central para:

- políticas organizacionais;
- IAM herdado;
- governança;
- visibilidade dos projetos;
- delegação administrativa.

Uma Organization pode existir sem Folder.

Exemplo:

```text
Organization: marketmining.com.br
   ├── Project: mm-dev
   └── Project: mm-prod
```

## 2.2 Folder

Folder é um agrupador opcional dentro da Organization.

Use Folder para representar, por exemplo:

```text
departamento
ambiente
unidade de negócio
time
```

Exemplo:

```text
Organization
   ├── Folder: Engenharia
   │      ├── Project: app-dev
   │      └── Project: app-prod
   │
   └── Folder: Dados
          ├── Project: data-dev
          └── Project: data-prod
```

Folders são importantes porque políticas IAM e Organization Policies podem ser aplicadas no Folder e herdadas pelos Projects abaixo dele.

## 2.3 Project

Project é a unidade central de organização para uso de serviços Google Cloud.

É nele que você normalmente:

```text
habilita APIs
cria recursos
associa billing
gerencia quotas
concede IAM
```

Modelo:

```text
Project
   ├── Compute Engine VM
   ├── Cloud Storage Bucket
   ├── Cloud Run Service
   └── BigQuery Dataset
```

O Project é um ponto importante de fronteira administrativa, mas não confunda isso com isolamento absoluto: algumas políticas e permissões podem ser herdadas de níveis superiores.

## 2.4 Resource

Resource é o recurso concreto criado dentro da plataforma.

Exemplos:

```text
VM
Bucket
VPC
Cloud Run Service
Cloud SQL Instance
BigQuery Dataset
GKE Cluster
```

Modelo completo:

```text
Organization
   ↓
Folder
   ↓
Project
   ↓
Resource
```

### Regra para prova

```text
Organization
→ raiz administrativa

Folder
→ agrupamento opcional

Project
→ unidade para APIs, billing, quotas, IAM e recursos

Resource
→ recurso real do serviço
```

---

# 3. Inspecionar a hierarquia

Nem toda conta possui Organization.

Liste Organizations visíveis:

```bash
# Lista as Organizations que a identidade atual consegue visualizar.
gcloud organizations list
```

Se houver uma Organization, você verá algo parecido com:

```text
DISPLAY_NAME          ID
marketmining.com.br   123456789012
```

Liste Projects:

```bash
# Lista os projetos visíveis para a identidade atual.
gcloud projects list
```

Se você possui Organization e permissão para listar Folders:

```bash
# Substitua ORG_ID pelo ID numérico da Organization.
export ORG_ID="123456789012"

# Lista os Folders diretamente abaixo da Organization.
gcloud resource-manager folders list \
  --organization="$ORG_ID"
```

> Uma conta pessoal sem Organization pode ter Projects diretamente no topo da sua hierarquia.

---

# 4. Project Name, Project ID e Project Number

Todo Project possui três identificadores que costumam ser confundidos.

## 4.1 Project Name

É o nome amigável exibido para humanos.

Exemplo:

```text
Market Mining Labs
```

Ele é uma propriedade de apresentação.

Não use o nome como identificador técnico principal.

## 4.2 Project ID

É o identificador textual usado em muitos comandos e APIs.

Exemplo:

```text
market-mining-labs
```

Características:

```text
escolhido/criado para o projeto
único globalmente
muito usado em CLI e URLs
```

Exemplo:

```bash
gcloud config set project market-mining-labs
```

## 4.3 Project Number

É um identificador numérico gerado automaticamente pelo Google.

Exemplo:

```text
123456789012
```

Características:

```text
gerado pelo Google
numérico
imutável
usado por alguns service agents e APIs
```

Exemplo de Service Agent:

```text
service-123456789012@serverless-robot-prod.iam.gserviceaccount.com
```

## Comparação direta

```text
Project Name
→ humano / display

Project ID
→ identificador textual usado frequentemente em CLI/API

Project Number
→ identificador numérico gerado pelo Google
```

---

# 5. Inspecionar Name, ID e Number

Defina o projeto atual:

```bash
# Obtém o Project ID configurado no gcloud.
export PROJECT_ID="$(gcloud config get-value project)"
```

Mostre os três valores:

```bash
# Exibe Name, Project ID e Project Number em uma tabela.
gcloud projects describe "$PROJECT_ID" \
  --format="table(name,projectId,projectNumber)"
```

Exemplo esperado:

```text
NAME                 PROJECT_ID           PROJECT_NUMBER
Market Mining Labs   market-mining-labs   123456789012
```

Armazene o Project Number:

```bash
# Extrai somente o Project Number.
export PROJECT_NUMBER="$(gcloud projects describe "$PROJECT_ID" \
  --format='value(projectNumber)')"

echo "$PROJECT_NUMBER"
```

### Pegadinha ACE

Se uma questão pedir:

> “qual identificador é criado automaticamente e é numérico?”

Resposta:

```text
Project Number
```

Se pedir:

> “qual valor normalmente aparece em comandos e precisa identificar o projeto de forma única?”

Resposta:

```text
Project ID
```

---

# 6. Region e Zone

Google Cloud possui recursos distribuídos geograficamente.

Uma **region** é uma área geográfica composta por uma ou mais zones.

Exemplo:

```text
us-central1
   ├── us-central1-a
   ├── us-central1-b
   ├── us-central1-c
   └── us-central1-f
```

## 6.1 Region

Exemplo:

```text
us-central1
southamerica-east1
europe-west1
```

Recursos regionais incluem, por exemplo:

```text
subnets
regional static IPs
alguns managed services
regional disks
```

Um recurso regional pode ser usado dentro daquela region conforme as regras do serviço.

## 6.2 Zone

Zone é uma área de implantação dentro de uma region.

Exemplo:

```text
us-central1-a
```

Recursos tipicamente zonais incluem:

```text
VM
zonal Persistent Disk
machine type availability
```

## 6.3 Global, Regional e Zonal

Modelo mental:

```text
Global
→ disponível no escopo global do serviço/projeto

Regional
→ associado a uma region

Zonal
→ associado a uma zone
```

Exemplos:

```text
VPC network
→ global

Subnet
→ regional

VM
→ zonal
```

### Alta disponibilidade

```text
duas VMs na mesma zone
→ compartilham domínio de falha zonal

VMs em zones diferentes da mesma region
→ maior isolamento de falha

recursos em regions diferentes
→ maior independência geográfica
```

---

# 7. Inspecionar Regions e Zones

Liste regions:

```bash
# Lista regions disponíveis para Compute Engine.
gcloud compute regions list
```

Descreva uma region:

```bash
# Mostra detalhes de us-central1.
gcloud compute regions describe us-central1
```

Liste zones:

```bash
# Lista zones.
gcloud compute zones list
```

Filtre as zones de uma region:

```bash
# Lista somente zones pertencentes a us-central1.
gcloud compute zones list \
  --filter="region:us-central1"
```

Descreva uma zone:

```bash
# Exibe metadados da zone.
gcloud compute zones describe us-central1-a
```

---

# 8. gcloud configurations

Uma `gcloud configuration` é um conjunto nomeado de propriedades usadas pelo CLI.

Exemplo:

```text
configuration: lab
├── account
├── project
├── compute/region
└── compute/zone
```

Você pode ter configurações separadas para:

```text
lab
dev
homologação
produção
```

Exemplo:

```text
ace-lab
→ projeto labs-mm
→ us-central1
→ us-central1-a

production
→ projeto market-mining-prod
→ southamerica-east1
→ southamerica-east1-a
```

Apenas uma configuration fica ativa por vez.

---

# 9. Inspecionar a configuration atual

Liste as configurações existentes:

```bash
# Lista todas as configurations e mostra qual está ativa.
gcloud config configurations list
```

Mostre as propriedades da ativa:

```bash
# Exibe propriedades da configuration ativa.
gcloud config list
```

Mostre valores individualmente:

```bash
# Mostra o Project ID configurado.
gcloud config get-value project

# Mostra a região padrão.
gcloud config get-value compute/region

# Mostra a zona padrão.
gcloud config get-value compute/zone
```

Mostre a conta autenticada ativa:

```bash
# Lista as contas autenticadas e marca a ativa.
gcloud auth list
```

Modelo:

```text
gcloud authentication
→ quem sou eu?

gcloud configuration
→ em qual contexto estou trabalhando?
```

---

# 10. Criar uma nova gcloud configuration

Antes de criar, preserve o Project ID atual:

```bash
# Guarda o projeto da configuration atual.
export PROJECT_ID="$(gcloud config get-value project)"
```

Crie:

```bash
# Cria uma configuration chamada ace-base.
gcloud config configurations create ace-base
```

Ative:

```bash
# Torna ace-base a configuration ativa.
gcloud config configurations activate ace-base
```

Configure o projeto:

```bash
# Define o Project ID para esta configuration.
gcloud config set project "$PROJECT_ID"
```

Configure region:

```bash
# Define uma região padrão para comandos regionais.
gcloud config set compute/region us-central1
```

Configure zone:

```bash
# Define uma zone padrão para comandos zonais.
gcloud config set compute/zone us-central1-a
```

Inspecione:

```bash
# Confirma todos os valores.
gcloud config list
```

---

# 11. Criar e alternar entre duas configurations

Crie outra configuration:

```bash
# Cria uma segunda configuration para demonstrar troca de contexto.
gcloud config configurations create ace-segunda
```

Configure:

```bash
# Mantém o mesmo projeto, mas usa outra region/zone.
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region southamerica-east1
gcloud config set compute/zone southamerica-east1-a
```

Liste:

```bash
# Mostra as duas configurations e identifica a ativa.
gcloud config configurations list
```

Volte para a primeira:

```bash
# Alterna novamente para ace-base.
gcloud config configurations activate ace-base
```

Confirme:

```bash
# Verifica o contexto depois da troca.
gcloud config list
```

### O que mudou?

```text
configuration
→ troca conjunto de propriedades

não é apenas trocar project
```

Ela pode trocar simultaneamente:

```text
account
project
region
zone
outras propriedades
```

---

# 12. APIs e Services

Criar um Project não significa que todas as APIs estão habilitadas.

Antes de usar muitos serviços, a API correspondente precisa estar habilitada.

Exemplo:

```text
Compute Engine
→ compute.googleapis.com

Cloud Run
→ run.googleapis.com

GKE
→ container.googleapis.com
```

Habilitar uma API:

```text
não cria o recurso
```

Apenas permite que o projeto utilize aquele serviço/API, sujeito a IAM, quotas e billing.

---

# 13. Validar o contexto antes de habilitar uma API

Antes de modificar qualquer API, confirme:

```bash
# Confirma a conta ativa.
gcloud auth list

# Confirma a configuration ativa.
gcloud config configurations list

# Confirma o Project ID ativo.
gcloud config get-value project

# Mostra contexto completo.
gcloud config list
```

Modelo mental:

```text
quem?
→ account

onde?
→ project

qual local padrão?
→ region / zone

qual conjunto de propriedades?
→ configuration
```

Só depois:

```text
ação
→ habilitar API
```

---

# 14. Habilitar e validar uma API

Habilite Compute Engine API:

```bash
# Habilita Compute Engine API no projeto ativo.
gcloud services enable compute.googleapis.com
```

Valide:

```bash
# Lista serviços habilitados e filtra Compute Engine API.
gcloud services list \
  --enabled \
  --filter="NAME:compute.googleapis.com"
```

Outra forma:

```bash
# Exibe apenas o nome da API, se estiver habilitada.
gcloud services list \
  --enabled \
  --filter="config.name=compute.googleapis.com" \
  --format="value(config.name)"
```

Resultado esperado:

```text
compute.googleapis.com
```

### Pegadinha

```text
gcloud services enable compute.googleapis.com
```

não cria:

```text
VM
VPC
disk
MIG
```

Ele apenas habilita o serviço.

---

# 15. Teste integrado

Agora valide os cinco objetivos da aula.

## 15.1 Hierarquia

```bash
gcloud organizations list
gcloud projects list
```

Pergunte:

```text
Organization existe?
Folders existem?
Qual Project está ativo?
Quais Resources dependem desse Project?
```

## 15.2 Project identifiers

```bash
gcloud projects describe "$PROJECT_ID" \
  --format="table(name,projectId,projectNumber)"
```

## 15.3 Region e Zone

```bash
gcloud compute regions describe us-central1
gcloud compute zones describe us-central1-a
```

## 15.4 gcloud configurations

```bash
gcloud config configurations list
gcloud config list
```

## 15.5 API

```bash
gcloud services list \
  --enabled \
  --filter="NAME:compute.googleapis.com"
```

Se você consegue explicar a saída de cada bloco, os objetivos deixaram de ser apenas mencionados e passaram a ser realmente observáveis.

---

# 16. Quebrar propositalmente — configuration sem Project

Crie uma configuration isolada:

```bash
# Cria uma configuration sem contexto de projeto.
gcloud config configurations create ace-sem-projeto
```

Confirme:

```bash
# O campo project deve estar vazio.
gcloud config list
```

Garanta que esteja vazio:

```bash
# Remove project da configuration ativa, caso exista.
gcloud config unset project
```

Agora execute:

```bash
# Esse comando depende de um Project ativo.
gcloud compute instances list
```

Dependendo do ambiente e propriedades herdadas, o comando deve reclamar da ausência de Project ou exigir que você forneça `--project`.

---

# 17. Troubleshooting

## Sintoma

Um comando `gcloud` não sabe em qual Project operar.

## Hipótese

A configuration ativa não possui:

```text
core/project
```

## Evidência

```bash
gcloud config get-value project
```

e:

```bash
gcloud config configurations list
```

## Causa

A configuration `ace-sem-projeto` não possui Project definido.

## Correção

```bash
# Define novamente o Project ID.
gcloud config set project "$PROJECT_ID"
```

Teste:

```bash
gcloud compute instances list
```

---

# 18. Organization Policy

Organization Policy é diferente de IAM.

```text
IAM
→ quem pode fazer?

Organization Policy
→ quais configurações são permitidas?
```

Exemplo:

```text
IAM
→ usuário pode criar VM

Organization Policy
→ VM com IP externo pode ser proibida
```

Inspecione políticas aplicadas ao Project:

```bash
# Lista Organization Policies visíveis/aplicáveis ao Project.
gcloud org-policies list \
  --project="$PROJECT_ID"
```

> Em conta pessoal sem Organization, parte desses comandos pode não produzir conteúdo relevante. O importante no ACE é compreender a diferença conceitual.

---

# 19. Cloud Asset Inventory

Cloud Asset Inventory ajuda a descobrir e pesquisar recursos.

Modelo:

```text
Cloud Asset Inventory
→ inventário pesquisável de recursos e políticas
```

Exemplo:

```bash
# Pesquisa até 20 recursos no escopo do projeto.
gcloud asset search-all-resources \
  --scope="projects/$PROJECT_ID" \
  --limit=20
```

Perguntas que ele ajuda a responder:

```text
Quais recursos existem?
Qual o tipo?
Qual a localização?
Qual o nome completo do recurso?
```

---

# 20. Workforce Identity Federation

Não confunda:

```text
Workforce Identity Federation
→ pessoas/usuários externos acessando Google Cloud

Workload Identity Federation
→ workloads externos obtendo credenciais Google
```

Esse tópico é complementar nesta aula. A configuração completa depende de um Identity Provider externo e não será construída aqui.

---

# 21. Questões estilo ACE

## Questão 1

Uma empresa quer aplicar uma política a vários projetos de um departamento sem configurá-la projeto por projeto.

Qual recurso da hierarquia é adequado para agrupar esses projetos?

**Resposta:** Folder.

---

## Questão 2

Qual identificador de Project é numérico e gerado automaticamente pelo Google?

**Resposta:** Project Number.

---

## Questão 3

Uma VM está em:

```text
us-central1-a
```

Esse valor representa:

**Resposta:** uma Zone.

A Region é:

```text
us-central1
```

---

## Questão 4

Você trabalha alternadamente em dois Projects e deseja manter Project, Region e Zone separados no CLI.

Qual recurso usar?

**Resposta:** `gcloud configurations`.

---

## Questão 5

Você habilitou:

```text
compute.googleapis.com
```

Isso criou uma VM?

**Resposta:** Não.

Apenas habilitou o serviço/API.

---

## Questão 6

Antes de habilitar uma API em produção, qual conjunto de informações você deve validar?

**Resposta:** conta ativa, configuration ativa e Project ativo.

---

# 22. Cleanup

Volte à configuration principal:

```bash
# Ativa novamente ace-base.
gcloud config configurations activate ace-base
```

Exclua as configurations temporárias:

```bash
# Remove a configuration sem projeto.
gcloud config configurations delete ace-sem-projeto \
  --quiet

# Remove a segunda configuration usada no exercício.
gcloud config configurations delete ace-segunda \
  --quiet
```

Não desabilite `compute.googleapis.com` se você continuará usando Compute Engine nas próximas aulas.

---

# 23. Checklist

Ao final desta aula, confirme:

- [ ] Sei explicar Organization;
- [ ] Sei explicar Folder;
- [ ] Sei explicar Project;
- [ ] Sei explicar Resource;
- [ ] Sei desenhar `Organization → Folder → Project → Resource`;
- [ ] Sei diferenciar Project Name, Project ID e Project Number;
- [ ] Sei consultar os três identificadores com `gcloud projects describe`;
- [ ] Sei explicar Region;
- [ ] Sei explicar Zone;
- [ ] Sei diferenciar recurso global, regional e zonal;
- [ ] Sei listar Regions e Zones;
- [ ] Sei criar uma `gcloud configuration`;
- [ ] Sei ativar outra configuration;
- [ ] Sei verificar Project, Region e Zone ativos;
- [ ] Sei validar a conta autenticada;
- [ ] Sei habilitar uma API;
- [ ] Sei confirmar que uma API está habilitada;
- [ ] Sei diagnosticar erro de contexto de Project;
- [ ] Sei diferenciar IAM de Organization Policy.

---

# 24. Critério de aceite M/E/P

| Tópico | Esperado | Evidência |
|---|---:|---|
| Organization / Folder / Project / Resource | E/P | conceito + inspeção de hierarchy |
| Project Name / ID / Number | P | `projects describe` + comparação |
| Region / Zone | P | list/describe + análise de escopo |
| gcloud configurations | P | create/activate/set/list |
| Habilitar API | P | services enable + services list |
| Validar contexto ativo | P | auth/config/configurations |
| Organization Policy | E/P* | conceito + list quando aplicável |
| Cloud Asset Inventory | P | search-all-resources |

---

## Resumo para prova

```text
Organization
→ raiz administrativa

Folder
→ agrupamento opcional

Project
→ unidade para APIs, billing, quotas, IAM e recursos

Resource
→ recurso real do serviço
```

```text
Project Name
→ amigável

Project ID
→ identificador textual

Project Number
→ identificador numérico gerado pelo Google
```

```text
Region
→ área geográfica

Zone
→ área de implantação dentro da Region
```

```text
gcloud configuration
→ conjunto nomeado de propriedades

API enable
→ habilita uso do serviço
→ não cria recurso
```
