# Aula 5 — Cenários Integrados e Questões Estilo ACE

## Objetivos

Ao final desta aula, você deverá:

- Resolver cenários least privilege;
- Combinar IAM, rede e runtime identity;
- Treinar troubleshooting de acesso;

---

# 1. Modelo mental

```text
Usuário/Workload
  ↓ identity
IAM binding/condition
  ↓
Resource
  ↕
Network path (quando aplicável)
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

### Caso 1 — VM lê bucket
Desenhe:
```text
VM
 └─ Service Account
      └─ roles/storage.objectViewer
           └─ Bucket
```
Pergunte:
- Quem é o principal?
- Em qual escopo conceder?
- A VM precisa de key JSON? Não.

### Caso 2 — CI/CD externo
```text
GitHub OIDC
   ↓ WIF
Google identity
   ↓ impersonation/permissions
Deploy Cloud Run
```

### Caso 3 — usuário temporário
Use IAM Condition com expiração em vez de lembrar de remover manualmente quando o caso comportar.

### Checklist de comandos
```bash
gcloud auth list
gcloud projects get-iam-policy PROJECT_ID
gcloud iam service-accounts list
gcloud iam roles describe ROLE
gcloud logging read 'protoPayload.status.code=7' --limit=20
```

---

# 4. Testes e falhas propositais

- Conceder role no nível errado aumenta blast radius.
- Key SA é último recurso, não default.
- Rede pode estar perfeita e IAM negar; IAM pode estar perfeito e rede falhar.

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

- Identidade + escopo + role + condição.
- Escolha mínima que resolve requisito.
- Use logs/audit para evidência.

---

# 7. Questões estilo ACE

- Cloud Run precisa ler um bucket específico: runtime SA + role mínima no bucket.
- Fornecedor externo sem conta Google precisa acesso temporário: federação/WIF quando compatível.

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

