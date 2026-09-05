# Aula 4 — Segurança de Workloads e Troubleshooting de Acesso

## Objetivos

Ao final, você deverá:
- diagnosticar 403 de maneira estruturada;
- identificar principal efetivo;
- conferir IAM no recurso;
- usar Policy Troubleshooter no Console;
- corrigir com role mínima.


---

# 1. Conceito

Autenticação responde “quem é”. Autorização responde “pode”. Em workload, identidade efetiva costuma ser uma Service Account. 403 normalmente indica autorização, embora detalhes devam ser confirmados pela mensagem/evidência.

## Arquitetura mental

```text
Request
 ↓ identity
 ↓ IAM policy/condition
 ↓ allow/deny decision
 ↓ Resource
```

---

# 2. Criar

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define a variável `SA` usada nas próximas etapas do laboratório.
export SA="ace-noaccess@$PROJECT_ID.iam.gserviceaccount.com"
# Explicação: Define `BUCKET` com o nome do bucket usado no laboratório.
export BUCKET="gs://$PROJECT_ID-ace-sec-$RANDOM"

# Explicação: Cria uma Service Account que será usada como identidade de workload ou principal IAM.
gcloud iam service-accounts create ace-noaccess
# Explicação: Cria um bucket Cloud Storage com localização e opções informadas.
gcloud storage buckets create "$BUCKET" --location=us-central1
# Explicação: Exibe ou grava o valor/texto informado, normalmente para validar variável ou criar conteúdo de teste.
echo dado > arquivo.txt
# Explicação: Copia arquivo(s) entre o ambiente local e Cloud Storage, ou entre localizações no Cloud Storage.
gcloud storage cp arquivo.txt "$BUCKET/"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
# Explicação: Exibe detalhes da Service Account indicada.
gcloud iam service-accounts describe "$SA"
# Explicação: Exibe a política IAM do bucket para verificar quem possui acesso.
gcloud storage buckets get-iam-policy "$BUCKET"
# Explicação: Lista as identidades autenticadas e mostra qual conta está ativa no `gcloud`.
gcloud auth list
```

---

# 4. Testar

Tente ler via SA sem role:

```bash
# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/arquivo.txt" \
  --impersonate-service-account="$SA"
```

Se ainda não tiver Token Creator para impersonar, use a aula anterior para conceder temporariamente essa capacidade ao seu usuário. O importante aqui é separar:
1. conseguir assumir a SA;
2. a SA poder acessar o bucket.

---

# 5. Quebrar propositalmente

A ausência de role no bucket é a falha proposital. Não adicione firewall ou VPC ao cenário.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** 403/PERMISSION_DENIED ao ler objeto.

**Hipótese:** SA efetiva não tem `storage.objects.get`.

**Evidências:**
```bash
# Explicação: Exibe a política IAM do bucket para verificar quem possui acesso.
gcloud storage buckets get-iam-policy "$BUCKET"
# Explicação: Exibe detalhes da role IAM, incluindo permissões e estágio, para entender exatamente o acesso concedido.
gcloud iam roles describe roles/storage.objectViewer
```

No Console:
IAM & Admin → Policy Troubleshooter
- Principal: `$SA`
- Permission: `storage.objects.get`
- Resource: bucket/objeto apropriado

**Causa:** nenhuma role de leitura foi concedida à SA.

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
# Explicação: Adiciona uma concessão IAM diretamente ao bucket.
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA" \
  --role="roles/storage.objectViewer"

# Explicação: Lê o conteúdo de um objeto do Cloud Storage diretamente no terminal.
gcloud storage cat "$BUCKET/arquivo.txt" \
  --impersonate-service-account="$SA"
```

---

# 8. Questões estilo ACE

1. 403 em API: investigar primeiro **IAM/autorização**.
2. Corrigir com Owner? **Não; usar role mínima**.
3. Workload está usando SA diferente da esperada: corrigir **runtime identity**, não aumentar permissões aleatoriamente.

---

# 9. Cleanup

```bash
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm "$BUCKET/arquivo.txt"
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$BUCKET" --quiet
# Explicação: Exclui a Service Account criada para o laboratório.
gcloud iam service-accounts delete "$SA" --quiet
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
rm -f arquivo.txt
```

---

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

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.
