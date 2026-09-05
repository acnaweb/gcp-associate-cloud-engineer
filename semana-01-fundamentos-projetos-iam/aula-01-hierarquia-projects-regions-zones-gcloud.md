# Aula 1 — Hierarquia, Projects, Regions, Zones e gcloud

## Objetivos

Ao final, você deverá:
- distinguir Organization, Folder, Project e Resource;
- distinguir Project ID, Project Number e nome;
- entender region e zone;
- criar e alternar `gcloud configurations`;
- habilitar uma API e validar o contexto ativo.


---

# 1. Conceito

O projeto é uma fronteira fundamental para recursos, IAM, quotas e billing. `gcloud` mantém um contexto local com conta, projeto, região e zona. Region e zone não são sinônimos: vários recursos são regionais, enquanto VMs normalmente são zonais.

## Arquitetura mental

```text
Organization
   ↓
Folder
   ↓
Project
   ↓
Resources

gcloud configuration
 ├─ account
 ├─ project
 ├─ region
 └─ zone
```

---

# 2. Criar

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)

# Explicação: Cria uma configuração nomeada do `gcloud` para isolar projeto, região, zona e outras propriedades.
gcloud config configurations create ace-base
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate ace-base
# Explicação: Define o projeto ativo da configuração `gcloud`, evitando informar `--project` em cada comando.
gcloud config set project "$PROJECT_ID"
# Explicação: Define a região padrão da configuração `gcloud` para comandos regionais.
gcloud config set compute/region us-central1
# Explicação: Define a zona padrão da configuração `gcloud` para comandos zonais.
gcloud config set compute/zone us-central1-a

# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable compute.googleapis.com
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
# Explicação: Exibe as propriedades da configuração `gcloud` ativa para conferência.
gcloud config list
# Explicação: Lista as configurações do `gcloud` existentes na máquina/Cloud Shell.
gcloud config configurations list
# Explicação: Exibe metadados do projeto para confirmar ID, número e demais propriedades.
gcloud projects describe "$PROJECT_ID"
# Explicação: Executa `gcloud compute regions describe us-central1` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute regions describe us-central1
# Explicação: Executa `gcloud compute zones describe us-central1-a` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute zones describe us-central1-a
# Explicação: Lista as APIs já habilitadas no projeto para confirmar a configuração.
gcloud services list --enabled --filter="NAME:compute.googleapis.com"
```

---

# 4. Testar

```bash
# Explicação: Executa `gcloud compute zones list --filter="region:us-central1"` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud compute zones list --filter="region:us-central1"
# Explicação: Lista tipos de máquina disponíveis na zona/região para comparar CPU e memória.
gcloud compute machine-types list --zones=us-central1-a --limit=5
```

---

# 5. Quebrar propositalmente

Crie uma segunda configuration sem definir projeto:

```bash
# Explicação: Cria uma configuração nomeada do `gcloud` para isolar projeto, região, zona e outras propriedades.
gcloud config configurations create ace-sem-projeto
# Explicação: Executa `gcloud config unset project` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud config unset project
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

O erro/resultando vazio deve ser interpretado a partir do **contexto ausente**, conceito já inspecionado acima.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

1. Execute `gcloud config list` e confirme se `project` está vazio.
2. Execute `gcloud config configurations list` e confirme qual configuration está ativa.
3. Compare com `ace-base`.
4. Causa: o comando depende de um projeto e a configuration ativa não o definiu.

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

```bash
# Explicação: Define o projeto ativo da configuração `gcloud`, evitando informar `--project` em cada comando.
gcloud config set project "$PROJECT_ID"
# Explicação: Lista VMs do projeto para verificar inventário, zona, IPs e estado.
gcloud compute instances list
```

---

# 8. Questões estilo ACE

1. Você precisa alternar rapidamente entre projetos de laboratório e produção. Qual recurso do CLI ajuda? **gcloud configurations**.
2. Uma VM será criada em `us-central1-a`. Esse valor representa região ou zona? **Zona**.
3. Habilitar `compute.googleapis.com` cria uma VM? **Não. Apenas habilita o uso da API no projeto.**

---

# 9. Cleanup

```bash
# Explicação: Ativa a configuração nomeada do `gcloud` que será usada nos próximos comandos.
gcloud config configurations activate ace-base
# Explicação: Remove a configuração do `gcloud` criada para o laboratório.
gcloud config configurations delete ace-sem-projeto --quiet
```

---


---

# Cobertura ACE ampliada — ambiente, organização e inventário

## Resource hierarchy e standalone organization

```text
Organization
  ├─ Folder
  │   └─ Project
  └─ Project
      └─ Resources
```

- **Organization**: raiz administrativa para políticas e IAM corporativo.
- **Folder**: agrupamento opcional de projetos para delegação e políticas.
- **Project**: fronteira fundamental de recursos, quotas, APIs e billing linkage.
- **Standalone organization**: opção de organização que não depende do domínio tradicional do Google Workspace/Cloud Identity, conforme disponibilidade do produto.

Inspecione, quando aplicável:

```bash
# Explicação: Lista organizações visíveis para a identidade atual.
gcloud organizations list
# Explicação: Executa uma operação sobre folders da hierarquia de recursos do Google Cloud.
gcloud resource-manager folders list --organization=ORG_ID
# Explicação: Executa `gcloud projects list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud projects list
```

## Organization Policies

Organization Policy é diferente de IAM:

```text
IAM              → quem pode fazer
Organization Policy → quais configurações/ações são permitidas como guardrail
```

Exemplos comuns de constraints incluem restrições de localização, uso de IP externo ou criação de chaves, dependendo do ambiente.

```bash
# Explicação: Executa uma operação de consulta ou configuração de Organization Policy.
gcloud org-policies list --project=$PROJECT_ID
```

> Algumas políticas só fazem sentido em ambientes com Organization. Em conta pessoal, pratique leitura e decisão arquitetural.

## Cloud Asset Inventory

Cloud Asset Inventory ajuda a pesquisar e inventariar recursos e políticas.

```bash
# Explicação: Executa `gcloud asset search-all-resources --scope=projects/$PROJECT_ID --limit=20` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud asset search-all-resources --scope=projects/$PROJECT_ID --limit=20
```

Perguntas que ele ajuda a responder:

```text
Quais recursos existem?
Em quais regiões?
Quais tipos?
Quais recursos correspondem a determinado filtro?
```

## Gemini Cloud Assist para análise de recursos

No nível ACE, entenda que Gemini Cloud Assist pode ajudar a analisar recursos, troubleshooting e operações; ele **não substitui** IAM, políticas ou validação do operador.

## Workforce Identity Federation

Não confunda:

```text
Workforce Identity Federation
→ usuários/workforce externos acessando Google Cloud

Workload Identity Federation
→ workloads externos obtendo credenciais Google
```

A configuração completa normalmente envolve IdP externo e não é um bom laboratório isolado sem esse provedor. O importante aqui é reconhecer o caso de uso.

## Questões adicionais

1. Precisa restringir configurações em toda a hierarquia? **Organization Policy**, não apenas IAM.
2. Precisa descobrir recursos existentes em vários projetos? **Cloud Asset Inventory**.
3. Funcionários autenticados em IdP externo precisam acessar Google Cloud sem contas Google individuais? **Workforce Identity Federation**.

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

# Cobertura adicional exigida pelo exam guide — Hierarquia, Organization Policies, Cloud Identity, APIs e Quotas

A prova não limita “ambiente” a Project/Region/Zone. Também é necessário reconhecer:

```text
Organization
  ↓
Folders
  ↓
Projects
  ↓
Resources
```

## Organization Policies

Organization Policy é diferente de IAM:

```text
IAM
→ quem pode fazer uma ação

Organization Policy
→ quais configurações são permitidas/restritas na hierarquia
```

Em uma conta com Organization:

```bash
# Explicação: Lista organizações visíveis para a identidade atual.
gcloud organizations list
# Explicação: Executa uma operação sobre folders da hierarquia de recursos do Google Cloud.
gcloud resource-manager folders list --organization=ORGANIZATION_ID
# Explicação: Executa uma operação de consulta ou configuração de Organization Policy.
gcloud org-policies list --organization=ORGANIZATION_ID
```

Exemplo de cenário de prova: impedir criação de recursos fora de determinadas regiões é uma **restrição organizacional**, não uma role IAM.

## Cloud Identity — usuários e grupos

Cloud Identity/Google Workspace representa identidades humanas e grupos que podem aparecer em bindings IAM:

```text
user:ana@empresa.com
group:engenharia@empresa.com
serviceAccount:app@projeto.iam.gserviceaccount.com
```

Para muitos usuários com a mesma responsabilidade, prefira conceder IAM ao **grupo** em vez de manter bindings individuais.

## APIs e Services

```bash
# Explicação: Lista APIs/serviços disponíveis ou habilitados, conforme os filtros informados.
gcloud services list --available --limit=20
# Explicação: Lista as APIs já habilitadas no projeto para confirmar a configuração.
gcloud services list --enabled
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable compute.googleapis.com
```

Habilitar API ≠ conceder IAM ≠ criar recurso.

## Quotas

```bash
# Explicação: Exibe metadados/configurações do Compute Engine no projeto.
gcloud compute project-info describe --format='yaml(quotas)'
```

Modelo mental:

```text
Billing/Budget → dinheiro
Quota          → limite técnico
IAM            → autorização
```

Se a criação falhar com `RESOURCE_EXHAUSTED`, confirme quota antes de alterar IAM ou firewall.


---

## Prática guiada — aplicar Organization Policy

**Nível:** `P*` — depende de uma Organization e permissões de Organization Policy Administrator.

O guia não pede apenas reconhecer Organization Policy; ele fala em **aplicar políticas organizacionais à hierarquia**.

Em uma Organization de laboratório, primeiro inspecione constraints disponíveis:

```bash
# Explicação: Executa uma operação de consulta ou configuração de Organization Policy.
gcloud org-policies list --organization=ORGANIZATION_ID
```

Escolha uma constraint apropriada para laboratório e leia o estado atual antes de alterar:

```bash
# Explicação: Executa uma operação de consulta ou configuração de Organization Policy.
gcloud org-policies describe CONSTRAINT_NAME \
  --organization=ORGANIZATION_ID
```

Use o Console em **IAM & Admin → Organization Policies** para:

1. selecionar a Organization ou Folder de laboratório;
2. abrir uma constraint;
3. observar inherited policy;
4. criar override somente se tiver autorização;
5. salvar;
6. verificar a effective policy.

### Falha proposital

Tente planejar a criação de um recurso que viole a constraint configurada.

### Troubleshooting

```text
Sintoma: criação/configuração bloqueada
Hipótese: Organization Policy efetiva impede a configuração
Evidência: effective policy da constraint no escopo
Causa: guardrail hierárquico, não falta de IAM role
Correção: ajustar a configuração do recurso ou a policy, conforme governança
```

> Não altere políticas de uma Organization corporativa apenas para praticar.
