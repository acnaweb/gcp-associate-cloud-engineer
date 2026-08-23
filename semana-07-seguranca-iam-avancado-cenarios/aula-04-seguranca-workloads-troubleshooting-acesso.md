# Aula 4 — Segurança de Workloads e Troubleshooting de Acesso

## Objetivos

Ao final desta aula, você deverá:

- Entender segurança de identidade para workloads;
- Aplicar least privilege;
- Troubleshootar `permission denied`;
- Entender Policy Troubleshooter em nível conceitual;
- Analisar IAM, rede e autenticação separadamente.

---

# 1. Segurança de Workload

Modelo recomendado:

```text
Workload
   │
Dedicated Service Account
   │
Minimal Roles
   │
Specific Resources
```

---

# 2. Evite identidade compartilhada

Ruim:

```text
Multiple apps
    ↓
Same Service Account
    ↓
roles/editor
```

Melhor:

```text
App A → SA-A → specific roles
App B → SA-B → specific roles
```

---

# 3. `Permission denied`

Fluxo:

```text
Who is calling?
      ↓
Which credential?
      ↓
Which principal?
      ↓
Which resource?
      ↓
Which permission is required?
      ↓
Which role grants it?
      ↓
At which scope?
```

---

# 4. Ver identidade ativa

```bash
gcloud auth list
```

---

# 5. Ver projeto

```bash
gcloud config get-value project
```

---

# 6. Ver IAM Policy

```bash
gcloud projects get-iam-policy PROJECT_ID
```

---

# 7. Impersonation Troubleshooting

Verifique:

- Service Account Credentials API;
- Token Creator;
- Nome correto da Service Account;
- Recurso alvo;
- Role efetiva da Service Account.

---

# 8. Policy Troubleshooter

Ferramenta conceitualmente usada para responder:

> Por que esse principal tem ou não tem acesso?

Ela considera:

- Principal;
- Permission;
- Resource;
- Policies aplicáveis.

---

# 9. IAM x Network

Não confunda:

```text
Permission denied
→ IAM/authentication
```

com:

```text
Connection timed out
→ network/firewall/DNS/application
```

---

# 10. IAM x Quota

```text
403 permission denied
→ IAM likely
```

```text
quota exceeded
→ quota/capacity
```

---

# 11. Logs de Auditoria

Cloud Audit Logs ajudam a investigar ações administrativas e acessos compatíveis.

Modelo:

```text
Who
What
When
Where
```

---

# 12. Questões Estilo ACE

## Questão 1

Cloud Run recebe 403 ao acessar BigQuery.

Verifique:

**Resposta:** Service Account de runtime + role correta no BigQuery.

## Questão 2

VM não alcança endpoint TCP.

**Resposta:** não assumir IAM; verificar rede/firewall/rota.

## Questão 3

Usuário consegue impersonar SA, mas SA não acessa bucket.

**Resposta:** a própria Service Account precisa da role adequada no bucket.

---

# 13. Checklist

- [ ] Entendo identidade dedicada por workload
- [ ] Sei investigar permission denied
- [ ] Sei separar IAM de rede
- [ ] Entendo Policy Troubleshooter
- [ ] Entendo Audit Logs
