# Aula 2 — IAM e Service Accounts

## Objetivos

Ao final, você deverá:

- entender `principal`, `role`, `permission`, `policy` e `resource`;
- criar uma Service Account;
- conceder uma role mínima em um bucket;
- testar acesso com impersonation;
- diagnosticar um `PERMISSION_DENIED` produzido no laboratório.

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
   ↓ aplicada por uma
Policy / Binding
   ↓ sobre um
Resource
```

Vamos separar cada conceito.

---

# 2. Principal

Um **principal** é uma identidade que pode receber acesso.

Exemplos:

```text
user:alguem@example.com
group:dev@example.com
serviceAccount:app@projeto.iam.gserviceaccount.com
```

Nesta aula teremos dois principals importantes:

```text
seu usuário
→ autentica no gcloud

Service Account
→ será impersonada e fará a leitura no bucket
```

Veja seu principal autenticado:

```bash
# Obtém a conta atualmente ativa no gcloud.
export USER_ACCOUNT="$(gcloud config get-value account)"

echo "$USER_ACCOUNT"
```

---

# 3. Permission

Uma **permission** representa uma operação elementar permitida por IAM.

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

No laboratório, a permission mais importante para leitura do objeto será:

```text
storage.objects.get
```

Permissions não são normalmente concedidas diretamente ao principal.

Elas são agrupadas em roles.

---

# 4. Role

Uma **role** é um conjunto de permissions.

Exemplo:

```text
roles/storage.objectViewer
```

Essa role contém permissions necessárias para visualizar objetos.

Inspecione:

```bash
# Mostra a definição da role e suas includedPermissions.
gcloud iam roles describe roles/storage.objectViewer
```

Procure:

```text
includedPermissions
```

e confirme que a role inclui operações de leitura, como:

```text
storage.objects.get
```

Modelo:

```text
roles/storage.objectViewer
        ↓ contém
storage.objects.get
```

---

# 5. Resource

Um **resource** é o recurso Google Cloud sobre o qual o acesso é concedido.

Exemplos:

```text
Project
Bucket
VM
Dataset
Service Account
```

Nesta aula teremos:

```text
Bucket
→ resource que contém o objeto dado.txt

Service Account
→ identidade, mas também um resource IAM
   sobre o qual poderemos conceder Token Creator ao usuário
```

Esse segundo ponto é importante:

```text
Service Account pode ser:
1. principal
2. resource IAM
```

---

# 6. Policy e Binding

Uma **allow policy** descreve quais principals recebem quais roles em um resource.

Dentro da policy existem **bindings**.

Modelo simplificado:

```text
Policy do bucket
   └── Binding
       ├── role: roles/storage.objectViewer
       └── member: serviceAccount:ace-storage-reader@...
```

Ou seja:

```text
Binding
= associação entre principal e role
```

Quando executamos:

```bash
gcloud storage buckets add-iam-policy-binding ...
```

estamos alterando a allow policy do bucket e adicionando um binding.

Inspecione uma policy com:

```bash
gcloud storage buckets get-iam-policy BUCKET
```

---

# 7. Arquitetura mental do laboratório

Teremos dois fluxos de autorização diferentes.

## Fluxo A — seu usuário pode impersonar a Service Account?

```text
Seu usuário
   │
   │ roles/iam.serviceAccountTokenCreator
   │ contém iam.serviceAccounts.getAccessToken
   ▼
Service Account
```

## Fluxo B — a Service Account pode ler o objeto?

```text
Service Account
   │
   │ roles/storage.objectViewer
   │ contém storage.objects.get
   ▼
Bucket
   ▼
dado.txt
```

O teste só funciona se **os dois fluxos** estiverem corretos.

```text
Usuário pode impersonar?
        ↓ sim
SA pode ler objeto?
        ↓ sim
leitura funciona
```

---

# 8. Criar

Defina as variáveis:

```bash
# Obtém o Project ID ativo.
export PROJECT_ID="$(gcloud config get-value project)"

# Obtém o usuário ativo.
export USER_ACCOUNT="$(gcloud config get-value account)"

# Nome da Service Account.
export SA_NAME="ace-storage-reader"

# E-mail completo da Service Account.
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"

# Nome único para o bucket.
export BUCKET="gs://$PROJECT_ID-ace-iam-$RANDOM"
```

Habilite APIs necessárias:

```bash
# Habilita IAM Credentials API para geração de credenciais curtas.
gcloud services enable \
  iamcredentials.googleapis.com \
  storage.googleapis.com
```

Crie a Service Account:

```bash
# Cria a identidade usada no laboratório.
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

# Envia o arquivo para o bucket.
gcloud storage cp dado.txt "$BUCKET/"
```

---

# 9. Inspecionar antes de conceder acesso

Service Account:

```bash
# Mostra os metadados da Service Account.
gcloud iam service-accounts describe "$SA_EMAIL"
```

Bucket:

```bash
# Mostra localização e configuração do bucket.
gcloud storage buckets describe "$BUCKET"
```

Policy do bucket:

```bash
# Mostra os bindings IAM atuais do bucket.
gcloud storage buckets get-iam-policy "$BUCKET"
```

Role de leitura:

```bash
# Mostra as permissions incluídas na role.
gcloud iam roles describe roles/storage.objectViewer
```

---

# 10. Preparar impersonation

O uso de:

```text
--impersonate-service-account
```

não funciona apenas porque a Service Account existe.

O principal autenticado precisa poder criar credenciais temporárias para ela.

A permission relevante é:

```text
iam.serviceAccounts.getAccessToken
```

Ela está incluída em:

```text
roles/iam.serviceAccountTokenCreator
```

Conceda a role **ao seu usuário sobre a Service Account**:

```bash
# Permite ao usuário gerar credenciais curtas para esta SA.
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Inspecione a policy da própria Service Account:

```bash
# Mostra os bindings concedidos SOBRE a Service Account.
gcloud iam service-accounts get-iam-policy "$SA_EMAIL"
```

---

# 11. Testar primeiro a impersonation

Antes de testar Cloud Storage, prove que a impersonation funciona.

```bash
# Solicita um access token temporário da Service Account.
gcloud auth print-access-token \
  --impersonate-service-account="$SA_EMAIL"
```

Se este comando falhar, **ainda não investigue o bucket**.

O problema está no fluxo:

```text
usuário
→ Service Account
```

e não no fluxo:

```text
Service Account
→ bucket
```

---

# 12. Conceder a role mínima no bucket

Agora conceda apenas leitura de objetos:

```bash
# Adiciona um binding na policy do bucket.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Inspecione:

```bash
# Confirma que o binding foi criado.
gcloud storage buckets get-iam-policy "$BUCKET"
```

Modelo:

```text
Bucket Policy
   ↓
roles/storage.objectViewer
   ↓
Service Account
```

---

# 13. Testar o comportamento esperado

Leia o objeto usando a identidade da Service Account:

```bash
# gcloud cria credencial temporária da SA
# e executa a leitura como essa identidade.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

Resultado esperado:

```text
conteudo ACE
```

Agora sabemos duas coisas:

```text
1. impersonation funciona;
2. SA possui storage.objects.get no bucket.
```

---

# 14. Quebrar propositalmente

Vamos alterar **uma única variável**: o acesso da Service Account ao bucket.

Não removeremos Token Creator.

Isso garante que o fluxo:

```text
usuário → SA
```

continue funcionando.

Remova somente:

```text
roles/storage.objectViewer
```

do bucket:

```bash
# Remove o binding de leitura do bucket.
gcloud storage buckets remove-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Confirme:

```bash
# Verifica que o binding realmente saiu da policy do bucket.
gcloud storage buckets get-iam-policy "$BUCKET"
```

---

# 15. Confirmar que impersonation ainda funciona

Antes de testar o bucket novamente:

```bash
# Se este comando funcionar, o caminho usuário → SA está saudável.
gcloud auth print-access-token \
  --impersonate-service-account="$SA_EMAIL"
```

Esse passo é essencial para isolar a falha.

```text
impersonation funciona
+
bucket binding removido
=
falha esperada está no acesso ao bucket
```

---

# 16. Produzir o PERMISSION_DENIED

Agora tente ler:

```bash
# A SA continua sendo impersonada,
# mas não deve mais possuir storage.objects.get no bucket.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

Em um projeto de laboratório limpo, o comportamento esperado é:

```text
PERMISSION_DENIED
ou
403
```

relacionado à ausência de autorização para leitura do objeto.

> Se a leitura ainda funcionar, não conclua que o laboratório está errado:
> a Service Account pode possuir `storage.objects.get` por outro binding efetivo.
> Nesse caso, investigue os grants adicionais antes de remover qualquer privilégio.

---

# 17. Troubleshooting

## Sintoma

```text
gcloud storage cat
→ PERMISSION_DENIED / 403
```

## Hipótese

A Service Account não possui:

```text
storage.objects.get
```

sobre o bucket/objeto.

## Evidência 1 — impersonation

```bash
# Confirma que o usuário ainda consegue impersonar a SA.
gcloud auth print-access-token \
  --impersonate-service-account="$SA_EMAIL"
```

Se funciona:

```text
usuário → SA
= OK
```

## Evidência 2 — policy do bucket

```bash
# Inspeciona os bindings existentes no bucket.
gcloud storage buckets get-iam-policy "$BUCKET"
```

O binding:

```text
roles/storage.objectViewer
→ serviceAccount:$SA_EMAIL
```

não deverá estar presente.

## Evidência 3 — permissions da role

```bash
# Confirma que a role removida incluía a permission necessária.
gcloud iam roles describe roles/storage.objectViewer
```

Procure:

```text
storage.objects.get
```

## Causa

Removemos deliberadamente:

```text
roles/storage.objectViewer
```

da Service Account no bucket.

Logo:

```text
SA
→ não possui mais a permission esperada
→ leitura é negada
```

Não investigue:

```text
DNS
firewall
rota
```

porque a requisição chegou ao serviço e a resposta é uma negação de IAM.

---

# 18. Corrigir

Recrie exatamente o binding mínimo:

```bash
# Restaura somente a role necessária para leitura dos objetos.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"
```

Teste:

```bash
# Confirma a correção.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

Resultado:

```text
conteudo ACE
```

---

# 19. Least privilege

O requisito é:

```text
ler objetos
```

Compare:

```text
roles/storage.objectViewer
→ leitura de objetos
→ adequado

roles/storage.admin
→ administração ampla
→ excessivo

roles/editor
→ acesso amplo ao projeto
→ excessivo
```

A regra de prova é:

```text
use a menor role que satisfaça o requisito
```

---

# 20. Tipos de roles

## Basic Roles

Roles amplas e históricas:

```text
roles/viewer
roles/editor
roles/owner
```

Inspecione:

```bash
gcloud iam roles describe roles/viewer
gcloud iam roles describe roles/editor
gcloud iam roles describe roles/owner
```

## Predefined Roles

Criadas e mantidas pelo Google.

Exemplos:

```text
roles/compute.viewer
roles/compute.admin
roles/storage.objectViewer
roles/storage.admin
roles/bigquery.dataViewer
```

Liste:

```bash
# Lista roles IAM disponíveis.
gcloud iam roles list \
  --filter="stage:GA" \
  --limit=30
```

Filtre:

```bash
gcloud iam roles list \
  --filter="title:Storage"
```

## Custom Roles

Criadas pela organização ou projeto quando nenhuma predefined role atende adequadamente.

Modelo de preferência:

```text
predefined role mínima
        ↓ se não atender
custom role
        ↓ evitar para novos grants
basic role ampla
```

Na Semana 7, Custom Roles serão aprofundadas.

---

# 21. Service Accounts gerenciadas pelo Google

Alguns serviços criam identidades próprias, frequentemente chamadas de:

```text
service agents
```

Elas são usadas internamente por serviços Google Cloud.

Não remova suas roles ou exclua essas identidades sem entender a dependência do serviço.

Nesta aula criamos uma **user-managed Service Account**:

```text
ace-storage-reader@...
```

---

# 22. Questões estilo ACE

## Questão 1

Uma workload precisa somente ler objetos de um bucket.

Qual role escolher?

**Resposta:** `roles/storage.objectViewer`.

---

## Questão 2

Por que não conceder `roles/editor`?

**Resposta:** porque viola least privilege.

---

## Questão 3

Uma pessoa quer usar:

```text
--impersonate-service-account
```

Qual permission precisa existir sobre a Service Account?

**Resposta:**

```text
iam.serviceAccounts.getAccessToken
```

Ela está incluída em:

```text
roles/iam.serviceAccountTokenCreator
```

---

## Questão 4

O access token da impersonation funciona, mas a leitura do objeto retorna 403.

Onde investigar primeiro?

**Resposta:** IAM do bucket/objeto e as permissions da Service Account, não o Token Creator do usuário.

---

## Questão 5

O que é um binding?

**Resposta:** associação entre um principal e uma role dentro de uma IAM allow policy.

---

# 23. Cleanup

Remova o objeto:

```bash
gcloud storage rm "$BUCKET/dado.txt"
```

Exclua o bucket:

```bash
gcloud storage buckets delete "$BUCKET" \
  --quiet
```

Remova o binding de Token Creator criado para o laboratório:

```bash
gcloud iam service-accounts remove-iam-policy-binding "$SA_EMAIL" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator" \
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

# 24. Checklist

- [ ] Sei definir principal;
- [ ] Sei definir permission;
- [ ] Sei definir role;
- [ ] Sei definir resource;
- [ ] Sei explicar policy;
- [ ] Sei explicar binding;
- [ ] Criei uma Service Account;
- [ ] Inspecionei a Service Account;
- [ ] Sei por que impersonation exige `iam.serviceAccounts.getAccessToken`;
- [ ] Testei impersonation antes de testar o bucket;
- [ ] Concedi `roles/storage.objectViewer` somente no bucket;
- [ ] Testei leitura com impersonation;
- [ ] Removi somente o acesso ao bucket;
- [ ] Produzi/analisei `PERMISSION_DENIED`;
- [ ] Diferenciei falha de impersonation de falha de acesso ao resource;
- [ ] Corrigi sem aumentar privilégios;
- [ ] Executei cleanup.

---

# 25. Critério de aceite M/E/P

| Objetivo | Nível | Evidência |
|---|---:|---|
| Principal | E/P | definição + usuário + SA no laboratório |
| Permission | E/P | `storage.objects.get` + inspeção da role |
| Role | P | describe + grant + remove + restore |
| Policy | P | `get-iam-policy` + alteração por binding |
| Resource | E/P | bucket e Service Account |
| Criar Service Account | P | create + describe |
| Role mínima no bucket | P | `roles/storage.objectViewer` + teste |
| Impersonation | P | Token Creator + access token + operação |
| PERMISSION_DENIED | P | falha isolada + evidências + correção |

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
→ define grants sobre um resource

Binding
→ principal + role

Resource
→ objeto protegido por IAM
```

```text
Seu usuário
   ↓ Token Creator
Service Account
   ↓ Storage Object Viewer
Bucket
```

```text
Impersonation falha?
→ investigue usuário → Service Account

Impersonation funciona, mas recurso retorna 403?
→ investigue Service Account → Resource
```
