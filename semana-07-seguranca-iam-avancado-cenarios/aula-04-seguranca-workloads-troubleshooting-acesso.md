# Aula 4 — Segurança de Workloads e Troubleshooting de Acesso

## Objetivos

Ao final desta aula, você deverá:

- Investigar PermissionDenied;
- Usar Policy Troubleshooter quando disponível;
- Validar SA de runtime;
- Distinguir authn/authz;

---

# 1. Modelo mental

```text
Request
  ↓ authentication: quem é?
  ↓ authorization: pode?
  ↓ resource policy / IAM condition
  ↓ allow/deny
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

Crie SA sem acesso:
```bash
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create ace-noaccess
```

Crie bucket:
```bash
export BUCKET=gs://$PROJECT_ID-ace-sec-$RANDOM
gcloud storage buckets create $BUCKET --location=us-central1
echo secret > arquivo.txt
gcloud storage cp arquivo.txt $BUCKET/
```

Roteiro de diagnóstico de 403:
```bash
gcloud auth list
gcloud config get-value account
gcloud projects get-iam-policy $PROJECT_ID
gcloud storage buckets get-iam-policy $BUCKET
gcloud iam service-accounts get-iam-policy \
  ace-noaccess@$PROJECT_ID.iam.gserviceaccount.com
```

No Console: IAM & Admin → Policy Troubleshooter.
Teste principal + permission + resource para explicar por que acesso é permitido/negado.

---

# 4. Testes e falhas propositais

- Não resolva 403 concedendo Owner.
- Cheque principal efetivo (especialmente com impersonation).
- IAM Conditions e deny policies podem alterar resultado.

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

- 401 costuma apontar autenticação/token; 403 autorização.
- Policy Troubleshooter ajuda explicar decisão.
- Least privilege é correção preferida.

---

# 7. Questões estilo ACE

- 403 em Storage: verificar principal, role/binding, condition, resource.
- Workload usa SA errada: corrigir runtime identity antes de aumentar permissões.

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

