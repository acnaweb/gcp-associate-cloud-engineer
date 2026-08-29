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
export PROJECT_ID=$(gcloud config get-value project)

gcloud config configurations create ace-base
gcloud config configurations activate ace-base
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region us-central1
gcloud config set compute/zone us-central1-a

gcloud services enable compute.googleapis.com
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud auth list
gcloud config list
gcloud config configurations list
gcloud projects describe "$PROJECT_ID"
gcloud compute regions describe us-central1
gcloud compute zones describe us-central1-a
gcloud services list --enabled --filter="NAME:compute.googleapis.com"
```

---

# 4. Testar

```bash
gcloud compute zones list --filter="region:us-central1"
gcloud compute machine-types list --zones=us-central1-a --limit=5
```

---

# 5. Quebrar propositalmente

Crie uma segunda configuration sem definir projeto:

```bash
gcloud config configurations create ace-sem-projeto
gcloud config unset project
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
gcloud config set project "$PROJECT_ID"
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
gcloud config configurations activate ace-base
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
gcloud organizations list
gcloud resource-manager folders list --organization=ORG_ID
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
gcloud org-policies list --project=$PROJECT_ID
```

> Algumas políticas só fazem sentido em ambientes com Organization. Em conta pessoal, pratique leitura e decisão arquitetural.

## Cloud Asset Inventory

Cloud Asset Inventory ajuda a pesquisar e inventariar recursos e políticas.

```bash
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
gcloud organizations list
gcloud resource-manager folders list --organization=ORGANIZATION_ID
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
gcloud services list --available --limit=20
gcloud services list --enabled
gcloud services enable compute.googleapis.com
```

Habilitar API ≠ conceder IAM ≠ criar recurso.

## Quotas

```bash
gcloud compute project-info describe --format='yaml(quotas)'
```

Modelo mental:

```text
Billing/Budget → dinheiro
Quota          → limite técnico
IAM            → autorização
```

Se a criação falhar com `RESOURCE_EXHAUSTED`, confirme quota antes de alterar IAM ou firewall.
