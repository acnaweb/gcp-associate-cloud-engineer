# Aula 2 — Service Accounts, Service Account User, Token Creator e Impersonation

## Objetivos

Ao final, você deverá:

- explicar por que uma Service Account é ao mesmo tempo um **principal IAM** e um **recurso IAM**;
- diferenciar `roles/iam.serviceAccountUser` de `roles/iam.serviceAccountTokenCreator`;
- entender o significado de `iam.serviceAccounts.actAs`;
- anexar uma Service Account a uma VM;
- gerar credenciais temporárias para uma Service Account;
- usar `--impersonate-service-account`;
- distinguir:
  - **o que a Service Account pode fazer**;
  - **quem pode usar/anexar a Service Account**;
  - **quem pode impersonar a Service Account**;
- diagnosticar falhas de `actAs` e de impersonation;
- evitar chaves JSON de longa duração quando credenciais curtas forem suficientes.

---

# 1. Conceito

## 1.1 Service Account é uma identidade

Uma Service Account é um **principal IAM** usado principalmente por workloads.

Exemplo:

```text
ace-app@PROJECT_ID.iam.gserviceaccount.com
```

Como principal, ela pode receber roles em recursos.

Exemplo:

```text
Service Account
      │
      │ roles/storage.objectViewer
      ▼
Cloud Storage
```

Nesse caso, a role responde:

> **O que essa Service Account pode fazer?**

Outro exemplo:

```text
ace-app
   │
   │ roles/viewer
   ▼
Projeto
```

A Service Account passa a ter as permissões incluídas naquela role.

---

## 1.2 Service Account também é um recurso IAM

A própria Service Account também é um recurso sobre o qual outros principals podem receber permissões.

Exemplo:

```text
Usuário
   │
   │ role concedida SOBRE a Service Account
   ▼
ace-app Service Account
```

Isso responde outra pergunta:

> **O que o usuário pode fazer COM essa Service Account?**

Essa distinção é fundamental.

```text
IAM concedido À Service Account em outros recursos
→ o que a SA pode fazer

IAM concedido SOBRE a própria Service Account
→ quem pode usá-la, impersoná-la ou administrá-la
```

---

# 2. As três ideias que não podem ser confundidas

## 2.1 Service Account

```text
Service Account
= identidade
```

Exemplo:

```text
ace-app@PROJECT_ID.iam.gserviceaccount.com
```

Ela pode possuir permissões como:

```text
roles/viewer
roles/storage.objectViewer
roles/pubsub.publisher
```

---

## 2.2 Service Account User

Role:

```text
roles/iam.serviceAccountUser
```

A principal permissão associada ao uso da Service Account em recursos é:

```text
iam.serviceAccounts.actAs
```

Modelo mental:

```text
Usuário
   │
   │ roles/iam.serviceAccountUser
   │ iam.serviceAccounts.actAs
   ▼
Service Account
   │
   │ anexada a
   ▼
VM / Cloud Run / outro recurso suportado
```

A ideia é:

> O usuário pode configurar um recurso para **executar como aquela Service Account**.

Isso **não** significa que o usuário ganhou automaticamente as permissões da SA no próprio terminal.

Também **não** significa que ele pode gerar um access token para a SA.

Exemplo típico de prova:

```text
"Um administrador precisa criar uma VM
e anexar uma Service Account à VM."

→ Service Account User
```

---

## 2.3 Service Account Token Creator

Role:

```text
roles/iam.serviceAccountTokenCreator
```

Essa role permite criar credenciais de curta duração para a Service Account e é central para impersonation.

Modelo mental:

```text
Usuário
   │
   │ roles/iam.serviceAccountTokenCreator
   ▼
gera credencial temporária
   │
   ▼
Service Account
   │
   ▼
Google API
```

Exemplos de credenciais temporárias incluem:

```text
OAuth 2.0 access token
OIDC ID token
signed JWT
signed blob
```

Exemplo típico:

```bash
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

Ou:

```bash
gcloud projects describe "$PROJECT_ID" \
  --impersonate-service-account="$SA"
```

Nesse caso, o usuário está chamando a API **temporariamente como a Service Account**.

Exemplo típico de prova:

```text
"Um usuário precisa executar comandos temporariamente
com as permissões de uma Service Account sem baixar uma chave JSON."

→ Service Account Token Creator
```

---

# 3. Comparação direta

| Elemento | Pergunta que responde | Exemplo |
|---|---|---|
| Service Account | Quem é a workload? | `ace-app@...` |
| Role concedida à SA | O que a SA pode fazer? | `roles/viewer` |
| Service Account User | Quem pode anexar/usar a SA em um recurso? | criar VM usando a SA |
| Service Account Token Creator | Quem pode gerar credenciais curtas/impersonar a SA? | `--impersonate-service-account` |

Memorize:

```text
Attach SA to resource
→ Service Account User

Impersonate / short-lived token
→ Service Account Token Creator
```

E principalmente:

```text
Service Account User
≠
Service Account Token Creator
```

São roles para operações diferentes.

---

# 4. Arquitetura do laboratório

Vamos observar os dois fluxos separadamente.

## Fluxo A — anexar SA a uma VM

```text
Seu usuário
    │
    │ Service Account User
    ▼
ace-impersonation SA
    │
    │ anexada a
    ▼
Compute Engine VM
```

## Fluxo B — impersonar a SA

```text
Seu usuário
    │
    │ Service Account Token Creator
    ▼
token curto
    │
    ▼
ace-impersonation SA
    │
    ▼
Google Cloud API
```

---

# 5. Preparar o laboratório

```bash
# Obtém o ID do projeto configurado atualmente no gcloud.
export PROJECT_ID="$(gcloud config get-value project)"

# Obtém a identidade atualmente autenticada no gcloud.
export USER_ACCOUNT="$(gcloud config get-value account)"

# Define a região usada no laboratório.
export REGION="us-central1"

# Define a zona usada para a VM.
export ZONE="us-central1-a"

# Define o nome da Service Account.
export SA_NAME="ace-impersonation"

# Monta o e-mail completo da Service Account.
export SA="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Habilita as APIs necessárias para IAM e Compute Engine.
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  compute.googleapis.com \
  policytroubleshooter.googleapis.com
```

---

# 6. Criar a Service Account

```bash
# Cria a Service Account que será usada nos dois laboratórios.
gcloud iam service-accounts create "$SA_NAME" \
  --display-name="ACE Service Account User e Token Creator"
```

Inspecione:

```bash
# Mostra os metadados da Service Account criada.
gcloud iam service-accounts describe "$SA"
```

---

# 7. Definir o que a Service Account pode fazer

Vamos conceder `roles/viewer` à Service Account no projeto.

```bash
# Concede Viewer À Service Account no projeto.
# Isso define O QUE a Service Account pode fazer.
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/viewer"
```

Inspecione:

```bash
# Filtra a IAM Policy do projeto para mostrar as roles concedidas À Service Account.
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA" \
  --format="table(bindings.role)"
```

Modelo mental:

```text
roles/viewer
foi concedida À Service Account
        ↓
define o que a SA pode fazer
```

---

# 8. Inspecionar as duas roles antes de usá-las

## Service Account User

```bash
# Mostra a definição oficial da role Service Account User.
gcloud iam roles describe roles/iam.serviceAccountUser
```

Procure principalmente pela permissão:

```text
iam.serviceAccounts.actAs
```

Ela representa a capacidade de **atuar como/anexar** a Service Account em cenários suportados.

## Service Account Token Creator

```bash
# Mostra a definição oficial da role Service Account Token Creator.
gcloud iam roles describe roles/iam.serviceAccountTokenCreator
```

Observe permissões relacionadas a geração de credenciais, como:

```text
iam.serviceAccounts.getAccessToken
iam.serviceAccounts.getOpenIdToken
iam.serviceAccounts.signBlob
iam.serviceAccounts.signJwt
```

---

# 9. Laboratório A — Service Account User

## 9.1 Conceder Service Account User ao seu usuário

A role será concedida **sobre a Service Account**.

```bash
# Permite que seu usuário use/anexe esta Service Account em recursos suportados.
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"
```

Inspecione a política IAM **DA própria Service Account**:

```bash
# Mostra quem recebeu roles SOBRE a Service Account.
gcloud iam service-accounts get-iam-policy "$SA"
```

Aqui você deverá encontrar:

```text
roles/iam.serviceAccountUser
```

associada ao seu usuário.

---

## 9.2 Criar VM usando a Service Account

```bash
# Cria uma VM e ANEXA a Service Account a ela.
#
# --service-account define a identidade usada pela workload na VM.
# --scopes=cloud-platform disponibiliza o escopo OAuth amplo;
# IAM continua sendo a fonte principal de autorização.
gcloud compute instances create ace-sa-vm \
  --zone="$ZONE" \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --service-account="$SA" \
  --scopes=cloud-platform
```

Observe o que aconteceu:

```text
Seu usuário
   │
   │ Service Account User
   ▼
pôde anexar
   │
   ▼
Service Account
   │
   ▼
VM
```

---

## 9.3 Inspecionar a identidade anexada

```bash
# Mostra as Service Accounts configuradas na VM.
gcloud compute instances describe ace-sa-vm \
  --zone="$ZONE" \
  --format="yaml(serviceAccounts)"
```

Comportamento esperado:

```text
serviceAccounts:
- email: ace-impersonation@PROJECT_ID.iam.gserviceaccount.com
```

Isso comprova o fluxo de **attach/use**.

---

# 10. O que Service Account User NÃO faz

Mesmo tendo:

```text
roles/iam.serviceAccountUser
```

não conclua que o usuário pode executar:

```bash
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

`Service Account User` não é a role usada para gerar credenciais temporárias para impersonation.

Modelo:

```text
Service Account User
→ attach/use SA em recurso

não significa

Service Account User
→ gerar access token da SA
```

---

# 11. Laboratório B — Service Account Token Creator

## 11.1 Conceder Token Creator

```bash
# Concede ao usuário permissão para criar credenciais temporárias
# em nome desta Service Account.
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Inspecione:

```bash
# Exibe as roles concedidas SOBRE a Service Account.
gcloud iam service-accounts get-iam-policy "$SA"
```

Agora deverão existir dois conceitos diferentes:

```text
Service Account User
→ attach

Service Account Token Creator
→ impersonation / token curto
```

---

## 11.2 Gerar access token temporário

```bash
# Gera um OAuth 2.0 access token temporário para a Service Account.
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

Não precisamos armazenar esse token.

O objetivo é provar que a credencial pode ser criada temporariamente.

---

## 11.3 Executar comando como a Service Account

```bash
# Consulta o projeto usando impersonation.
# A chamada à API será autorizada com a identidade da Service Account.
gcloud projects describe "$PROJECT_ID" \
  --impersonate-service-account="$SA"
```

Como a SA possui:

```text
roles/viewer
```

a leitura do projeto deverá funcionar.

Fluxo:

```text
Seu usuário
   │
   │ Token Creator
   ▼
credencial curta
   │
   ▼
Service Account
   │
   │ roles/viewer
   ▼
Projects API
```

---

# 12. A diferença mais importante da aula

Observe estes dois cenários:

## Cenário 1

```text
Usuário
   │
   │ Service Account User
   ▼
VM
usa
   ▼
Service Account
```

Aqui:

> **o recurso usa a identidade da SA.**

## Cenário 2

```text
Usuário
   │
   │ Token Creator
   ▼
credencial temporária
   │
   ▼
usuário chama API como SA
```

Aqui:

> **o próprio caller impersona temporariamente a SA.**

---

# 13. Quebrar propositalmente — remover o binding criado no laboratório

Até aqui, concedemos diretamente ao usuário:

```text
roles/iam.serviceAccountTokenCreator
```

sobre:

```text
ace-impersonation@PROJECT_ID.iam.gserviceaccount.com
```

Agora remova **esse binding específico**:

```bash
# Remove o binding de Token Creator criado diretamente sobre a Service Account.
gcloud iam service-accounts remove-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Inspecione a IAM Policy da própria Service Account:

```bash
# Confirma que o binding direto não está mais presente.
gcloud iam service-accounts get-iam-policy "$SA"
```

Nesse ponto, não conclua automaticamente:

```text
Token Creator removido
        ↓
impersonation obrigatoriamente falhará
```

Essa conclusão pode estar errada.

O que removemos foi apenas **um binding específico**.

A pergunta correta é:

```text
O principal ainda possui
`iam.serviceAccounts.getAccessToken`
por algum outro caminho?
```

---

# 14. Binding removido não significa necessariamente permission efetiva removida

IAM trabalha com **permissões efetivas**.

Um principal pode receber a mesma permission por diferentes políticas e níveis da hierarquia:

```text
binding direto na Service Account
          +
binding no projeto
          +
binding herdado de folder/organization
          +
custom role
          +
outro predefined role que contenha a permission
```

Para gerar access token e usar impersonation, a permission central é:

```text
iam.serviceAccounts.getAccessToken
```

`roles/iam.serviceAccountTokenCreator` contém essa permission, mas ela também pode chegar ao principal por outro caminho.

Por isso, este comando:

```bash
# Tenta gerar um access token temporário para a Service Account.
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

pode produzir dois resultados legítimos.

## Resultado A — falha

Se o usuário não possui mais `iam.serviceAccounts.getAccessToken` de nenhuma outra origem, a impersonation falha.

## Resultado B — continua funcionando

Se o usuário ainda possui a permission efetiva por outro binding/role, o comando continua funcionando.

Isso é comum em contas administrativas ou ambientes com IAM amplo.

---

# 15. Diagnóstico correto — Policy Troubleshooter

Não adivinhe. Consulte a permission efetiva.

A Service Account pode ser referenciada pelo full resource name:

```text
//iam.googleapis.com/projects/PROJECT_ID/serviceAccounts/SA_EMAIL
```

Defina:

```bash
# Monta o full resource name da Service Account para o Policy Troubleshooter.
export SA_RESOURCE="//iam.googleapis.com/projects/${PROJECT_ID}/serviceAccounts/${SA}"
```

Agora execute:

```bash
# Verifica se o usuário possui efetivamente a permission
# iam.serviceAccounts.getAccessToken sobre a Service Account.
gcloud policy-intelligence troubleshoot-policy iam "$SA_RESOURCE" \
  --principal-email="$USER_ACCOUNT" \
  --permission="iam.serviceAccounts.getAccessToken"
```

O Policy Troubleshooter avalia as políticas aplicáveis e informa se o principal possui ou não a permission.

Modelo mental:

```text
binding removido
      ↓
Policy Troubleshooter
      ↓
principal ainda tem permission?
   ┌───────┴────────┐
   │                │
  SIM              NÃO
   │                │
impersonation     impersonation
pode funcionar    deve falhar
```

---

# 16. Inspecionar possíveis fontes da permission

## 16.1 Policy da própria Service Account

```bash
# Mostra bindings diretamente configurados sobre a Service Account.
gcloud iam service-accounts get-iam-policy "$SA"
```

## 16.2 IAM Policy do projeto

```bash
# Lista roles do usuário no projeto.
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$USER_ACCOUNT" \
  --format="table(bindings.role)"
```

Esse comando mostra roles do projeto, mas não resolve sozinho toda a herança.

Por isso o Policy Troubleshooter é a evidência principal neste laboratório.

---

# 17. Verificar impersonation configurada globalmente no gcloud

O `gcloud` pode estar configurado para impersonar automaticamente uma Service Account.

Verifique:

```bash
# Exibe a Service Account configurada para impersonation na configuração ativa.
gcloud config get-value auth/impersonate_service_account
```

Se houver um valor configurado e você quiser evitar interferência no laboratório:

```bash
# Remove temporariamente a impersonation persistente da configuração ativa.
gcloud config unset auth/impersonate_service_account
```

Depois repita:

```bash
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

---

# 25. Troubleshooting — impersonation continua funcionando após remover Token Creator

## Sintoma

Você removeu:

```text
roles/iam.serviceAccountTokenCreator
```

da IAM Policy da Service Account, mas:

```bash
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

continua funcionando.

## Hipótese

O usuário ainda possui:

```text
iam.serviceAccounts.getAccessToken
```

por outra origem.

## Evidência 1 — binding direto realmente foi removido?

```bash
gcloud iam service-accounts get-iam-policy "$SA"
```

Confirme que o binding criado pelo laboratório não aparece.

## Evidência 2 — permission efetiva

```bash
gcloud policy-intelligence troubleshoot-policy iam "$SA_RESOURCE" \
  --principal-email="$USER_ACCOUNT" \
  --permission="iam.serviceAccounts.getAccessToken"
```

Se o resultado indicar acesso permitido, a impersonation continuar funcionando é coerente.

## Evidência 3 — roles no projeto

```bash
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:user:$USER_ACCOUNT" \
  --format="table(bindings.role)"
```

Use essa saída para procurar grants adicionais, lembrando que políticas também podem vir de níveis superiores.

## Causa

O laboratório removeu uma concessão direta, mas não eliminou necessariamente todas as origens da permission efetiva.

## Correção

Em ambiente real, **não remova papéis administrativos amplos apenas para fazer o teste falhar**.

A correção didática é:

```text
1. identificar a origem da permission;
2. entender por que ela continua efetiva;
3. usar um principal de laboratório com privilégios mínimos
   se for necessário demonstrar uma negação previsível.
```

---

# 26. Como reproduzir uma falha previsível

Para uma demonstração determinística, use um principal de laboratório que:

```text
não tenha roles herdadas amplas
não tenha custom role com getAccessToken
não tenha Token Creator sobre a SA
```

O fluxo esperado é:

```text
principal mínimo
      ↓
sem getAccessToken
      ↓
Policy Troubleshooter = DENIED
      ↓
--impersonate-service-account falha
```

Depois conceda:

```text
roles/iam.serviceAccountTokenCreator
```

sobre a Service Account.

Agora:

```text
Policy Troubleshooter = ALLOWED
      ↓
impersonation funciona
```

Isso demonstra causa e efeito sem depender das permissões administrativas da conta usada para construir o laboratório.

---

# 27. Recriar Token Creator para continuar a aula

Se o seu usuário realmente perdeu a permission efetiva, restaure o binding:

```bash
# Restaura Token Creator sobre a Service Account.
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Teste:

```bash
# Confirma impersonation com a role restaurada.
gcloud projects describe "$PROJECT_ID" \
  --impersonate-service-account="$SA"
```

---

# 28. Quebrar propositalmente — remover Service Account User

Agora faça um teste separado para `actAs`.

Remova:

```bash
# Remove o binding direto de Service Account User.
gcloud iam service-accounts remove-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"
```

Aqui vale a mesma regra:

```text
binding removido
≠
permission efetiva necessariamente removida
```

A permission relevante é:

```text
iam.serviceAccounts.actAs
```

Use o Policy Troubleshooter:

```bash
# Verifica se o usuário ainda possui actAs efetivamente.
gcloud policy-intelligence troubleshoot-policy iam "$SA_RESOURCE" \
  --principal-email="$USER_ACCOUNT" \
  --permission="iam.serviceAccounts.actAs"
```

Se ainda estiver permitido, o usuário pode continuar conseguindo anexar a SA por outro grant efetivo.

---

# 29. Troubleshooting de actAs

## Sintoma

Uma operação de anexar a Service Account a um recurso funciona ou falha de maneira diferente do esperado após remover `Service Account User`.

## Hipótese

A permission efetiva:

```text
iam.serviceAccounts.actAs
```

ainda existe ou deixou de existir.

## Evidência

```bash
gcloud policy-intelligence troubleshoot-policy iam "$SA_RESOURCE" \
  --principal-email="$USER_ACCOUNT" \
  --permission="iam.serviceAccounts.actAs"
```

## Causa

A decisão depende da **permission efetiva**, não apenas de um binding isolado.

## Correção

Para restaurar o binding direto usado no laboratório:

```bash
gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountUser"
```

---

# 30. Regra de ouro desta aula

```text
Role removida de um binding
≠
permission necessariamente removida
```

Sempre raciocine em três níveis:

```text
Role
  ↓
contém permissions
  ↓
políticas efetivas determinam acesso
```

Para este caso:

```text
roles/iam.serviceAccountTokenCreator
        ↓
iam.serviceAccounts.getAccessToken
        ↓
impersonation

roles/iam.serviceAccountUser
        ↓
iam.serviceAccounts.actAs
        ↓
attach/use SA em recurso
```

---

# 24. Credenciais de curta duração


A ideia central de impersonation é evitar, quando possível, credenciais persistentes.

Compare:

```text
Service Account Key JSON
→ segredo de longa duração
→ precisa ser armazenado/protegido/rotacionado
```

com:

```text
Impersonation
→ credencial curta
→ emitida quando necessária
→ expira automaticamente
```

Exemplo de access token:

```bash
# Gera um access token curto.
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

Exemplo de ID token:

```bash
# Gera um ID token para cenários que exigem autenticação OIDC compatível.
gcloud auth print-identity-token \
  --impersonate-service-account="$SA"
```

---

# 25. Service Account User não concede as permissões da SA ao usuário

Este é um erro conceitual comum.

Imagine:

```text
ace-app
→ roles/storage.admin
```

e:

```text
antonio@example.com
→ roles/iam.serviceAccountUser sobre ace-app
```

Isso não significa automaticamente:

```text
antonio@example.com
→ Storage Admin
```

O usuário pode estar autorizado a anexar a SA a um recurso.

A autorização do recurso em runtime será exercida pela identidade anexada conforme o serviço e contexto suportados.

---

# 26. Token Creator merece cuidado

Se uma Service Account possui privilégios elevados:

```text
privileged-sa
→ roles/admin...
```

e um usuário recebe:

```text
roles/iam.serviceAccountTokenCreator
```

sobre essa SA, ele pode impersoná-la e agir com as permissões que a SA possui durante a validade das credenciais.

Modelo:

```text
Usuário com poucos privilégios próprios
        │
        │ Token Creator
        ▼
SA privilegiada
        │
        ▼
recursos acessíveis à SA
```

Por isso, aplique:

```text
least privilege
```

também às permissões **sobre** Service Accounts.

---

# 27. Questões estilo ACE

## Questão 1

Um engenheiro precisa criar uma VM configurada para executar com a Service Account `app-sa`. Qual role ele precisa sobre a Service Account?

**Resposta:** `roles/iam.serviceAccountUser`.

Motivo:

```text
attach SA to resource
→ Service Account User
```

---

## Questão 2

Um engenheiro precisa executar temporariamente comandos `gcloud` usando a identidade de `app-sa`, sem baixar uma chave JSON.

**Resposta:** `roles/iam.serviceAccountTokenCreator`.

Motivo:

```text
impersonation / short-lived credentials
→ Service Account Token Creator
```

---

## Questão 3

`app-sa` possui `roles/storage.objectViewer` em um bucket. Um usuário recebe `roles/iam.serviceAccountUser` sobre `app-sa`.

O usuário automaticamente consegue executar `gcloud storage ls` em seu próprio contexto usando as permissões da SA?

**Resposta:** Não.

`Service Account User` controla o uso/anexo da SA em contextos suportados; não é, por si só, uma credencial de impersonation.

---

## Questão 4

Qual alternativa é preferível quando uma pessoa precisa assumir temporariamente uma identidade de workload e a arquitetura suporta isso?

A. Baixar uma chave JSON e mantê-la indefinidamente.  
B. Service Account impersonation com credenciais de curta duração.  
C. Dar Owner ao usuário.  
D. Tornar o recurso público.

**Resposta:** B.

---

# 28. Cleanup

Primeiro exclua a VM.

```bash
# Exclui a VM criada no laboratório.
gcloud compute instances delete ace-sa-vm \
  --zone="$ZONE" \
  --quiet
```

Remova os bindings concedidos sobre a Service Account.

```bash
# Remove Service Account User.
gcloud iam service-accounts remove-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountUser" \
  --quiet

# Remove Service Account Token Creator.
gcloud iam service-accounts remove-iam-policy-binding "$SA" \
  --member="user:$USER_ACCOUNT" \
  --role="roles/iam.serviceAccountTokenCreator" \
  --quiet
```

Remova a role concedida **à** Service Account no projeto.

```bash
# Remove Viewer da Service Account no projeto.
gcloud projects remove-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/viewer" \
  --quiet
```

Por fim:

```bash
# Exclui a Service Account.
gcloud iam service-accounts delete "$SA" \
  --quiet
```

---

# 29. Checklist

- [ ] Sei explicar Service Account como principal;
- [ ] Sei explicar Service Account como recurso;
- [ ] Sei diferenciar IAM **da SA** de IAM concedido **à SA**;
- [ ] Sei para que serve `roles/iam.serviceAccountUser`;
- [ ] Relaciono Service Account User com `iam.serviceAccounts.actAs`;
- [ ] Sei para que serve `roles/iam.serviceAccountTokenCreator`;
- [ ] Sei gerar credencial temporária;
- [ ] Sei usar `--impersonate-service-account`;
- [ ] Sei distinguir attach de impersonation;
- [ ] Testei o fluxo esperado;
- [ ] Provoquei falha;
- [ ] Diagnostiquei usando IAM Policy da própria SA;
- [ ] Sei que remover um binding não garante remover a permission efetiva;
- [ ] Usei Policy Troubleshooter para `iam.serviceAccounts.getAccessToken` e `iam.serviceAccounts.actAs`;
- [ ] Executei cleanup.

---

# 30. Critério de aceite M/E/P

| Tópico | Esperado | Evidência nesta aula |
|---|---:|---|
| Criar Service Account | P | criação + describe |
| Conceder role à SA | P | binding no projeto + inspeção |
| Service Account User | P | binding + attach à VM + describe |
| `iam.serviceAccounts.actAs` | E/P | inspeção da role + uso em recurso |
| Token Creator | P | binding + token + impersonation |
| Credenciais curtas | P | access token / ID token |
| IAM da própria SA | P | get-iam-policy |
| IAM concedido à SA | P | project get-iam-policy |
| Troubleshooting de impersonation | P | remover binding + Policy Troubleshooter + análise de permission efetiva |
| Troubleshooting de actAs | P | remover binding + Policy Troubleshooter + análise de `iam.serviceAccounts.actAs` |

---

## Resumo para prova

```text
Service Account
= identidade

Service Account User
= attach/use SA em recurso
= iam.serviceAccounts.actAs

Service Account Token Creator
= criar credenciais curtas
= impersonar a SA
= --impersonate-service-account
```
