# Aula 3 — Cloud Run Jobs, IAM e Operação

## Objetivos

Ao final, você deverá:

- diferenciar Cloud Run Service de Cloud Run Job;
- explicar a relação entre **Job, Execution e Task**;
- criar uma container image batch e publicá-la no Artifact Registry;
- criar, inspecionar e atualizar um Cloud Run Job via `gcloud`;
- criar e associar uma **runtime Service Account**;
- diferenciar a identidade do operador da identidade de runtime;
- executar o Job e inspecionar Executions e logs;
- configurar e testar **tasks** e **parallelism**;
- explicar e configurar **retries** e **timeout**;
- provocar uma falha determinística com `exit 1`, diagnosticar e corrigir;
- aplicar menor privilégio e realizar cleanup.

> [!IMPORTANT]
> ## Pré-requisito — Aulas 1 e 2
>
> Este laboratório reutiliza o **Artifact Registry** criado na Aula 1. O repositório `ace-containers-lab` deve existir. Se você executou o cleanup remoto da Aula 1, recrie o repositório. A image Nginx da Aula 2 não será usada como Job: criaremos uma image batch própria, que termina sua execução.

## 1. Service x Job

| Característica | Service | Job |
|---|---|---|
| Modelo | request/response | run-to-completion |
| Endpoint para servir tráfego | Sim | Não |
| Unidade operacional | Revision / Instance | Execution / Task |
| Escala | `concurrency` de requests | `parallelism` de tasks |
| Exemplo | API REST | ETL, batch, manutenção |

```text
Cloud Run Service                 Cloud Run Job
requests                             Job
   |                                  |
   v                                  v
Revision                           Execution
   |                                  |
Instances                         Task(s)
```

## 2. Job, Execution e Task

O **Job** é a configuração persistente. Cada `execute` cria uma **Execution**. Uma Execution contém uma ou mais **Tasks**.

```text
ace-job
  |
  +-- Execution A
  |     +-- Task 0
  |     +-- Task 1
  |
  +-- Execution B
        +-- Task 0
        +-- Task 1
```

Executar novamente não cria outro Job: cria outra Execution.

## 3. Variáveis e preflight

```bash
# Recupera o projeto ativo.
export PROJECT_ID="$(gcloud config get-value project)"
# Define a região.
export REGION="southamerica-east1"
# Reutiliza o repositório da Aula 1.
export REPO="ace-containers-lab"
# Define o host do Artifact Registry.
export HOST="${REGION}-docker.pkg.dev"
# Define o Job e sua identidade.
export JOB="ace-job"
export JOB_SA="ace-job-sa"
export JOB_SA_EMAIL="${JOB_SA}@${PROJECT_ID}.iam.gserviceaccount.com"
# Define a image batch.
export JOB_IMAGE="${HOST}/${PROJECT_ID}/${REPO}/ace-job:v1"
# Habilita APIs.
gcloud services enable run.googleapis.com artifactregistry.googleapis.com iam.googleapis.com --project="$PROJECT_ID"
# Valida o repositório herdado.
gcloud artifacts repositories describe "$REPO" --location="$REGION" --project="$PROJECT_ID"
```

Se houver `NOT_FOUND`, recrie o Artifact Registry conforme a Aula 1.

## 4. Criar e publicar a image batch

```bash
# Cria diretório do laboratório.
mkdir -p ace-job-image
cd ace-job-image
# Cria uma image que executa e termina.
cat > Dockerfile <<'EOF'
FROM alpine:3
CMD ["sh", "-c", "echo 'ACE Cloud Run Job'; echo \"Task index=${CLOUD_RUN_TASK_INDEX:-0}\"; echo \"Task count=${CLOUD_RUN_TASK_COUNT:-1}\"; date; exit 0"]
EOF
# Constrói a image.
docker build -t ace-job:v1 .
# Configura autenticação Docker.
gcloud auth configure-docker "$HOST" --quiet
# Cria a tag remota.
docker tag ace-job:v1 "$JOB_IMAGE"
# Publica a image.
docker push "$JOB_IMAGE"
# Confirma image/tag.
gcloud artifacts docker images list "${HOST}/${PROJECT_ID}/${REPO}" --include-tags
```

## 5. Runtime Service Account e IAM

```text
usuário/deployer
      |
      | cria/configura/executa
      v
 Cloud Run Job
      |
      | executa COMO
      v
Runtime Service Account
      |
      v
recursos GCP
```

A runtime Service Account não precisa de `roles/run.admin` apenas para o container executar. Quem configura um Job para usar uma Service Account precisa de `iam.serviceAccounts.actAs`; `roles/iam.serviceAccountUser` inclui essa capacidade.

```bash
# Cria identidade dedicada ao runtime.
gcloud iam service-accounts create "$JOB_SA" --display-name="ACE Cloud Run Job runtime" --project="$PROJECT_ID"
# Inspeciona a identidade.
gcloud iam service-accounts describe "$JOB_SA_EMAIL" --project="$PROJECT_ID"
# Identifica o operador.
export ACTIVE_ACCOUNT="$(gcloud auth list --filter='status:ACTIVE' --format='value(account)')"
# Mostra a conta ativa.
echo "$ACTIVE_ACCOUNT"
# Inspeciona IAM da runtime Service Account.
gcloud iam service-accounts get-iam-policy "$JOB_SA_EMAIL" --project="$PROJECT_ID"
```

> [!NOTE]
> Se sua conta não possuir `iam.serviceAccounts.actAs`, solicite a concessão apropriada no escopo definido pela organização. Não use papéis amplos como atalho.

## 6. Criar e inspecionar o Job

```bash
# Cria o Job com identidade e controles explícitos.
gcloud run jobs create "$JOB"   --image="$JOB_IMAGE"   --region="$REGION"   --service-account="$JOB_SA_EMAIL"   --tasks=1   --parallelism=1   --max-retries=1   --task-timeout=60s
# Inspeciona configuração.
gcloud run jobs describe "$JOB" --region="$REGION"
# Lista Jobs.
gcloud run jobs list --region="$REGION"
```

Localize runtime Service Account, tasks, parallelism, retries e timeout.

## 7. Executar e inspecionar Executions

```bash
# Executa e aguarda.
gcloud run jobs execute "$JOB" --region="$REGION" --wait
# Lista executions.
gcloud run jobs executions list --job="$JOB" --region="$REGION"
# Captura a mais recente.
export EXECUTION="$(gcloud run jobs executions list --job="$JOB" --region="$REGION" --sort-by='~createTime' --limit=1 --format='value(metadata.name)')"
# Exibe o identificador.
echo "$EXECUTION"
# Inspeciona a execution.
gcloud run jobs executions describe "$EXECUTION" --region="$REGION"
```

## 8. Logs: Job → Execution → Task

```bash
# Consulta logs do Job.
gcloud logging read "resource.type=\"cloud_run_job\" AND resource.labels.job_name=\"$JOB\""   --project="$PROJECT_ID"   --limit=30   --format="table(timestamp,severity,textPayload)"
```

Observe índice da task, quantidade de tasks, timestamp e erros.

## 9. Tasks e parallelism

`tasks` é a quantidade de unidades de trabalho. `parallelism` limita quantas podem executar simultaneamente.

```text
tasks=4
parallelism=2
tempo ------------------------>
Task 0  =======
Task 1  =======
Task 2          =======
Task 3          =======
```

```bash
# Configura quatro tasks e até duas simultâneas.
gcloud run jobs update "$JOB" --region="$REGION" --tasks=4 --parallelism=2
# Confirma.
gcloud run jobs describe "$JOB" --region="$REGION"
# Executa.
gcloud run jobs execute "$JOB" --region="$REGION" --wait
# Lista executions.
gcloud run jobs executions list --job="$JOB" --region="$REGION"
```

```text
Service                         Job
concurrency                     parallelism
requests por instance           tasks simultâneas
```

## 10. Retries e timeout

Retries tratam falhas potencialmente transitórias; não corrigem erros determinísticos. `task-timeout` limita a duração de cada task.

```text
API externa instável           erro determinístico
tentativa 1 -> falha           exit 1
tentativa 2 -> sucesso         exit 1 novamente
retry pode ajudar              retry não corrige
```

```bash
# Inspeciona retries e timeout configurados.
gcloud run jobs describe "$JOB" --region="$REGION"
```

## 11. Quebrar propositalmente — exit 1

Alteraremos uma variável por vez: somente o comando do container.

```bash
# Simplifica para uma task e desativa retry para diagnóstico determinístico.
gcloud run jobs update "$JOB"   --region="$REGION"   --tasks=1   --parallelism=1   --max-retries=0   --command=sh   --args=-c,'echo "falha proposital"; exit 1'
# Executa esperando falha.
gcloud run jobs execute "$JOB" --region="$REGION" --wait || true
# Lista executions.
gcloud run jobs executions list --job="$JOB" --region="$REGION"
# Captura a execution que falhou.
export FAILED_EXECUTION="$(gcloud run jobs executions list --job="$JOB" --region="$REGION" --sort-by='~createTime' --limit=1 --format='value(metadata.name)')"
# Inspeciona status/condições.
gcloud run jobs executions describe "$FAILED_EXECUTION" --region="$REGION"
# Consulta logs.
gcloud logging read "resource.type=\"cloud_run_job\" AND resource.labels.job_name=\"$JOB\"" --project="$PROJECT_ID" --limit=30 --format="table(timestamp,severity,textPayload)"
```

**Sintoma:** Execution falha. **Hipótese:** task terminou com exit code não zero. **Evidência:** Execution e logs. **Causa:** `exit 1`. **Correção:** restaurar comando que termina com sucesso.

## 12. Corrigir e validar

```bash
# Corrige somente o comando.
gcloud run jobs update "$JOB"   --region="$REGION"   --command=sh   --args=-c,'echo "ACE Job corrigido"; date; exit 0'
# Executa novamente.
gcloud run jobs execute "$JOB" --region="$REGION" --wait
# Confirma nova execution.
gcloud run jobs executions list --job="$JOB" --region="$REGION"
```

A Execution anterior permanece no histórico para diagnóstico.

## 13. Cenários operacionais

- **ETL particionado:** use tasks e limite parallelism conforme a capacidade downstream.
- **API externa instável:** retries podem ajudar em falhas transitórias, desde que repetir seja seguro.
- **Banco com conexões limitadas:** parallelism alto pode sobrecarregar o banco.
- **Processamento travado:** timeout limita a duração.
- **Acesso a GCP:** conceda à runtime Service Account apenas os papéis necessários; não use `roles/editor`.

## 14. Agendamento — visão arquitetural

```text
Agendador / Orquestrador
          |
          v
   Cloud Run Job
          |
          v
      Execution
          |
          v
       Task(s)
```

Agendamento é contexto arquitetural nesta aula; o foco prático é Jobs, IAM e operação.

## 15. Questões estilo ACE

1. Processamento noturno que termina após concluir: **Cloud Run Job**.
2. Executar novamente um Job cria o quê? **Nova Execution**.
3. Unidade de trabalho de uma Execution? **Task**.
4. Cinquenta partições, apenas cinco simultâneas: **parallelism**.
5. Job precisa ler um bucket: dê a permissão necessária à **runtime Service Account**, com menor privilégio.
6. Erro determinístico sempre igual: aumentar retries resolve? **Não; corrija a causa**.
7. Task pode travar: use **task timeout**.
8. Execution falhou: investigue **status da Execution/Task e Cloud Logging**.

## 16. Cleanup

```bash
# Exclui o Job.
gcloud run jobs delete "$JOB" --region="$REGION" --quiet
# Exclui a runtime Service Account do laboratório.
gcloud iam service-accounts delete "$JOB_SA_EMAIL" --project="$PROJECT_ID" --quiet
# Remove somente a image do Job.
gcloud artifacts docker images delete "$JOB_IMAGE" --delete-tags --quiet
# Volta à pasta anterior.
cd ..
# Remove arquivos locais.
rm -rf ace-job-image
```

> [!IMPORTANT]
> O repositório `ace-containers-lab` é compartilhado. Não o exclua neste cleanup.

## 17. M/E/P

| Conteúdo | Nível | Evidência |
|---|---|---|
| Service x Job | E | comparação e cenários |
| Job / Execution / Task | P | create, execute, list, describe |
| Artifact Registry | P | build/tag/push/list |
| Runtime Service Account | P | criação, associação e inspeção |
| IAM / `actAs` / menor privilégio | E/P* | inspeção e orientação por política |
| Tasks / parallelism | P | 4 tasks, parallelism 2 |
| Retries / timeout | E/P | configuração e inspeção |
| Logs | P | Cloud Logging |
| Exit code / troubleshooting | P | `exit 1`, evidência e correção |
| Agendamento | M | contexto arquitetural |

## 18. Mapa mental para a prova

```text
Service -> request -> revision -> instance -> concurrency
Job     -> execute -> execution -> task -> parallelism
deployer/executor != runtime Service Account
```
