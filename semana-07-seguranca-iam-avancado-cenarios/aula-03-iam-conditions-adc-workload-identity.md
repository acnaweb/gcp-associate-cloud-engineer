# Aula 3 — IAM Conditions, ADC e Workload Identity Federation

## Objetivos

Ao final desta aula, você deverá:

- Entender IAM Conditions;
- Entender acesso baseado em atributos;
- Entender ADC em nível conceitual;
- Entender Workload Identity Federation;
- Saber escolher métodos de autenticação.

---

# 1. IAM Conditions

IAM Conditions adiciona condição a um role binding.

```text
Principal
  +
Role
  +
Condition
```

Exemplo:

```text
Grant access only until date X
```

ou:

```text
Grant access only to resources matching attribute
```

---

# 2. Modelo

```text
Role Binding
   │
   ├── Principal
   ├── Role
   └── Condition
```

---

# 3. Acesso Temporário

Exemplo conceitual:

```text
roles/storage.objectViewer
until
2026-12-31
```

---

# 4. Limitação importante

Conditions não são aplicáveis a todos os tipos de binding.

Para a prova, lembre que basic roles legadas como:

```text
Owner
Editor
Viewer
```

não são o cenário ideal para Conditions.

---

# 5. ADC — Application Default Credentials

ADC é um mecanismo usado por bibliotecas e ferramentas Google para localizar credenciais automaticamente.

Modelo:

```text
Application
   │
   ▼
ADC
   │
   ▼
Available Identity
```

---

# 6. ADC em desenvolvimento

Em desenvolvimento local:

```bash
gcloud auth application-default login
```

ou use impersonation quando a aplicação precisa agir como Service Account.

---

# 7. Workload Identity Federation

Permite que workloads externos autentiquem sem usar chaves persistentes de Service Account.

Modelo:

```text
External Workload
      │
External Identity
      │
      ▼
Workload Identity Federation
      │
      ▼
Google Cloud
```

---

# 8. Casos de uso

- AWS workload acessando GCP;
- Azure workload acessando GCP;
- On-premises;
- CI/CD externo;
- GitHub/OIDC compatível.

---

# 9. GKE

Para GKE, existe integração de identidade para workloads Kubernetes.

Modelo:

```text
Kubernetes Pod
      │
      ▼
Workload Identity
      │
      ▼
Google Cloud IAM
```

---

# 10. Escolha de autenticação

```text
Running on Google Cloud?
   │
   ├── Yes → attached identity / workload identity
   │
   └── No
        │
        ├── Federation possible? → use federation
        │
        └── Otherwise → key only if necessary
```

---

# 11. Questões Estilo ACE

## Questão 1

Acesso deve expirar automaticamente após determinada data.

**Resposta:** IAM Conditions.

## Questão 2

Workload em outra cloud precisa acessar GCP sem JSON key.

**Resposta:** Workload Identity Federation.

## Questão 3

Biblioteca cliente precisa descobrir credenciais padrão.

**Resposta:** Application Default Credentials.

---

# 12. Checklist

- [ ] Entendo IAM Conditions
- [ ] Entendo acesso temporário
- [ ] Entendo ADC
- [ ] Entendo Workload Identity Federation
- [ ] Entendo identidade de workload em GKE
