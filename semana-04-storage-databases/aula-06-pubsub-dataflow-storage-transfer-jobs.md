# Aula 6 — Pub/Sub, Dataflow, Storage Transfer e Jobs

## Objetivos

Ao final, você deverá:
- explicar o modelo de produtores, tópicos, subscriptions e consumidores no Pub/Sub;
- criar e testar um fluxo básico de mensagens Pub/Sub;
- explicar quando Dataflow é usado para processamento batch ou streaming;
- inspecionar o status de jobs Dataflow;
- explicar o papel do Storage Transfer Service;
- reconhecer quando usar upload direto, transferência gerenciada ou processamento de dados.

---


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

### Storage Transfer Service — prática completa via gcloud

O Storage Transfer Service cria **jobs gerenciados de transferência**. Um job define:

```text
origem
  ↓
regras/opções
  ↓
schedule
  ↓
destino
```

Não confunda:

```text
gcloud storage cp
→ o seu cliente executa a cópia

Storage Transfer Service
→ serviço gerenciado executa e acompanha um transfer job
```

#### 1. Preparar os buckets

```bash
# Define o projeto atual.
export PROJECT_ID="$(gcloud config get-value project)"

# Define nomes únicos para origem e destino.
export STS_SOURCE="gs://${PROJECT_ID}-ace-sts-src-$RANDOM"
export STS_DEST="gs://${PROJECT_ID}-ace-sts-dst-$RANDOM"

# Habilita a API do Storage Transfer Service.
gcloud services enable storagetransfer.googleapis.com

# Cria o bucket de origem.
gcloud storage buckets create "$STS_SOURCE" \
  --location=us-central1

# Cria o bucket de destino.
gcloud storage buckets create "$STS_DEST" \
  --location=us-central1

# Cria um arquivo pequeno para provar a transferência.
printf 'ACE Storage Transfer Service
' > /tmp/ace-sts.txt

# Envia o arquivo ao bucket de origem.
gcloud storage cp /tmp/ace-sts.txt "$STS_SOURCE/"
```

Inspecione:

```bash
# Lista o conteúdo da origem antes da transferência.
gcloud storage ls "$STS_SOURCE"
```

#### 2. Entender a identidade do serviço

O Storage Transfer Service usa um **service agent gerenciado pelo Google** para acessar buckets.

Em projetos/ambientes em que as permissões não são concedidas automaticamente, o service agent precisa conseguir:

```text
origem
→ listar/ler objetos

destino
→ criar objetos
```

Se o job falhar com `PERMISSION_DENIED`, investigue primeiro IAM no source/destination e a identidade do Storage Transfer Service.

#### 3. Criar o transfer job

```bash
# Cria um transfer job Cloud Storage → Cloud Storage.
# Sem schedule explícito, o comando inicia a transferência imediatamente,
# salvo quando --do-not-run é utilizado.
gcloud transfer jobs create \
  "$STS_SOURCE" \
  "$STS_DEST" \
  --name="ace-storage-transfer" \
  --description="ACE - transferencia pequena entre buckets"
```

#### 4. Listar e inspecionar jobs

```bash
# Lista jobs do Storage Transfer Service.
gcloud transfer jobs list
```

Identifique o nome real retornado, normalmente no formato:

```text
transferJobs/...
```

Defina:

```bash
# Substitua pelo nome retornado pelo comando anterior.
export STS_JOB="transferJobs/SEU_JOB"
```

Descreva:

```bash
# Exibe source, destination, status, schedule e opções do job.
gcloud transfer jobs describe "$STS_JOB"
```

Procure conceitualmente por:

```text
transferSpec
schedule
status
description
```

#### 5. Inspecionar operações

Um **job** é a configuração. Cada execução cria uma **operation**.

```bash
# Lista operações associadas ao projeto.
gcloud transfer operations list
```

Se houver operação ativa/concluída, descreva a operação real:

```bash
# Substitua OPERATION_NAME pelo nome retornado.
gcloud transfer operations describe OPERATION_NAME
```

#### 6. Testar o resultado

```bash
# Verifica se o objeto chegou ao destino.
gcloud storage ls "$STS_DEST"
```

Teste o conteúdo:

```bash
# Copia o objeto do destino para stdout.
gcloud storage cat "$STS_DEST/ace-sts.txt"
```

Resultado esperado:

```text
ACE Storage Transfer Service
```

#### 7. Schedule: quando usar

O mesmo comando suporta transferências agendadas.

Modelo:

```text
one-time
→ transferência pontual

scheduled
→ execução em uma data/cadência definida
```

Exemplo conceitual:

```bash
# Exemplo: cria um job e não inicia imediatamente.
# Use --schedule-starts / --schedule-repeats-every quando quiser recorrência.
gcloud transfer jobs create \
  "$STS_SOURCE" \
  "$STS_DEST" \
  --do-not-run
```

Não deixe jobs recorrentes ativos apenas para estudo.

#### 8. Quebrar propositalmente

Crie uma evidência simples de falha usando um destino inexistente:

```bash
# Este caminho aponta para um bucket que não existe.
export BAD_DEST="gs://${PROJECT_ID}-bucket-inexistente-ace"

# A criação/execução deve falhar por destino inválido ou inacessível.
gcloud transfer jobs create \
  "$STS_SOURCE" \
  "$BAD_DEST" \
  --name="ace-sts-falha"
```

#### 9. Troubleshooting

```text
Sintoma
→ job não transfere o objeto

Hipóteses
→ origem incorreta
→ destino incorreto
→ service agent sem permissão
→ job desabilitado / schedule ainda não executou

Evidências
→ gcloud transfer jobs describe
→ gcloud transfer operations list/describe
→ gcloud storage ls source/destination

Causa
→ determinar a partir do job/operação real

Correção
→ corrigir URI, IAM ou schedule e executar novamente
```

#### 10. Cleanup do Storage Transfer Service

```bash
# Exclui o transfer job.
gcloud transfer jobs delete "$STS_JOB"

# Remove objetos e buckets usados no laboratório.
gcloud storage rm --recursive "$STS_SOURCE/**" 2>/dev/null || true
gcloud storage rm --recursive "$STS_DEST/**" 2>/dev/null || true
gcloud storage buckets delete "$STS_SOURCE" --quiet
gcloud storage buckets delete "$STS_DEST" --quiet

# Remove o arquivo local.
rm -f /tmp/ace-sts.txt
```

### Cleanup Dataflow

Depois do job terminar:

```bash
# Explicação: Remove objeto(s) do Cloud Storage conforme o caminho/padrão informado.
gcloud storage rm --recursive "$DF_BUCKET/**" 2>/dev/null || true
# Explicação: Exclui o bucket; ele precisa estar vazio ou ser removido recursivamente conforme o comando.
gcloud storage buckets delete "$DF_BUCKET" --quiet
```

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

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
| 3.4 | Storage Transfer Service | `P` | `P` |
| 4.4 | Status Dataflow jobs | `P` | `P` |
