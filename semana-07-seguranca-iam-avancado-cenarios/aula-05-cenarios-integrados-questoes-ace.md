# Aula 5 — Cenários Integrados e Questões Estilo ACE

## Objetivos

Ao final desta aula, você deverá:

- Resolver cenários combinando IAM, compute, network e data;
- Escolher a solução com menor privilégio;
- Interpretar perguntas de prova;
- Evitar respostas excessivamente amplas.

---

# 1. Método de resolução

Pergunte:

```text
1. Qual é o objetivo?
2. Quem precisa acessar?
3. Qual recurso?
4. Qual permissão mínima?
5. Em qual escopo?
6. Precisa credencial persistente?
7. Existe opção gerenciada?
```

---

# 2. Cenário — Cloud Run + BigQuery

```text
Cloud Run
   │
Runtime SA
   │
roles/bigquery.dataViewer
   ▼
BigQuery
```

Não use:

```text
Owner
Editor
```

---

# 3. Cenário — VM privada + Storage

```text
Private VM
   │
Service Account
   │
Storage role
   ▼
Cloud Storage
```

Se também precisa internet:

```text
Cloud NAT
```

IAM e rede são problemas diferentes.

---

# 4. Cenário — Administrador temporário

Usuário precisa privilégio elevado por período curto.

Melhores ideias:

```text
Temporary conditional access
or
Service Account impersonation
```

Evite criar chave permanente.

---

# 5. Cenário — CI/CD externo

Pipeline fora do Google Cloud precisa deploy.

Prefira:

```text
External identity
   ↓
Workload Identity Federation
   ↓
Service Account / IAM
```

---

# 6. Cenário — GKE workload

Pod precisa acessar API Google.

Prefira identidade de workload em vez de distribuir chave JSON.

---

# 7. Cenário — acesso a bucket específico

Necessidade:

> Ler somente um bucket.

Melhor:

```text
roles/storage.objectViewer
on specific bucket
```

em vez de no projeto inteiro.

---

# 8. Questões Estilo ACE

## Questão 1

Um usuário precisa executar comandos como uma Service Account durante troubleshooting, sem armazenar uma chave localmente.

A. Criar JSON key  
B. Tornar usuário Owner  
C. Usar Service Account Impersonation  
D. Tornar SA pública

**Resposta: C**

---

## Questão 2

Aplicação no Cloud Run precisa apenas ler objetos de um bucket.

A. Editor no projeto  
B. Owner no bucket  
C. Storage Object Viewer no bucket  
D. Viewer na organização

**Resposta: C**

---

## Questão 3

Workload em AWS precisa acessar APIs Google sem usar chave estática.

A. Basic Role  
B. Workload Identity Federation  
C. Public bucket  
D. Editor

**Resposta: B**

---

## Questão 4

Usuário deve ter acesso apenas até sexta-feira.

A. Owner  
B. IAM Condition  
C. Static key  
D. Shared account

**Resposta: B**

---

## Questão 5

A aplicação retorna timeout ao acessar outro servidor.

A. Adicionar Editor  
B. Adicionar Owner  
C. Verificar rota/firewall/DNS  
D. Criar Service Account Key

**Resposta: C**

---

# 9. Regra de Ouro

Quando houver duas respostas possíveis, prefira a que:

```text
Uses managed identity
+
Uses least privilege
+
Avoids long-lived credentials
+
Restricts scope
```

---

# 10. Revisão Visual

```text
IAM
│
├── Principal
├── Role
├── Resource
├── Condition
│
├── Service Accounts
│   ├── User
│   ├── Token Creator
│   └── Impersonation
│
├── Federation
│
└── Troubleshooting
    ├── Policy
    ├── Credential
    ├── Scope
    └── Audit
```

---

# 11. Checklist Final

- [ ] Resolvo cenários de least privilege
- [ ] Sei quando usar impersonation
- [ ] Sei quando usar IAM Conditions
- [ ] Sei quando usar federation
- [ ] Sei separar IAM, rede e quota
- [ ] Evito respostas com Owner/Editor sem necessidade
