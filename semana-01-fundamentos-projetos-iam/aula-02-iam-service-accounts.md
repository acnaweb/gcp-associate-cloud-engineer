# Aula 2 — IAM e Service Accounts

## Objetivos

Ao final, você deverá:

- entender `principal`, `role`, `permission`, `policy`, `binding` e `resource`;
- criar uma Service Account;
- conceder uma role mínima a uma Service Account;
- inspecionar políticas IAM;
- validar o acesso esperado;
- produzir e diagnosticar um `PERMISSION_DENIED`;
- aplicar least privilege.

---

# 1. Conceito — como IAM decide acesso

IAM responde:

```text
quem
pode fazer o quê
em qual recurso?
```

O modelo básico é:

```text
Principal
   ↓ recebe
Role
   ↓ contém
Permissions
   ↓ por meio de
Policy / Binding
   ↓ sobre um
Resource
```

---

# 2. Principal

Um **principal** é uma identidade que pode receber acesso.

Exemplos:

```text
user:alguem@example.com
group:dev@example.com
serviceAccount:app@projeto.iam.gserviceaccount.com
```

Nesta aula, o principal principal do laboratório será uma **Service Account**.

---

# 3. Permission

Uma **permission** representa uma ação elementar.

Formato típico:

```text
service.resource.verb
```

Exemplos:

```text
storage.objects.get
storage.objects.create
compute.instances.get
```

Permissions normalmente não são concedidas diretamente.

Elas são agrupadas em roles.

---

# 4. Role

Uma **role** é um conjunto de permissions.

Exemplo:

```text
roles/storage.objectViewer
```

Essa role contém permissões de leitura de objetos.

Inspecione:

```bash
# Mostra a definição da role e suas permissões.
gcloud iam roles describe roles/storage.objectViewer
```

Procure:

```text
includedPermissions
```

e confirme que existe:

```text
storage.objects.get
```

Modelo:

```text
roles/storage.objectViewer
        ↓
storage.objects.get
```

---

# 5. Resource

Um **resource** é o recurso protegido por IAM.

Exemplos:

```text
Project
Bucket
VM
Dataset
Service Account
```

No laboratório:

```text
Bucket
→ resource

Service Account
→ principal
```

---

# 6. Policy e Binding

Uma **allow policy** define quais principals recebem quais roles em um resource.

Dentro da policy existem **bindings**.

Modelo:

```text
Policy do bucket
   └── Binding
       ├── role: roles/storage.objectViewer
       └── member: serviceAccount:ace-storage-reader@...
```

Ou seja:

```text
Binding
= principal + role
```

Quando executamos:

```bash
gcloud storage buckets add-iam-policy-binding ...
```

estamos adicionando um binding à policy do bucket.

---

# 7. Arquitetura mental do laboratório

O objetivo é simples:

```text
Service Account
      ↓
roles/storage.objectViewer
      ↓
Bucket
      ↓
dado.txt
```

A ideia é aprender primeiro:

```text
quem?
→ Service Account

qual role?
→ roles/storage.objectViewer

sobre qual resource?
→ Bucket

qual permission efetiva interessa?
→ storage.objects.get
```

---

# 8. Criar

Defina variáveis:

```bash
# Project ID ativo.
export PROJECT_ID="$(gcloud config get-value project)"

# Nome da Service Account.
export SA_NAME="ace-storage-reader"

# E-mail da Service Account.
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Nome único para o bucket.
export BUCKET="gs://$PROJECT_ID-ace-iam-$RANDOM"
```

Habilite APIs:

```bash
# Habilita Cloud Storage e Compute Engine para o laboratório.
gcloud services enable \
  storage.googleapis.com \
  compute.googleapis.com
```

Crie a Service Account:

```bash
# Cria a Service Account do laboratório.
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="ACE Storage Reader"
```

Crie o bucket:

```bash
# Cria um bucket regional.
gcloud storage buckets create "$BUCKET" \
  --location=us-central1
```

Crie e envie um objeto:

```bash
# Cria arquivo local.
echo "conteudo ACE" > dado.txt

# Envia o arquivo ao bucket.
gcloud storage cp dado.txt "$BUCKET/"
```

---

# 9. Inspecionar

Service Account:

```bash
# Mostra os metadados da Service Account.
gcloud iam service-accounts describe "$SA_EMAIL"
```

Bucket:

```bash
# Mostra metadados do bucket.
gcloud storage buckets describe "$BUCKET"
```

Policy atual do bucket:

```bash
# Mostra os bindings IAM atuais.
gcloud storage buckets get-iam-policy "$BUCKET"
```

Role de leitura:

```bash
# Mostra as permissões contidas na role.
gcloud iam roles describe roles/storage.objectViewer
```

---

# 10. Conceder a role mínima

O requisito é:

```text
ler objetos
```

A role adequada é:

```text
roles/storage.objectViewer
```

Conceda no bucket:

```bash
# Concede somente leitura de objetos à Service Account.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Inspecione:

```bash
# Confirma o binding criado.
gcloud storage buckets get-iam-policy "$BUCKET"
```

---

# 11. Criar uma VM que usa a Service Account

Para testar a autorização sem introduzir temas avançados de identidade, vamos anexar a Service Account a uma VM.

```bash
# Cria uma VM simples usando a Service Account do laboratório.
#
# --service-account define a identidade usada pela VM.
# --scopes=cloud-platform permite que as APIs usem IAM como controle principal.
gcloud compute instances create ace-iam-vm \
  --zone=us-central1-a \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --service-account="$SA_EMAIL" \
  --scopes=cloud-platform
```

Inspecione:

```bash
# Confirma qual Service Account está anexada à VM.
gcloud compute instances describe ace-iam-vm \
  --zone=us-central1-a \
  --format="yaml(serviceAccounts)"
```

---

# 12. Validar o acesso esperado

Execute o comando dentro da VM:

```bash
# A VM executa com a identidade da Service Account anexada.
gcloud compute ssh ace-iam-vm \
  --zone=us-central1-a \
  --command="gcloud storage cat '$BUCKET/dado.txt'"
```

Resultado esperado:

```text
conteudo ACE
```

Modelo:

```text
VM
  ↓ usa
Service Account
  ↓ roles/storage.objectViewer
Bucket
  ↓
dado.txt
```

---

# 13. Quebrar propositalmente

Altere uma única variável:

```text
remover a role da Service Account no bucket
```

Remova:

```bash
# Remove somente a role de leitura do bucket.
gcloud storage buckets remove-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Confirme:

```bash
# Verifica que o binding não está mais na policy.
gcloud storage buckets get-iam-policy "$BUCKET"
```

---

# 14. Produzir o PERMISSION_DENIED

Repita a leitura:

```bash
# A VM continua usando a mesma Service Account,
# mas ela perdeu a autorização no bucket.
gcloud compute ssh ace-iam-vm \
  --zone=us-central1-a \
  --command="gcloud storage cat '$BUCKET/dado.txt'"
```

Comportamento esperado:

```text
PERMISSION_DENIED
ou
403
```

---

# 15. Troubleshooting

## Sintoma

A VM não consegue ler:

```text
dado.txt
```

## Hipótese

A Service Account não possui:

```text
storage.objects.get
```

no bucket.

## Evidência 1 — identidade da VM

```bash
gcloud compute instances describe ace-iam-vm \
  --zone=us-central1-a \
  --format="yaml(serviceAccounts)"
```

Confirme que a VM usa:

```text
ace-storage-reader@...
```

## Evidência 2 — policy do bucket

```bash
gcloud storage buckets get-iam-policy "$BUCKET"
```

O binding de `roles/storage.objectViewer` não deverá estar presente.

## Evidência 3 — permissions da role

```bash
gcloud iam roles describe roles/storage.objectViewer
```

Procure:

```text
storage.objects.get
```

## Causa

Removemos deliberadamente a role de leitura.

## Correção

```bash
# Restaura exatamente a role mínima.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Teste novamente:

```bash
gcloud compute ssh ace-iam-vm \
  --zone=us-central1-a \
  --command="gcloud storage cat '$BUCKET/dado.txt'"
```

Resultado esperado:

```text
conteudo ACE
```

---

# 16. Least privilege

Compare:

```text
roles/storage.objectViewer
→ suficiente para leitura

roles/storage.admin
→ excessivo

roles/editor
→ muito amplo
```

Regra:

```text
conceda a menor role que satisfaça o requisito
```

---

# 17. Basic, Predefined e Custom Roles

## Basic Roles

```text
roles/viewer
roles/editor
roles/owner
```

São amplas.

## Predefined Roles

Criadas e mantidas pelo Google.

Exemplos:

```text
roles/compute.viewer
roles/storage.objectViewer
roles/storage.admin
roles/bigquery.dataViewer
```

## Custom Roles

Criadas pela organização ou projeto quando nenhuma predefined role atende adequadamente.

Nesta aula basta entender a ideia.

Custom Roles serão aprofundadas na Semana 7.

---

# 18. Service Accounts gerenciadas pelo usuário e pelo Google

Nesta aula criamos:

```text
user-managed Service Account
```

Exemplo:

```text
ace-storage-reader@...
```

Também existem:

```text
Google-managed service agents
```

Essas identidades são usadas internamente pelos serviços Google Cloud.

Não remova suas roles sem entender a dependência do serviço.

---

# 19. Questões estilo ACE

## Questão 1

Uma aplicação precisa apenas ler objetos de um bucket.

Qual role usar?

**Resposta:**

```text
roles/storage.objectViewer
```

## Questão 2

O que é uma permission?

**Resposta:** uma ação elementar, como `storage.objects.get`.

## Questão 3

O que é uma role?

**Resposta:** um conjunto de permissions.

## Questão 4

O que é um binding?

**Resposta:** associação entre um principal e uma role dentro de uma policy.

## Questão 5

Por que não usar `roles/editor`?

**Resposta:** porque viola least privilege.

---

# 20. Cleanup

Exclua a VM:

```bash
gcloud compute instances delete ace-iam-vm \
  --zone=us-central1-a \
  --quiet
```

Remova o objeto:

```bash
gcloud storage rm "$BUCKET/dado.txt"
```

Exclua o bucket:

```bash
gcloud storage buckets delete "$BUCKET" \
  --quiet
```

Exclua a Service Account:

```bash
gcloud iam service-accounts delete "$SA_EMAIL" \
  --quiet
```

Remova o arquivo local:

```bash
rm -f dado.txt
```

---

# 21. Checklist

- [ ] Sei definir principal;
- [ ] Sei definir permission;
- [ ] Sei definir role;
- [ ] Sei definir policy;
- [ ] Sei definir binding;
- [ ] Sei definir resource;
- [ ] Criei uma Service Account;
- [ ] Inspecionei uma Service Account;
- [ ] Concedi uma role mínima;
- [ ] Inspecionei a policy do bucket;
- [ ] Relacionei role com permission;
- [ ] Validei a Service Account anexada à VM;
- [ ] Produzi um `PERMISSION_DENIED`;
- [ ] Diagnostiquei a ausência do binding;
- [ ] Corrigi sem aumentar privilégios;
- [ ] Entendi least privilege.

---

# 22. Critério de aceite M/E/P

| Objetivo | Nível | Evidência |
|---|---:|---|
| Principal | E/P | definição + SA |
| Permission | E/P | `storage.objects.get` |
| Role | P | describe + grant + remove + restore |
| Policy | P | get-iam-policy |
| Binding | P | add/remove IAM binding |
| Resource | E/P | bucket |
| Criar Service Account | P | create + describe |
| Role mínima | P | Object Viewer no bucket |
| Validar acesso | P | VM executando com SA |
| PERMISSION_DENIED | P | falha isolada + evidências + correção |
| Least privilege | E/P | comparação de roles |

---

## Resumo para prova

```text
Principal
→ identidade

Permission
→ ação elementar

Role
→ conjunto de permissions

Policy
→ grants sobre resource

Binding
→ principal + role

Resource
→ recurso protegido por IAM
```

```text
VM
  ↓ usa
Service Account
  ↓ roles/storage.objectViewer
Bucket
```

Os mecanismos avançados de uso temporário de identidades serão estudados na Semana 7.
