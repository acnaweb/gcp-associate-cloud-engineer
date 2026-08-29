# Aula 2 — Service Accounts e Impersonation

## Objetivos

Ao final, você deverá:
- diferenciar runtime SA, Service Account User e Token Creator;
- praticar impersonation;
- remover Token Creator e observar falha;
- evitar long-lived keys.


---

# 1. Conceito

Service Account é principal. `Service Account User` permite usar/anexar SA em determinados contextos. `Service Account Token Creator` permite criar credenciais curtas/impersonar. São permissões diferentes.

## Arquitetura mental

```text
User
 ├─ SA User → attach/use SA
 └─ Token Creator → impersonate
                       ↓
                 Service Account
                       ↓
                    API
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)
export USER=$(gcloud config get-value account)
export SA="ace-impersonation@$PROJECT_ID.iam.gserviceaccount.com"

gcloud iam service-accounts create ace-impersonation

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA" \
  --role="roles/viewer"

gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --member="user:$USER" \
  --role="roles/iam.serviceAccountTokenCreator"
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
gcloud iam service-accounts get-iam-policy "$SA"
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:$SA"
```

---

# 4. Testar

```bash
gcloud projects describe "$PROJECT_ID" \
  --impersonate-service-account="$SA"

gcloud auth print-access-token \
  --impersonate-service-account="$SA" | head -c 20
echo
```

---

# 5. Quebrar propositalmente

Remova Token Creator:

```bash
gcloud iam service-accounts remove-iam-policy-binding "$SA" \
  --member="user:$USER" \
  --role="roles/iam.serviceAccountTokenCreator"

gcloud projects describe "$PROJECT_ID" \
  --impersonate-service-account="$SA"
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** impersonation falha.

**Hipótese:** usuário não pode mais gerar token da SA.

**Evidência:**
```bash
gcloud iam service-accounts get-iam-policy "$SA"
```

**Causa:** removemos `roles/iam.serviceAccountTokenCreator`.

A SA ainda tem `roles/viewer` no projeto, mas o usuário não consegue mais assumir essa identidade. Isso separa “o que a SA pode fazer” de “quem pode impersoná-la”.

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

Reaplique Token Creator e teste novamente.

---

# 8. Questões estilo ACE

1. Gerar token da SA? **Service Account Token Creator**.
2. Attach SA a recurso? **Service Account User** (além das permissões do recurso).
3. Melhor que baixar chave JSON quando possível? **Impersonation/credenciais curtas**.

---

# 9. Cleanup

```bash
gcloud iam service-accounts delete "$SA" --quiet
```

---


---

# Cobertura ACE ampliada — short-lived credentials e SA em recursos

## Assign Service Account to resource

Exemplo VM:

```bash
gcloud compute instances create ace-sa-vm \
  --zone=us-central1-a \
  --service-account="$SA" \
  --scopes=cloud-platform \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

A autorização efetiva depende das IAM roles da SA; scopes não substituem IAM.

## Short-lived credentials

Além de impersonation pelo `gcloud`, entenda o conceito de credenciais temporárias:

```text
User/Workload autorizado
       ↓ token curto
Service Account identity
       ↓
Google API
```

Isso reduz risco em comparação com chaves JSON de longa duração.

## Service Account IAM policy

Há duas dimensões diferentes:

```text
Roles concedidas À SA em recursos
→ o que a SA pode fazer

IAM policy DA própria SA
→ quem pode usar/impersonar/administrar a SA
```

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

# Cobertura adicional — identidade temporária e credenciais de curta duração

O exam guide exige administrar identidade temporária e credenciais curtas de Service Account.

Exemplos:

```bash
gcloud auth print-access-token \
  --impersonate-service-account="$SA"
```

Para emitir token ID quando necessário para audiência compatível:

```bash
gcloud auth print-identity-token \
  --impersonate-service-account="$SA"
```

Modelo mental:

```text
Key JSON de longa duração
→ segredo persistente; maior risco operacional

Impersonation / short-lived token
→ credencial temporária
→ preferível quando arquitetura suporta
```

Não confunda:

```text
roles/iam.serviceAccountUser
→ usar/anexar SA a um recurso

roles/iam.serviceAccountTokenCreator
→ criar tokens/impersonar em cenários suportados
```


---

## Prática completa — atribuir SA a recurso e gerenciar IAM da própria SA

### Atribuir Service Account a uma VM

```bash
gcloud compute instances create ace-sa-vm \
  --zone=us-central1-a \
  --service-account="$SA" \
  --scopes=cloud-platform \
  --machine-type=e2-micro \
  --image-family=debian-12 \
  --image-project=debian-cloud

gcloud compute instances describe ace-sa-vm \
  --zone=us-central1-a \
  --format='yaml(serviceAccounts)'
```

### IAM DA Service Account

```bash
gcloud iam service-accounts get-iam-policy "$SA"
```

Isso responde **quem pode usar/impersonar/administrar essa identidade**.

### IAM concedido À Service Account

```bash
gcloud projects get-iam-policy "$PROJECT_ID" \
  --flatten='bindings[].members' \
  --filter="bindings.members:serviceAccount:$SA"
```

Isso responde **o que essa identidade pode fazer em recursos**.

### Cleanup adicional

```bash
gcloud compute instances delete ace-sa-vm \
  --zone=us-central1-a --quiet
```
