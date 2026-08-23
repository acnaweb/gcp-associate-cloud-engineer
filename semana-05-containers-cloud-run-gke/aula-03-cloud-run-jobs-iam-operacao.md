# Aula 3 — Cloud Run Jobs, IAM e Operação

## Objetivos

Ao final desta aula, você deverá:

- Entender Cloud Run Jobs;
- Diferenciar Service e Job;
- Entender Service Account de runtime;
- Entender IAM;
- Trabalhar com logs;
- Entender variáveis e secrets em nível conceitual.

---

# 1. Service x Job

## Cloud Run Service

Recebe requisições/eventos continuamente.

```text
Request
   ↓
Service
   ↓
Response
```

## Cloud Run Job

Executa tarefas até a conclusão.

```text
Start
  ↓
Task
  ↓
Complete
```

---

# 2. Casos de uso para Jobs

- Batch;
- ETL curto;
- Processamento agendado;
- Migração;
- Scripts administrativos;
- Workers finitos.

---

# 3. Criar Job

```bash
PROJECT_ID=$(gcloud config get-value project)

gcloud run jobs create ace-job \
  --image=southamerica-east1-docker.pkg.dev/$PROJECT_ID/ace-containers/ace-web:v1 \
  --region=southamerica-east1
```

---

# 4. Executar Job

```bash
gcloud run jobs execute ace-job \
  --region=southamerica-east1
```

---

# 5. Tasks

Um job pode executar múltiplas tasks.

```text
Job Execution
   │
   ├── Task 1
   ├── Task 2
   └── Task 3
```

Tasks podem ser paralelas, dependendo da configuração.

---

# 6. Service Account de runtime

Modelo:

```text
Cloud Run
   │
   │ runs as
   ▼
Service Account
   │
   ▼
Google Cloud APIs
```

Conceda somente as roles necessárias.

---

# 7. Exemplo

Cloud Run precisa ler BigQuery:

```text
Service Account
      +
roles/bigquery.dataViewer
```

Evite:

```text
roles/editor
```

---

# 8. Atualizar Service Account

```bash
gcloud run services update ace-web \
  --region=southamerica-east1 \
  --service-account=ace-runtime-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

# 9. Logs

Listar logs:

```bash
gcloud run services logs read ace-web \
  --region=southamerica-east1
```

Logs também aparecem no Cloud Logging.

---

# 10. Secrets

Não coloque senha diretamente em variável versionada.

Prefira:

```text
Secret Manager
```

Modelo:

```text
Cloud Run
   │
   ▼
Secret Manager
```

---

# 11. Troubleshooting

Se o serviço falhar:

```text
1. Image existe?
2. Porta correta?
3. Container inicia?
4. IAM correto?
5. Service Account tem role?
6. Environment vars?
7. Logs?
8. Quotas?
```

---

# 12. Service x Job — decisão

| Cenário | Serviço |
|---|---|
| API HTTP | Cloud Run Service |
| Site web containerizado | Cloud Run Service |
| Batch diário | Cloud Run Job |
| Script finito | Cloud Run Job |

---

# 13. Questões Estilo ACE

## Questão 1

Processamento noturno deve iniciar, executar e terminar.

**Resposta:** Cloud Run Job.

## Questão 2

API precisa acessar BigQuery.

**Resposta:** Service Account com role mínima necessária.

## Questão 3

Container falha ao iniciar.

**Resposta:** verificar logs, image, porta e configuração.

---

# 14. Checklist

- [ ] Entendo Cloud Run Job
- [ ] Sei diferenciar Service e Job
- [ ] Entendo Service Account de runtime
- [ ] Entendo least privilege
- [ ] Sei consultar logs
- [ ] Sei o papel do Secret Manager
