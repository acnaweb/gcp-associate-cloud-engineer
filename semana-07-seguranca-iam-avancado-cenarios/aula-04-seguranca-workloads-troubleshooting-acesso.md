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
export PROJECT_ID=$(gcloud config get-value project)
export SA="ace-noaccess@$PROJECT_ID.iam.gserviceaccount.com"
export BUCKET="gs://$PROJECT_ID-ace-sec-$RANDOM"

gcloud iam service-accounts create ace-noaccess
gcloud storage buckets create "$BUCKET" --location=us-central1
echo dado > arquivo.txt
gcloud storage cp arquivo.txt "$BUCKET/"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud iam service-accounts describe "$SA"
gcloud storage buckets get-iam-policy "$BUCKET"
gcloud auth list
```

---

# 4. Testar

Tente ler via SA sem role:

```bash
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
gcloud storage buckets get-iam-policy "$BUCKET"
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
gcloud storage buckets add-iam-policy-binding "$BUCKET" \
  --member="serviceAccount:$SA" \
  --role="roles/storage.objectViewer"

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
gcloud storage rm "$BUCKET/arquivo.txt"
gcloud storage buckets delete "$BUCKET" --quiet
gcloud iam service-accounts delete "$SA" --quiet
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
