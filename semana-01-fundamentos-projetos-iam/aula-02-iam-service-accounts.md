# Aula 2 — IAM e Service Accounts

## Objetivos

Ao final desta aula, você deverá:

- Entender Principal, Role, Permission e Resource;
- Criar Service Account;
- Conceder e remover role;
- Testar least privilege;

---

# 1. Modelo mental

```text
Principal ── role ──> Resource
                 │
                 └─ permissions

VM/Cloud Run ── usa ──> Service Account
```

O objetivo desta aula não é apenas reconhecer nomes de serviços. Você deve conseguir **criar, inspecionar, testar e explicar** o comportamento dos recursos.

---

# 2. Regra de estudo da aula

Use sempre este ciclo:

```text
Conceito
   ↓
Criar
   ↓
Inspecionar
   ↓
Testar
   ↓
Quebrar propositalmente
   ↓
Diagnosticar
   ↓
Corrigir
   ↓
Remover
```

---

# 3. Laboratório principal

```bash
export PROJECT_ID=$(gcloud config get-value project)
export SA_NAME=ace-lab-sa
export SA_EMAIL=$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts create $SA_NAME \
  --display-name="ACE Lab Service Account"

gcloud iam service-accounts list
```

Crie um bucket e tente desenhar o acesso:
```bash
export BUCKET=gs://$PROJECT_ID-ace-iam-lab
gcloud storage buckets create $BUCKET --location=us-central1
```

Conceda somente leitura de objetos ao principal:
```bash
gcloud storage buckets add-iam-policy-binding $BUCKET \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectViewer"

gcloud storage buckets get-iam-policy $BUCKET
```

Inspecione IAM do projeto:
```bash
gcloud projects get-iam-policy $PROJECT_ID \
  --format="table(bindings.role,bindings.members)"
```

Compare papéis:
```bash
gcloud iam roles describe roles/storage.objectViewer
gcloud iam roles describe roles/storage.objectAdmin
```

---

# 4. Testes e falhas propositais

- Remova o binding e observe como o principal perde o acesso.
- Compare objectViewer x objectAdmin antes de escolher a role.
- Não crie chave persistente de SA para este lab: a prova favorece credenciais de curta duração quando possível.

Para cada falha, não corrija imediatamente. Primeiro registre:

```text
Sintoma:
Hipótese:
Comando/evidência:
Causa:
Correção:
```

---

# 5. Troubleshooting

Use este fluxo:

```text
1. O recurso existe e está no estado esperado?
2. O escopo (project/region/zone) está correto?
3. A identidade/principal está correta?
4. IAM permite a operação?
5. Rede/rota/firewall permitem comunicação, quando aplicável?
6. A aplicação/serviço está saudável?
7. Há quota/capacidade suficiente?
8. Logs e métricas confirmam a hipótese?
```

Comandos-base:

```bash
gcloud config list
gcloud auth list
gcloud projects describe $(gcloud config get-value project)
gcloud logging read 'severity>=ERROR' --limit=10
```

---

# 6. Pegadinhas ACE

- Roles contêm permissions.
- Bindings associam principals a roles.
- Service Account é identidade de workload, não 'usuário técnico genérico'.
- Owner/Editor são amplos; prefira predefined roles específicas.

---

# 7. Questões estilo ACE

- Uma aplicação só precisa ler objetos. Qual role é mais adequada? → Storage Object Viewer.
- Você precisa permitir que uma VM aja como uma SA. Qual conceito aparece? → Service Account User/attach SA.

---

# 8. Checklist

- [ ] Consigo explicar o modelo mental da aula;
- [ ] Executei o laboratório;
- [ ] Inspecionei os recursos com `describe/list`;
- [ ] Provoquei ao menos uma falha;
- [ ] Diagnostiquei antes de corrigir;
- [ ] Consigo justificar a escolha do serviço;
- [ ] Consigo explicar as pegadinhas ACE;
- [ ] Fiz o cleanup.

---

# 9. O que memorizar

Não memorize apenas comandos. Memorize a relação:

```text
Requisito
   ↓
Serviço/recurso correto
   ↓
Escopo correto
   ↓
Permissão correta
   ↓
Operação correta
   ↓
Troubleshooting com evidência
```

Essa é a forma de raciocínio mais útil para o Associate Cloud Engineer.

