# Aula 2 — IAM e Service Accounts

## Objetivos

Ao final desta aula, você deverá:

- Entender o modelo de IAM do Google Cloud;
- Diferenciar Principal, Role, Permission e Resource;
- Diferenciar Basic, Predefined e Custom Roles;
- Aplicar o princípio do menor privilégio;
- Entender Service Accounts;
- Criar Service Accounts via `gcloud`;
- Conceder roles;
- Visualizar IAM Policies;
- Reconhecer conceitos de herança.

---

# 1. Modelo Mental do IAM

```text
WHO
 │
 ▼
Principal

CAN DO WHAT
 │
 ▼
Role

ON WHAT
 │
 ▼
Resource
```

Portanto:

```text
Principal
   +
Role
   +
Resource
   =
IAM
```

Exemplo:

```text
usuario@empresa.com
        +
roles/storage.objectViewer
        +
bucket
```

Significa:

> O usuário pode visualizar objetos no bucket.

---

# 2. Principal

Um **Principal** representa a identidade que recebe acesso.

Pode ser:

- usuário;
- grupo;
- Service Account;
- domínio;
- identidade federada.

Exemplo:

```text
user:usuario@empresa.com
```

ou:

```text
serviceAccount:app@project.iam.gserviceaccount.com
```

---

# 3. Permission

Uma **Permission** representa uma ação individual.

Exemplo:

```text
storage.objects.get
```

Outro exemplo:

```text
compute.instances.start
```

---

# 4. Role

Um **Role** é um conjunto de permissions.

Exemplo:

```text
roles/storage.objectViewer
     │
     ├── storage.objects.get
     └── storage.objects.list
```

Na prática, normalmente concedemos **roles**, não permissions isoladas.

---

# 5. Tipos de Roles

## Basic Roles

```text
Viewer
Editor
Owner
```

Exemplos:

```text
roles/viewer
roles/editor
roles/owner
```

São amplas e devem ser usadas com cautela.

---

## Predefined Roles

São roles específicas mantidas pelo Google.

Exemplos:

```text
roles/storage.objectViewer
roles/bigquery.dataViewer
roles/compute.instanceAdmin.v1
```

---

## Custom Roles

São criadas pela organização.

```text
Custom Role
     │
     ├── permission A
     ├── permission B
     └── permission C
```

Úteis quando nenhuma predefined role atende exatamente ao requisito.

---

# 6. Least Privilege

O princípio do menor privilégio determina:

> Uma identidade deve receber somente as permissões necessárias.

Exemplo ruim:

```text
Aplicação precisa ler BigQuery
             │
             ▼
          Editor
```

Melhor:

```text
Aplicação precisa ler BigQuery
             │
             ▼
roles/bigquery.dataViewer
```

---

# 7. Herança de IAM

As políticas podem ser herdadas pela hierarquia.

```text
Organization
      │
      ▼
    Folder
      │
      ▼
   Project
      │
      ▼
  Resource
```

Uma permissão concedida em nível superior pode se aplicar aos recursos abaixo.

Para o ACE, lembre:

> IAM é cumulativo ao longo da hierarquia.

---

# 8. Visualizar IAM do Projeto

```bash
gcloud projects get-iam-policy \
  $(gcloud config get-value project)
```

Saída típica:

```yaml
bindings:
- members:
  - user:usuario@email.com
  role: roles/owner

- members:
  - serviceAccount:app@project.iam.gserviceaccount.com
  role: roles/storage.objectViewer
```

Modelo:

```text
Role
 │
 └── Members
```

---

# 9. Service Accounts

Uma **Service Account** é uma identidade normalmente utilizada por workloads.

Exemplo:

```text
Cloud Run
    │
    │ executa como
    ▼
Service Account
    │
    │ possui role
    ▼
BigQuery
```

Isso permite que aplicações acessem recursos sem utilizar credenciais pessoais de usuários.

---

# 10. Usuário x Service Account

| Tipo | Uso |
|---|---|
| User Account | Pessoa |
| Service Account | Aplicação, workload ou serviço |
| Group | Conjunto de usuários |
| Domain | Usuários de um domínio |

---

# 11. Laboratório — Criar Service Account

```bash
gcloud iam service-accounts create ace-lab-sa \
  --display-name="ACE Lab Service Account"
```

Liste:

```bash
gcloud iam service-accounts list
```

Formato:

```text
ace-lab-sa@PROJECT_ID.iam.gserviceaccount.com
```

---

# 12. Conceder Role à Service Account

Primeiro:

```bash
PROJECT_ID=$(gcloud config get-value project)
```

Depois:

```bash
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

---

# 13. Validar a Role

```bash
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:ace-lab-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

---

# 14. Service Account por Workload

Imagine duas aplicações:

```text
Application A
     │
     ▼
Service Account A
     │
     ▼
BigQuery
```

```text
Application B
     │
     ▼
Service Account B
     │
     ▼
Cloud Storage
```

Essa separação facilita:

- menor privilégio;
- auditoria;
- troubleshooting;
- revogação;
- governança.

---

# 15. Evite Roles Muito Amplas

Exemplo ruim:

```text
Service Account
      │
      ▼
roles/editor
```

Melhor:

```text
Service Account
      │
      ├── roles/storage.objectViewer
      └── roles/bigquery.dataViewer
```

conforme a necessidade real.

---

# 16. Conceitos Importantes para as Próximas Aulas

Você deverá aprofundar depois:

```text
IAM inheritance
Predefined Roles
Custom Roles
Service Account User
Service Account Token Creator
Impersonation
IAM Conditions
Policy Troubleshooter
```

---

# 17. Questões Estilo ACE

## Questão 1

Uma aplicação precisa apenas ler objetos do Cloud Storage.

Qual role é mais adequada?

A. `roles/owner`  
B. `roles/editor`  
C. `roles/storage.objectViewer`  
D. `roles/viewer`

**Resposta: C**

---

## Questão 2

Duas aplicações possuem necessidades de acesso diferentes.

Qual abordagem é melhor?

A. Compartilhar a mesma Service Account  
B. Criar uma Service Account para cada workload  
C. Usar a conta pessoal do desenvolvedor  
D. Conceder Owner às duas

**Resposta: B**

---

## Questão 3

Uma identidade recebeu acesso em nível de Folder.

Projetos dentro desse Folder podem herdar o acesso?

A. Não  
B. Sim  
C. Apenas VMs  
D. Apenas Cloud Storage

**Resposta: B**

---

## Questão 4

Uma aplicação precisa apenas consultar dados do BigQuery.

Qual princípio deve orientar a escolha da role?

A. Highest privilege  
B. Shared credentials  
C. Least privilege  
D. Owner by default

**Resposta: C**

---

# 18. Exercício Prático

```bash
# Obter projeto atual
PROJECT_ID=$(gcloud config get-value project)

# Visualizar IAM Policy
gcloud projects get-iam-policy "$PROJECT_ID"

# Criar Service Account
gcloud iam service-accounts create ace-lab-sa \
  --display-name="ACE Lab"

# Listar Service Accounts
gcloud iam service-accounts list

# Conceder role de leitura no Storage
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:ace-lab-sa@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"

# Validar
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:ace-lab-sa@$PROJECT_ID.iam.gserviceaccount.com"
```

---

# 19. O que Memorizar

```text
Principal + Role + Resource
              =
             IAM
```

```text
Permission
   ↓
Role
   ↓
Principal recebe o Role
```

E principalmente:

> Prefira sempre o menor privilégio necessário.

---

# 20. Checklist

- [ ] Entendo Principal
- [ ] Entendo Permission
- [ ] Entendo Role
- [ ] Sei diferenciar Basic, Predefined e Custom Roles
- [ ] Entendo Least Privilege
- [ ] Sei visualizar IAM Policy de um projeto
- [ ] Sei criar Service Accounts
- [ ] Sei conceder roles
- [ ] Entendo herança de IAM
- [ ] Entendo por que workloads diferentes devem ter identidades distintas
