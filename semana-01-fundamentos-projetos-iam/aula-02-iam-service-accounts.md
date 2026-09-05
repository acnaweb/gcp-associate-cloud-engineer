# Aula 2 — IAM e Service Accounts

## Objetivos

Ao final, você deverá:
- entender principal, role, permission, policy e resource;
- criar uma Service Account;
- conceder uma role mínima em um bucket;
- testar acesso com impersonation;
- diagnosticar um `PERMISSION_DENIED` produzido no laboratório.


---

# 1. Conceito

IAM responde “quem pode fazer o quê em qual recurso”. Service Accounts são identidades usadas por workloads. Nesta aula o acesso será testado sem criar chave JSON persistente.

## Arquitetura mental

```text
User
  └─ impersonates
      Service Account
          └─ role
              └─ Bucket
```

---

# 2. Criar

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define a variável `SA_NAME` usada nas próximas etapas do laboratório.
export SA_NAME=ace-storage-reader
# Explicação: Define a variável `SA_EMAIL` usada nas próximas etapas do laboratório.
export SA_EMAIL="$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com"
# Explicação: Define `BUCKET` com o nome do bucket usado no laboratório.
export BUCKET="gs://$PROJECT_ID-ace-iam-$RANDOM"

# Explicação: Cria uma Service Account que será usada como identidade de workload ou principal IAM.
gcloud iam service-accounts create "$SA_NAME"
# Explicação: Cria um bucket Cloud Storage com localização e opções informadas.
gcloud storage buckets create "$BUCKET" --location=us-central1

# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo "conteudo ACE" > dado.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp dado.txt "$BUCKET/"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe detalhes da Service Account indicada.
gcloud iam service-accounts describe "$SA_EMAIL"
# Explicação: Exibe propriedades do bucket, como localização, storage class, versioning e políticas.
gcloud storage buckets describe "$BUCKET"
# Explicação: Exibe a política IAM do bucket para verificar quem possui acesso.
gcloud storage buckets get-iam-policy "$BUCKET"
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
```

---

# 4. Testar

Conceda leitura e depois teste:

```bash
# Explicação: Adiciona uma concessão IAM diretamente ao bucket.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

---

# 5. Quebrar propositalmente

Remova a role que acabou de conceder:

```bash
# Explicação: Remove uma concessão IAM diretamente do bucket.
gcloud storage buckets remove-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

Agora você espera um erro de autorização.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** leitura retorna `PERMISSION_DENIED`/403.

**Hipótese:** a SA não possui mais permissão `storage.objects.get`.

**Evidências:**
```bash
# Explicação: Exibe a política IAM do bucket para verificar quem possui acesso.
gcloud storage buckets get-iam-policy "$BUCKET"
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
```

**Causa:** removemos deliberadamente o binding `roles/storage.objectViewer`.

Observe que não há motivo para investigar rota, firewall ou DNS: o acesso está chegando ao serviço e a negação é de IAM.

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

Recrie exatamente o binding mínimo:

```bash
# Explicação: Adiciona uma concessão IAM diretamente ao bucket.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/dado.txt" \
  --impersonate-service-account="$SA_EMAIL"
```

---

# 8. Questões estilo ACE

1. A workload só precisa ler objetos. Qual role escolher? **Storage Object Viewer**.
2. Por que não usar `roles/editor`? **Viola least privilege**.
3. A SA precisa obrigatoriamente de uma chave JSON para este cenário? **Não.**

---

# 9. Cleanup

```bash
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm "$BUCKET/dado.txt"
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$BUCKET" --quiet
# Explicação: Exclui a Service Account criada para o laboratório.
gcloud iam service-accounts delete "$SA_EMAIL" --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f dado.txt
```

---


---

# Cobertura ACE ampliada — permissions e tipos de roles

## Permission → Role → Binding

```text
Permission
   ↓ agrupada em
Role
   ↓ concedida a um
Principal
   ↓ em um
Resource / Scope
```

Exemplos:

```text
storage.objects.get
compute.instances.start
resourcemanager.projects.get
```

## Basic Roles

As Basic Roles são amplas e históricas:

```text
roles/viewer  → Viewer
roles/editor  → Editor
roles/owner   → Owner
```

Inspecione:

```bash
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/viewer
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/editor
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/owner
```

## Predefined Roles

São criadas e mantidas pelo Google para serviços específicos.

Exemplos:

```text
roles/compute.viewer
roles/compute.admin
roles/storage.objectViewer
roles/storage.admin
roles/bigquery.dataViewer
```

Descubra as roles existentes:

```bash
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list --filter='stage:GA' --limit=30
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list --filter='title:Compute'
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list --filter='title:Storage'
```

Inspecione as permissions de uma role:

```bash
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/compute.viewer
```

## Custom Roles

Use quando nenhuma predefined role atende o conjunto necessário de permissions.

```text
Preferência para a prova:
predefined role mínima
   ↓ se não atende
custom role
   ↓ evitar
basic role ampla
```

## Google-managed service accounts

Alguns serviços criam Service Accounts gerenciadas pelo Google/service agents. Não delete ou altere suas permissões sem entender a dependência do serviço.

## Perguntas adicionais

1. Onde descobrir roles prontas? **IAM & Admin → Roles** ou `gcloud iam roles list`.
2. Viewer, Editor e Owner pertencem a qual categoria? **Basic Roles**.
3. `Storage Object Viewer` é basic ou predefined? **Predefined**.
4. Role é uma lista de quê? **Permissions**.

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

# Cobertura fundamental — Permissions, Basic Roles, Predefined Roles e Custom Roles

Este conteúdo deve ser dominado já na Semana 1, e será aprofundado novamente na Semana 7.

## Permission

Permission é uma operação elementar, normalmente com formato semelhante a:

```text
service.resource.verb
```

Exemplos:

```text
compute.instances.get
storage.objects.get
storage.objects.create
```

## Role

Role é um conjunto de permissions:

```text
Principal
   ↓ recebe
Role
   ↓ contém
Permissions
   ↓ sobre
Resource
```

## Tipos de roles

### Basic Roles

```text
roles/viewer
roles/editor
roles/owner
```

São amplas e existem principalmente por compatibilidade/conveniência. Para novos grants, prefira roles mais específicas quando possível.

### Predefined Roles

Criadas e mantidas pelo Google para serviços e responsabilidades específicas:

```text
roles/compute.viewer
roles/compute.admin
roles/storage.objectViewer
roles/storage.objectAdmin
roles/storage.admin
roles/bigquery.dataViewer
roles/run.invoker
```

### Custom Roles

Criadas na organização ou projeto quando nenhuma predefined role atende ao conjunto mínimo necessário.

## Como descobrir roles existentes

No Console:

```text
IAM & Admin → Roles
```

Pelo CLI:

```bash
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list --filter='title:Compute'
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/viewer
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/editor
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/compute.viewer
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
```

Para listar apenas custom roles do projeto:

```bash
# Explicação: Lista roles IAM disponíveis para descobrir roles básicas/predefinidas ou filtrar as relevantes.
gcloud iam roles list --project="$(gcloud config get-value project)"
```

## Como descobrir as permissions de uma role

```bash
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
```

Observe `includedPermissions`.

## Regra de prova

Se a questão disser:

> “O usuário precisa apenas visualizar VMs.”

Compare:

```text
Editor           → amplo demais
Compute Admin    → amplo demais
Compute Viewer   → adequado
Owner            → muito amplo
```

A prova costuma favorecer **least privilege**.
