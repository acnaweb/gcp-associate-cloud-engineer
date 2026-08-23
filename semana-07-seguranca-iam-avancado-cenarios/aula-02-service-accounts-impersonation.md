# Aula 2 — Service Accounts, User, Token Creator e Impersonation

## Objetivos

Ao final desta aula, você deverá:

- Entender Service Accounts em profundidade;
- Entender Service Account User;
- Entender Service Account Token Creator;
- Entender impersonation;
- Saber por que evitar chaves persistentes.

---

# 1. Service Account

Uma Service Account é uma identidade para workloads.

```text
Workload
   │
   ▼
Service Account
   │
   ▼
Google Cloud APIs
```

---

# 2. Service Account como Principal e Resource

Uma Service Account pode ser:

```text
Principal
→ recebe roles em outros recursos
```

e também:

```text
Resource
→ outras identidades recebem roles sobre ela
```

---

# 3. Service Account User

Role:

```text
roles/iam.serviceAccountUser
```

Concede capacidade de anexar/usar uma Service Account em determinados contextos suportados.

Modelo:

```text
User
  │
  │ Service Account User
  ▼
Service Account
  │
  ▼
Workload
```

---

# 4. Service Account Token Creator

Role:

```text
roles/iam.serviceAccountTokenCreator
```

Permite gerar credenciais de curta duração da Service Account e é central para impersonation.

---

# 5. Impersonation

```text
Authenticated User
       │
       │ impersonates
       ▼
Service Account
       │
       ▼
Short-lived Credentials
       │
       ▼
Google Cloud Resource
```

---

# 6. Por que usar Impersonation?

Vantagens:

- Credenciais temporárias;
- Menor risco que chave persistente;
- Auditoria;
- Evita distribuir JSON keys;
- Útil para desenvolvimento e tarefas administrativas.

---

# 7. Habilitar API

```bash
gcloud services enable iamcredentials.googleapis.com
```

---

# 8. Exemplo de Impersonation

```bash
gcloud storage buckets list \
  --impersonate-service-account=ace-runtime-sa@PROJECT_ID.iam.gserviceaccount.com
```

---

# 9. Conceder Token Creator

Exemplo conceitual:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  ace-runtime-sa@PROJECT_ID.iam.gserviceaccount.com \
  --member="user:usuario@empresa.com" \
  --role="roles/iam.serviceAccountTokenCreator"
```

---

# 10. Chaves de Service Account

Evite quando possível:

```text
service-account-key.json
```

Problemas:

- Persistente;
- Pode ser copiada;
- Pode vazar;
- Difícil de controlar em escala.

---

# 11. Ordem de preferência

Modelo simplificado:

```text
Attached Service Account / Workload Identity
        ↓
Impersonation
        ↓
Federation
        ↓
Persistent Key only when necessary
```

---

# 12. Questões Estilo ACE

## Questão 1

Desenvolvedor precisa testar permissões de uma Service Account sem baixar chave.

**Resposta:** impersonation.

## Questão 2

Usuário precisa gerar access token temporário de uma Service Account.

**Resposta:** Service Account Token Creator.

## Questão 3

Aplicação roda no Google Cloud.

Melhor abordagem?

**Resposta:** anexar identidade apropriada ao workload, evitando chave persistente.

---

# 13. Checklist

- [ ] Entendo Service Account como principal e recurso
- [ ] Entendo Service Account User
- [ ] Entendo Token Creator
- [ ] Entendo impersonation
- [ ] Sei usar `--impersonate-service-account`
- [ ] Sei por que evitar JSON keys
