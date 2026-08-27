# Aula 3 — Cloud Run Jobs, IAM e Operação

## Objetivos

Ao final desta aula, você deverá:

- Criar Cloud Run Job;
- Executar manualmente;
- Configurar Service Account;
- Ler executions/logs;

---

# 1. Modelo mental

```text
Scheduler/manual ──> Cloud Run Job
                    └─ execution ── task(s)
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
export REGION=us-central1
gcloud services enable run.googleapis.com

gcloud run jobs create ace-job \
  --image=alpine \
  --region=$REGION \
  --command=sh \
  --args=-c,'echo ACE Job; date'

gcloud run jobs execute ace-job \
  --region=$REGION \
  --wait

gcloud run jobs executions list \
  --job=ace-job \
  --region=$REGION
```

Service Account:
```bash
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create ace-job-sa

gcloud run jobs update ace-job \
  --region=$REGION \
  --service-account=ace-job-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

# 4. Testes e falhas propositais

- Use comando `exit 1` numa nova versão do job e observe execution FAILED.
- Service account de runtime define identidade do job para APIs Google.
- Job não precisa ficar ouvindo porta HTTP.

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

- Service ≠ Job.
- Invoker executa/chama; runtime SA define o que workload pode acessar.
- Falha de job: olhar execution + logs.

---

# 7. Questões estilo ACE

- Processo batch diário containerizado? → Cloud Run Job.
- Endpoint HTTP escalável? → Cloud Run Service.

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

