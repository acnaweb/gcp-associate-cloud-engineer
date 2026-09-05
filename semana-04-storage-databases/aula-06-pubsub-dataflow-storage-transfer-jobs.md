# Aula 6 — Pub/Sub, Dataflow, Storage Transfer e Jobs

## Cobertura no exam guide

Exam Guide 3.3, 3.4 e 4.4: Pub/Sub, Dataflow, eventos, Storage Transfer Service e revisão de status de jobs.

**Custos:** não crie Dataflow jobs sem necessidade; jobs podem gerar cobrança de compute.

## 1. Conceito

Pub/Sub desacopla produtores e consumidores por mensagens. Dataflow executa pipelines batch/stream Apache Beam. Storage Transfer Service move dados entre origens suportadas e Cloud Storage. A ACE deve reconhecer e operar o básico, não desenvolver pipelines Beam complexos.

### Arquitetura / modelo mental

```text
Producer → Pub/Sub Topic → Subscription → Consumer
Data source → Dataflow job → sink
External/GCS source → Storage Transfer Service → GCS
```

## 2. Criar / Configurar

Pub/Sub hands-on:

```bash
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable pubsub.googleapis.com dataflow.googleapis.com storagetransfer.googleapis.com
# Explicação: Cria um tópico Pub/Sub para receber mensagens dos produtores.
gcloud pubsub topics create ace-topic
# Explicação: Cria uma subscription associada ao tópico Pub/Sub para permitir consumo das mensagens.
gcloud pubsub subscriptions create ace-sub --topic=ace-topic
```

Para Dataflow/Storage Transfer, liste jobs/configurações antes de provisionar pipelines que possam gerar custo.

## 3. Inspecionar

```bash
# Explicação: Lista tópicos Pub/Sub existentes para confirmar a criação e localizar o recurso do laboratório.
gcloud pubsub topics list
# Explicação: Exibe a configuração da subscription Pub/Sub, incluindo o tópico associado e parâmetros de entrega.
gcloud pubsub subscriptions describe ace-sub
# Explicação: Lista jobs Dataflow para verificar estado e identificar a execução do laboratório.
gcloud dataflow jobs list --region=us-central1
# Explicação: Lista jobs do Storage Transfer Service para acompanhar transferências configuradas.
gcloud transfer jobs list 2>/dev/null || true
```

> A partir deste ponto, todos os elementos usados no troubleshooting já foram apresentados e inspecionados.

## 4. Testar

```bash
# Explicação: Publica uma mensagem no tópico Pub/Sub para testar o fluxo de eventos.
gcloud pubsub topics publish ace-topic --message='ACE'
# Explicação: Consome mensagens disponíveis na subscription; `--auto-ack` confirma automaticamente o recebimento.
gcloud pubsub subscriptions pull ace-sub --auto-ack --limit=1
```

## 5. Quebrar propositalmente

Publique uma mensagem e tente puxar de uma subscription com nome incorreto: `ace-sub-errada`.

## 6. Troubleshooting

**Sintoma:** recurso não encontrado.
**Hipótese:** subscription ID incorreto.
**Evidência:** `gcloud pubsub subscriptions list`.
**Causa:** nome deliberadamente errado.
**Correção:** usar `ace-sub`.

Para Dataflow, quando um job falhar, primeiro liste e descreva o **job**, antes de supor erro de Pub/Sub ou Storage.

Use a sequência:

```text
Sintoma → Hipótese → Evidência → Causa → Correção
```

## 7. Corrigir

Repita pull com a subscription correta. Registre a matriz: Pub/Sub=mensageria, Dataflow=pipeline, Storage Transfer=movimentação gerenciada de objetos/dados suportados.

## 8. Questões estilo ACE

1. Desacoplar eventos? **Pub/Sub**.
2. Pipeline Apache Beam batch/stream? **Dataflow**.
3. Mover grande conjunto de objetos de fonte suportada para Cloud Storage? **Storage Transfer Service**.
4. Ver execução Dataflow? **Dataflow jobs**.

## 9. Cleanup

```bash
# Explicação: Exclui a subscription Pub/Sub do laboratório.
gcloud pubsub subscriptions delete ace-sub --quiet
# Explicação: Exclui o tópico Pub/Sub criado no laboratório.
gcloud pubsub topics delete ace-topic --quiet
```

## Checklist

- [ ] Consigo explicar os conceitos sem consultar;
- [ ] Sei localizar o recurso no Console e/ou CLI;
- [ ] Executei ou simulei o laboratório indicado;
- [ ] Inspecionei a configuração antes de provocar a falha;
- [ ] Diagnostiquei a falha com evidências;
- [ ] Sei reconhecer a alternativa correta em uma questão de cenário.


---

# Cobertura ACE ampliada — data products e job status

## Pub/Sub

Modelo:

```text
Publisher → Topic → Subscription → Subscriber
```

Comandos básicos:

```bash
# Explicação: Cria um tópico Pub/Sub para receber mensagens dos produtores.
gcloud pubsub topics create ace-topic
# Explicação: Cria uma subscription associada ao tópico Pub/Sub para permitir consumo das mensagens.
gcloud pubsub subscriptions create ace-sub --topic=ace-topic
# Explicação: Publica uma mensagem no tópico Pub/Sub para testar o fluxo de eventos.
gcloud pubsub topics publish ace-topic --message='ACE'
# Explicação: Consome mensagens disponíveis na subscription; `--auto-ack` confirma automaticamente o recebimento.
gcloud pubsub subscriptions pull ace-sub --auto-ack --limit=1
```

## Dataflow

Dataflow executa pipelines Apache Beam para batch/streaming. Para ACE, reconheça:

```text
Pub/Sub → Dataflow → BigQuery
```

E saiba revisar job status:

```bash
# Explicação: Lista jobs Dataflow para verificar estado e identificar a execução do laboratório.
gcloud dataflow jobs list --region=us-central1
```

## BigQuery jobs

```bash
# Explicação: Lista datasets, tabelas ou jobs BigQuery conforme o argumento.
bq ls -j -a -n 10
```

Job status é parte explícita do escopo operacional.

## Filestore, NetApp Volumes e Managed Lustre

Matriz de storage:

```text
Cloud Storage        → object storage
Filestore            → NFS gerenciado para arquivos
NetApp Volumes       → file storage empresarial com capacidades NetApp
Managed Lustre       → filesystem paralelo para HPC/AI
Persistent Disk      → block storage para VMs
```

Escolha pelo protocolo e workload, não apenas pela capacidade.


---

## Prática adicional — Dataflow Job e Storage Transfer

### Dataflow — elevar de “listar jobs” para “executar e analisar job”

**Custos:** Dataflow cria recursos de compute. Execute apenas em projeto de laboratório e faça cleanup.

Crie um bucket temporário:

```bash
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)
# Explicação: Define a variável `DF_BUCKET` usada nas próximas etapas do laboratório.
export DF_BUCKET="gs://$PROJECT_ID-ace-dataflow-$RANDOM"
# Explicação: Cria um bucket Cloud Storage com localização e opções informadas.
gcloud storage buckets create "$DF_BUCKET" --location=us-central1
```

Execute um template de exemplo suportado na região:

```bash
# Explicação: Inicia um job Dataflow a partir do template e parâmetros informados.
gcloud dataflow jobs run ace-wordcount \
  --gcs-location=gs://dataflow-templates-us-central1/latest/Word_Count \
  --region=us-central1 \
  --staging-location="$DF_BUCKET/staging" \
  --parameters inputFile=gs://dataflow-samples/shakespeare/kinglear.txt,output="$DF_BUCKET/output/result"
```

Inspecione:

```bash
# Explicação: Lista jobs Dataflow para verificar estado e identificar a execução do laboratório.
gcloud dataflow jobs list --region=us-central1
```

Pegue o `JOB_ID` real e descreva:

```bash
# Explicação: Exibe detalhes e estado do job Dataflow selecionado.
gcloud dataflow jobs describe JOB_ID --region=us-central1
```

Agora “job status” deixou de ser apenas mencionado.

### Falha proposital

Use um `JOB_ID` inexistente em `describe` e confirme primeiro a lista real antes de investigar pipeline, Pub/Sub ou IAM.

### Storage Transfer Service — prática guiada

O guia exige uso do serviço. Para evitar transferência desnecessária de grande volume:

1. crie dois buckets pequenos de laboratório;
2. coloque um objeto no bucket origem;
3. no Console abra **Storage Transfer → Create a transfer**;
4. escolha origem Cloud Storage e destino Cloud Storage;
5. execute transferência imediata;
6. valide o objeto no destino;
7. exclua o transfer job.

Modelo:

```text
Source bucket
    ↓ Storage Transfer Service
Destination bucket
```

Não confunda `gcloud storage cp` (cópia direta pelo cliente) com Storage Transfer Service (serviço gerenciado de transferência).

### Cleanup Dataflow

Depois do job terminar:

```bash
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm --recursive "$DF_BUCKET/**" 2>/dev/null || true
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$DF_BUCKET" --quiet
```

---

<!-- MEP-ACCEPTANCE-V8 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v8.

Para um tópico ser classificado como `P` nesta baseline, não basta existir um comando. A aula precisa apresentar:

```text
conceito operacional
   ↓
configuração/comando
   ↓
inspeção
   ↓
teste ou comportamento observável
```

Quando a execução depender de Organization, privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.

## Tópicos do guia mapeados para esta aula

| Seção | Tópico | Esperado | Nível da matriz |
|---|---|---:|---:|
| 3.4 | Pub/Sub | `P` | `P` |
| 3.4 | Dataflow | `P` | `P` |
| 3.4 | Storage Transfer Service | `P` | `P*` |
| 4.4 | Status Dataflow jobs | `P` | `P` |
