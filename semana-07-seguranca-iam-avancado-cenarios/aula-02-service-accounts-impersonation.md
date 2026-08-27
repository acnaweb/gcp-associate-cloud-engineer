# Aula 2 — Service Accounts, User, Token Creator e Impersonation

## Objetivos

Ao final desta aula, você deverá:

- Diferenciar Service Account User e Token Creator;
- Praticar impersonation;
- Evitar keys persistentes;
- Entender attach x impersonate;

---

# 1. Modelo mental

```text
User
 ├─ Service Account User → anexar/usar SA em recurso
 └─ Token Creator → gerar credencial curta/impersonar
                         ↓
                    Service Account
                         ↓
                     API resource
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
export SA=ace-impersonation@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts create ace-impersonation
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA" \
  --role="roles/viewer"
```

Conceda Token Creator ao seu usuário (somente em projeto de laboratório):
```bash
export USER=$(gcloud config get-value account)

gcloud iam service-accounts add-iam-policy-binding $SA \
  --member="user:$USER" \
  --role="roles/iam.serviceAccountTokenCreator"
```

Teste:
```bash
gcloud projects describe $PROJECT_ID \
  --impersonate-service-account=$SA
```

Compare:
```bash
gcloud auth print-access-token \
  --impersonate-service-account=$SA | head -c 20
echo
```

---

# 4. Testes e falhas propositais

- Remova Token Creator e repita impersonation.
- Impersonation usa credenciais curtas; não exige baixar JSON key.
- Service Account User não implica automaticamente Token Creator.

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

- Attach SA e impersonate SA são ações distintas.
- Preferir impersonation/federation a chaves persistentes.
- Runtime SA deve ter apenas roles necessárias.

---

# 7. Questões estilo ACE

- Usuário precisa gerar token da SA? → Service Account Token Creator.
- Usuário precisa anexar SA a uma VM? → Service Account User, além de permissões do recurso.

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

