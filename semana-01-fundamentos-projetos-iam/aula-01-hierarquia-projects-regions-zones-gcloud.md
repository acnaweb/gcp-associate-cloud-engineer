# Aula 1 — Hierarquia, Projects, Regions, Zones e gcloud

## Objetivos

Ao final desta aula, você deverá:

- Entender a hierarquia de recursos do Google Cloud;
- Diferenciar Organization, Folder, Project e Resource;
- Diferenciar Project ID e Project Number;
- Entender Regions e Zones;
- Reconhecer escopos globais, regionais e zonais;
- Configurar o `gcloud`;
- Listar e habilitar APIs;
- Utilizar o Cloud Shell.

---

# 1. Hierarquia de Recursos

O modelo mental principal do Google Cloud é:

```text
Organization
    │
    ├── Folder
    │     ├── Project DEV
    │     ├── Project HML
    │     └── Project PRD
    │
    └── Project Shared
```

Um **Project** é uma unidade fundamental no GCP.

Recursos como:

- VMs;
- buckets;
- bancos de dados;
- datasets;
- APIs;
- permissões;

normalmente pertencem a um projeto.

A hierarquia é especialmente importante para:

```text
IAM
Policies
Billing
Organization Policies
Governança
```

Uma política definida em nível superior pode ser herdada pelos níveis inferiores.

---

# 2. Organization x Folder x Project

| Recurso | Função |
|---|---|
| **Organization** | Representa a organização ou empresa |
| **Folder** | Agrupa projetos de forma lógica |
| **Project** | Unidade onde os recursos GCP são criados |
| **Resource** | VM, bucket, banco, dataset etc. |

Exemplo corporativo:

```text
Organization: empresa.com
        │
        ├── Folder: Produção
        │      ├── prj-app-prd
        │      └── prj-data-prd
        │
        ├── Folder: Homologação
        │      ├── prj-app-hml
        │      └── prj-data-hml
        │
        └── Folder: Desenvolvimento
               ├── prj-app-dev
               └── prj-data-dev
```

## Para a prova

Memorize:

> Organization → Folder → Project → Resource

---

# 3. Project ID x Project Number

## Project ID

Exemplo:

```text
study-gcp-398200
```

É um identificador textual usado frequentemente em comandos e APIs.

## Project Number

Exemplo:

```text
123456789012
```

É um identificador numérico interno.

### Atenção

`Project ID` e `Project Number` não são a mesma coisa.

---

# 4. Regions e Zones

Uma **Region** representa uma área geográfica.

Exemplo:

```text
southamerica-east1
```

São Paulo.

Uma **Zone** é uma subdivisão de uma região:

```text
southamerica-east1-a
southamerica-east1-b
southamerica-east1-c
```

Modelo:

```text
Region: southamerica-east1
       │
       ├── Zone A
       ├── Zone B
       └── Zone C
```

---

# 5. Disponibilidade

Se duas VMs estiverem na mesma zone:

```text
southamerica-east1-a
   ├── VM1
   └── VM2
```

uma indisponibilidade zonal pode afetar ambas.

Uma estratégia melhor:

```text
VM1 → southamerica-east1-a
VM2 → southamerica-east1-b
```

---

# 6. Escopo Global, Regional e Zonal

| Recurso | Escopo típico |
|---|---|
| Compute Engine VM | Zonal |
| Persistent Disk | Zonal ou Regional |
| Subnet | Regional |
| VPC | Global |
| Cloud Storage Bucket | Regional ou multirregional |
| Load Balancing | Depende do tipo |
| Project | Global/lógico |

Pegadinha clássica:

> **VPC é global e subnet é regional.**

---

# 7. Cloud Shell

Para o ACE, é altamente recomendável usar o **Cloud Shell**.

Ele já oferece:

```text
gcloud
kubectl
terraform
git
python
bash
```

---

# 8. Laboratório — Verificar o Ambiente

```bash
gcloud auth list
```

Veja a configuração atual:

```bash
gcloud config list
```

Liste projetos:

```bash
gcloud projects list
```

Identifique:

```text
ACCOUNT
PROJECT_ID
PROJECT_NAME
PROJECT_NUMBER
```

---

# 9. Configurar Projeto Padrão

```bash
gcloud config set project SEU_PROJECT_ID
```

Exemplo:

```bash
gcloud config set project study-gcp-398200
```

Confira:

```bash
gcloud config get-value project
```

---

# 10. Configurar Região e Zona

```bash
gcloud config set compute/region southamerica-east1
```

```bash
gcloud config set compute/zone southamerica-east1-a
```

Confira:

```bash
gcloud config list
```

Resultado conceitual:

```text
project = study-gcp-398200
region  = southamerica-east1
zone    = southamerica-east1-a
```

---

# 11. Configurations do gcloud

Liste configurações:

```bash
gcloud config configurations list
```

Exemplo:

```text
dev
hml
prd
```

Criar:

```bash
gcloud config configurations create dev
```

Definir projeto:

```bash
gcloud config set project projeto-dev
```

Ativar outra configuração:

```bash
gcloud config configurations activate prd
```

---

# 12. Laboratório — Regions e Zones

Liste regiões:

```bash
gcloud compute regions list
```

Liste zonas:

```bash
gcloud compute zones list
```

Filtre São Paulo:

```bash
gcloud compute zones list \
  --filter="region:southamerica-east1"
```

Resultado esperado:

```text
southamerica-east1-a
southamerica-east1-b
southamerica-east1-c
```

---

# 13. APIs e Services

Vários serviços precisam ser habilitados no projeto.

Exemplo:

```text
Project
   │
   ├── Compute Engine API
   ├── Cloud Run API
   ├── BigQuery API
   └── Kubernetes Engine API
```

Listar:

```bash
gcloud services list
```

Somente habilitados:

```bash
gcloud services list --enabled
```

Habilitar Compute Engine:

```bash
gcloud services enable compute.googleapis.com
```

Habilitar Cloud Run:

```bash
gcloud services enable run.googleapis.com
```

---

# 14. Questões Estilo ACE

## Questão 1

Qual estrutura representa corretamente a hierarquia?

A. Folder → Organization → Project  
B. Project → Organization → Folder  
C. Organization → Folder → Project  
D. Region → Organization → Project

**Resposta: C**

---

## Questão 2

Qual afirmação está correta?

A. VPC e subnet são zonais  
B. VPC é global e subnet é regional  
C. VPC é regional e subnet é global  
D. Ambos são globais

**Resposta: B**

---

## Questão 3

Duas VMs precisam permanecer disponíveis mesmo em caso de falha de uma zone.

Qual abordagem é melhor?

A. Criar as duas na mesma zone  
B. Usar duas zones diferentes na mesma região  
C. Usar o mesmo IP externo  
D. Criar dois projetos

**Resposta: B**

---

# 15. Exercício Prático

```bash
# Ver conta
gcloud auth list

# Ver projeto
gcloud config get-value project

# Configurar região
gcloud config set compute/region southamerica-east1

# Configurar zona
gcloud config set compute/zone southamerica-east1-a

# Ver configuração
gcloud config list

# Listar regiões
gcloud compute regions list

# Listar zonas da região de São Paulo
gcloud compute zones list \
  --filter="region:southamerica-east1"

# Listar APIs habilitadas
gcloud services list --enabled
```

---

# 16. O que Memorizar

```text
Organization
    ↓
Folder
    ↓
Project
    ↓
Resource
```

```text
VPC       → Global
Subnet    → Regional
VM        → Zonal
```

E:

> Project ID e Project Number são identificadores diferentes.

---

# 17. Checklist

- [ ] Entendo Organization, Folder, Project e Resource
- [ ] Sei diferenciar Project ID e Project Number
- [ ] Sei diferenciar Region e Zone
- [ ] Sei que VPC é global
- [ ] Sei que subnet é regional
- [ ] Sei que Compute Engine VM é normalmente zonal
- [ ] Sei configurar projeto, região e zona com `gcloud`
- [ ] Sei listar Regions e Zones
- [ ] Sei listar e habilitar APIs
- [ ] Sei usar o Cloud Shell
