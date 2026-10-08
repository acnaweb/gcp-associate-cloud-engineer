# Aula 6 — Pub/Sub, Dataflow, Storage Transfer e Jobs

## Objetivos

Ao final, você deverá:

- explicar publisher, topic, subscription, subscriber e acknowledgment no Pub/Sub;
- criar e inspecionar topic e subscription;
- publicar e consumir mensagens;
- provocar e diagnosticar uma falha simples de Pub/Sub;
- explicar quando usar Storage Transfer Service em vez de uma cópia manual;
- executar e inspecionar uma transferência entre buckets;
- diferenciar transfer job e transfer operation;
- diferenciar processamento batch e streaming no Dataflow;
- explicar source, transformation e sink em um pipeline;
- executar um Dataflow job a partir de um template oficial;
- listar e inspecionar o estado de um Dataflow job;
- interpretar estados de execução de jobs;
- diferenciar BigQuery Job, Dataflow Job e Storage Transfer Job/Operation;
- escolher entre Pub/Sub, Dataflow, Storage Transfer e BigQuery a partir de um cenário;
- executar o cleanup dos recursos do laboratório.

> **Custos:** Pub/Sub e Storage Transfer usarão volumes mínimos. Dataflow cria recursos de processamento e pode gerar cobrança mesmo em um laboratório curto. Execute o job uma única vez, acompanhe até o estado terminal e faça o cleanup. Templates gerenciados pelo Google usam Dataflow Prime por padrão atualmente; não trate Dataflow como um recurso gratuito.

---

# 1. Visão geral

Esta aula fecha o fluxo de soluções de dados da Semana 4.

```text
mensagens/eventos desacoplados
→ Pub/Sub
processamento/transformação batch ou streaming
→ Dataflow
movimentação gerenciada de conjuntos de dados
→ Storage Transfer Service
SQL analítico / data warehouse
→ BigQuery
```

Esses serviços podem trabalhar juntos, mas resolvem problemas diferentes.

---

# 2. Pub/Sub — arquitetura

Modelo:

```text
Publisher
↓
Topic
↓
Subscription
↓
Subscriber
↓
ACK
```

## 2.1 Topic

É o recurso para o qual publishers enviam mensagens.

## 2.2 Subscription

Representa a entrega das mensagens de um topic para consumidores.

Uma subscription pull permite que o consumidor busque mensagens.

## 2.3 Acknowledgment

Após processar uma mensagem, o subscriber pode confirmar seu processamento com um ACK.

Modelo mental:

```text
publish
→ topic
→ subscription
→ pull
→ process
→ ack
```

Não confunda:

```text
topic
≠
subscription
```

---

# 3. Laboratório Pub/Sub

## 3.1 Variáveis e API

```bash
# Obtém o projeto configurado.
export PROJECT_ID="$(gcloud config get-value project)"
# Define recursos do laboratório.
export PUBSUB_TOPIC=ace-topic
export PUBSUB_SUB=ace-sub
# Habilita a API Pub/Sub.
gcloud services enable pubsub.googleapis.com
```

## 3.2 Criar topic

```bash
# Cria o topic.
gcloud pubsub topics create "$PUBSUB_TOPIC"
# Lista topics.
gcloud pubsub topics list
# Inspeciona o topic.
gcloud pubsub topics describe "$PUBSUB_TOPIC"
```

## 3.3 Criar subscription pull

```bash
# Cria uma subscription pull associada ao topic.
gcloud pubsub subscriptions create "$PUBSUB_SUB" \
  --topic="$PUBSUB_TOPIC"
# Lista subscriptions.
gcloud pubsub subscriptions list
# Inspeciona a subscription.
gcloud pubsub subscriptions describe "$PUBSUB_SUB"
```

## 3.4 Publicar

```bash
# Publica três mensagens.
gcloud pubsub topics publish "$PUBSUB_TOPIC" --message="evento-1"
gcloud pubsub topics publish "$PUBSUB_TOPIC" --message="evento-2"
gcloud pubsub topics publish "$PUBSUB_TOPIC" --message="evento-3"
```

## 3.5 Consumir e confirmar

```bash
# Faz pull e confirma automaticamente as mensagens retornadas.
gcloud pubsub subscriptions pull "$PUBSUB_SUB" \
  --auto-ack \
  --limit=10
```

Fluxo praticado:

```text
publisher
→ topic
→ subscription
→ pull
→ ACK
```

---

# 4. Quebrar Pub/Sub propositalmente

Altere somente uma variável conhecida: o nome da subscription.

```bash
# Tenta consumir de uma subscription inexistente.
gcloud pubsub subscriptions pull ace-sub-inexistente \
  --auto-ack \
  --limit=1
```

## Sintoma

```text
subscription não encontrada
```

## Hipótese

```text
nome da subscription está incorreto
```

## Evidência

```bash
# Lista as subscriptions realmente existentes.
gcloud pubsub subscriptions list
# Inspeciona a subscription correta.
gcloud pubsub subscriptions describe "$PUBSUB_SUB"
```

## Causa

```text
ace-sub-inexistente
≠
ace-sub
```

## Correção

```bash
# Usa novamente a subscription criada e inspecionada.
gcloud pubsub subscriptions pull "$PUBSUB_SUB" \
  --auto-ack \
  --limit=1
```

Se não houver mensagens, isso não significa que a correção falhou: as mensagens anteriores podem já ter sido confirmadas.

Publique outra:

```bash
# Publica nova mensagem para validar a correção.
gcloud pubsub topics publish "$PUBSUB_TOPIC" --message="evento-correcao"
# Consome a nova mensagem.
gcloud pubsub subscriptions pull "$PUBSUB_SUB" \
  --auto-ack \
  --limit=1
```

---

# 5. Storage Transfer Service

Storage Transfer Service é um serviço gerenciado para movimentação de dados.

Não confunda:

```text
gcloud storage cp
→ comando de cópia executado pelo cliente
Storage Transfer Service
→ serviço gerenciado de transferência
```

Arquitetura do laboratório:

```text
bucket origem
↓
Transfer Job
↓
Transfer Operation
↓
bucket destino
```

Um **Transfer Job** define a transferência.

Uma **Transfer Operation** representa uma execução do job.

---

# 6. Laboratório Storage Transfer

## 6.1 Variáveis

```bash
# Define nomes globalmente únicos usando project ID.
export TRANSFER_SOURCE="${PROJECT_ID}-ace-transfer-source"
export TRANSFER_DEST="${PROJECT_ID}-ace-transfer-dest"
# Define localização dos buckets.
export STORAGE_LOCATION=US
# Habilita a API do Storage Transfer Service.
gcloud services enable storagetransfer.googleapis.com
```

## 6.2 Criar buckets

```bash
# Cria bucket de origem.
gcloud storage buckets create "gs://$TRANSFER_SOURCE" \
  --location="$STORAGE_LOCATION"
# Cria bucket de destino.
gcloud storage buckets create "gs://$TRANSFER_DEST" \
  --location="$STORAGE_LOCATION"
# Lista os buckets.
gcloud storage buckets list
```

## 6.3 Criar objeto de origem

```bash
# Cria um arquivo pequeno.
cat > dados-transfer.csv <<'EOF'
id,nome
1,Ana
2,Bruno
EOF
# Envia o arquivo somente para a origem.
gcloud storage cp dados-transfer.csv "gs://$TRANSFER_SOURCE/"
# Confirma a origem.
gcloud storage ls "gs://$TRANSFER_SOURCE/"
# Confirma que o destino ainda está vazio.
gcloud storage ls "gs://$TRANSFER_DEST/"
```

## 6.4 Criar e executar a transferência

Sem um schedule explícito e sem `--do-not-run`, o comando cria um job de execução única e inicia a transferência.

```bash
# Cria uma transferência imediata entre os buckets.
gcloud transfer jobs create \
  "gs://$TRANSFER_SOURCE" \
  "gs://$TRANSFER_DEST" \
  --description="ACE Storage Transfer bucket to bucket"
```

## 6.5 Inspecionar transfer jobs

```bash
# Lista os transfer jobs.
gcloud transfer jobs list
```

Copie o nome do job retornado para a variável:

```bash
# Substitua pelo resource name real retornado.
export TRANSFER_JOB="transferJobs/SEU_JOB"
```

Inspecione:

```bash
# Exibe a definição do transfer job.
gcloud transfer jobs describe "$TRANSFER_JOB"
```

## 6.6 Inspecionar operações

```bash
# Lista operações do Storage Transfer Service.
gcloud transfer operations list
```

A execução pode levar algum tempo. O conceito importante é:

```text
Transfer Job
→ configuração
Transfer Operation
→ execução
```

## 6.7 Validar o resultado

```bash
# Verifica se o arquivo chegou ao destino.
gcloud storage ls "gs://$TRANSFER_DEST/"
# Lê o conteúdo transferido.
gcloud storage cat "gs://$TRANSFER_DEST/dados-transfer.csv"
```

Resultado esperado:

```text
id,nome
1,Ana
2,Bruno
```

---

# 7. Dataflow — batch e streaming

Dataflow é um serviço gerenciado para processamento de dados baseado no modelo Apache Beam.

Arquitetura genérica:

```text
Source
↓
Transformations
↓
Sink
```

Exemplos:

```text
Cloud Storage
↓
Dataflow
↓
Cloud Storage / BigQuery
```

e:

```text
Pub/Sub
↓
Dataflow
↓
BigQuery
```

## 7.1 Batch

```text
conjunto finito de dados
→ processa
→ termina
```

## 7.2 Streaming

```text
fluxo contínuo de eventos
→ processa continuamente
```

Não confunda:

```text
Pub/Sub
→ transporte/mensageria
Dataflow
→ processamento/transformação
```

---

# 8. Laboratório Dataflow — WordCount

Usaremos o template oficial `Word_Count`.

Ele é apropriado para o laboratório porque:

```text
batch
+
entrada conhecida
+
transformação conhecida
+
saída em Cloud Storage
+
job termina
```

> **Atenção a custos:** Dataflow provisiona recursos de processamento. Não repita o job desnecessariamente. Acompanhe o estado e remova os artefatos ao final.

## 8.1 Preparar

```bash
# Define o bucket de saída do Dataflow.
export DATAFLOW_BUCKET="${PROJECT_ID}-ace-dataflow"
# Define a região.
export REGION=us-central1
# Cria um nome único de job usando timestamp.
export DATAFLOW_JOB="ace-wordcount-$(date +%Y%m%d-%H%M%S)"
# Habilita Dataflow e Compute Engine.
gcloud services enable \
  dataflow.googleapis.com \
  compute.googleapis.com
# Cria o bucket de saída.
gcloud storage buckets create "gs://$DATAFLOW_BUCKET" \
  --location="$REGION"
```

## 8.2 Executar o template

A entrada usa o arquivo público de exemplo do Google e a saída vai para o bucket do laboratório.

```bash
# Executa o template batch WordCount fornecido pelo Google.
gcloud dataflow jobs run "$DATAFLOW_JOB" \
  --gcs-location="gs://dataflow-templates/latest/Word_Count" \
  --region="$REGION" \
  --parameters="inputFile=gs://dataflow-samples/shakespeare/kinglear.txt,output=gs://$DATAFLOW_BUCKET/output/wordcount"
```

O comando retorna informações como:

```text
id
name
projectId
type
currentState
```

---

# 9. Inspecionar Dataflow Jobs

## 9.1 Listar

```bash
# Lista jobs Dataflow da região.
gcloud dataflow jobs list \
  --region="$REGION"
```

Observe:

```text
JOB_ID
NAME
TYPE
STATE
```

## 9.2 Capturar o ID

```bash
# Localiza o ID pelo nome do job criado nesta sessão.
export DATAFLOW_JOB_ID="$(gcloud dataflow jobs list \
  --region="$REGION" \
  --filter="name=$DATAFLOW_JOB" \
  --format='value(id)' \
  --limit=1)"
# Confirma o ID.
echo "$DATAFLOW_JOB_ID"
```

## 9.3 Descrever

```bash
# Inspeciona o job específico.
gcloud dataflow jobs describe "$DATAFLOW_JOB_ID" \
  --region="$REGION"
```

Procure:

```text
name
type
currentState
createTime
```

Estados relevantes incluem:

```text
JOB_STATE_PENDING
JOB_STATE_RUNNING
JOB_STATE_DONE
JOB_STATE_FAILED
JOB_STATE_CANCELLED
```

Para um job batch bem-sucedido:

```text
JOB_STATE_DONE
```

é o estado terminal esperado.

## 9.4 Verificar a saída

Depois que o job chegar a `JOB_STATE_DONE`:

```bash
# Lista os arquivos gerados pelo WordCount.
gcloud storage ls "gs://$DATAFLOW_BUCKET/output/"
```

Leia uma parte:

```bash
# Exibe as primeiras linhas dos arquivos de saída.
gcloud storage cat "gs://$DATAFLOW_BUCKET/output/wordcount*" | head
```

---

# 10. Troubleshooting Dataflow

Não criaremos propositalmente um segundo job Dataflow com erro apenas para consumir recursos.

O laboratório já praticou:

```text
criar job
→ listar
→ obter ID
→ describe
→ interpretar estado
→ validar output
```

A falha real fica como `P*`.

## Cenário guiado

Sintoma:

```text
job termina em JOB_STATE_FAILED
```

Hipóteses iniciais compatíveis com o que já conhecemos:

```text
input incorreto
output inacessível
permissão insuficiente
configuração do job
```

Evidências:

```bash
# Inspeciona estado e detalhes do job.
gcloud dataflow jobs describe "$DATAFLOW_JOB_ID" \
  --region="$REGION"
```

Depois consulte os logs do job no Cloud Logging/Dataflow quando necessário.

Modelo:

```text
Sintoma
→ job FAILED
Hipótese
→ entrada/saída/permissão/configuração
Evidência
→ describe + logs
Causa
→ evidência concreta
Correção
→ corrigir somente a causa identificada
```

Classificação:

```text
executar job real
→ P
listar/describe/status
→ P
validar output
→ P
falha real controlada
→ P*
```

---

# 11. O significado de "Job" muda por serviço

| Serviço | Unidade operacional | O que observar |
|---|---|---|
| BigQuery | Job | query/load/copy/extract, estado e erro |
| Dataflow | Job | pipeline batch/streaming, estado e execução |
| Storage Transfer | Transfer Job | definição/configuração da transferência |
| Storage Transfer | Transfer Operation | execução concreta do transfer job |
| Pub/Sub | topic/subscription/mensagem | mensageria; não use "job" como equivalência |

Modelo mental:

```text
mesma palavra "job"
≠
mesmo modelo operacional em todos os serviços
```

---

# 12. Matriz de decisão

| Necessidade dominante | Serviço |
|---|---|
| desacoplar produtores e consumidores por mensagens/eventos | Pub/Sub |
| transformar/processar dados batch ou streaming | Dataflow |
| mover conjuntos de dados entre storages de forma gerenciada | Storage Transfer Service |
| consultar e analisar dados com SQL em data warehouse | BigQuery |

## 12.1 Exemplos combinados

Streaming analytics:

```text
Pub/Sub
↓
Dataflow
↓
BigQuery
```

Processamento batch:

```text
Cloud Storage
↓
Dataflow
↓
BigQuery / Cloud Storage
```

Movimentação:

```text
Storage externo / Cloud Storage
↓
Storage Transfer Service
↓
Cloud Storage
```

Storage Transfer movimenta dados; não é escolhido como engine de transformação equivalente ao Dataflow.

---

# 13. Que serviço escolher?

## Cenário A

> Sensores enviam eventos e produtores não devem depender diretamente dos consumidores.

```text
Pub/Sub
```

## Cenário B

> Eventos precisam ser transformados continuamente antes de chegar ao warehouse.

```text
Pub/Sub
↓
Dataflow
↓
BigQuery
```

## Cenário C

> Terabytes de objetos precisam ser migrados de um storage para Cloud Storage por um serviço gerenciado.

```text
Storage Transfer Service
```

## Cenário D

> Arquivos históricos precisam ser transformados em batch.

```text
Dataflow
```

## Cenário E

> Analistas precisam executar agregações SQL sobre histórico.

```text
BigQuery
```

---

# 14. Questões estilo ACE

### Questão 1

Uma aplicação publica eventos e vários consumidores precisam processá-los de forma desacoplada.

**Resposta:** Pub/Sub.

### Questão 2

Você precisa processar continuamente eventos vindos do Pub/Sub e transformá-los antes de gravá-los no BigQuery.

**Resposta:** Dataflow.

### Questão 3

Você precisa mover objetos entre buckets usando um serviço gerenciado de transferência.

**Resposta:** Storage Transfer Service.

### Questão 4

Você precisa analisar o estado de um pipeline Dataflow.

**Resposta:** listar o job e usar `gcloud dataflow jobs describe`.

### Questão 5

Um Storage Transfer Job existe, mas você precisa analisar uma execução específica.

**Resposta:** inspecionar a Transfer Operation correspondente.

### Questão 6

A equipe quer usar Storage Transfer Service para transformar registros antes de carregá-los.

**Resposta:** Storage Transfer é movimentação; Dataflow é o candidato para processamento/transformação.

### Questão 7

Você quer executar SQL analítico sobre grandes volumes históricos.

**Resposta:** BigQuery.

### Questão 8

Uma mensagem foi entregue a uma subscription pull e processada com sucesso.

**Resposta:** o subscriber deve fazer acknowledgment para confirmar o processamento.

---

# 15. M/E/P

| Conteúdo | Nível |
|---|---:|
| Pub/Sub — arquitetura | `E` |
| Pub/Sub — topic/subscription | `P` |
| Pub/Sub — publish/pull/ack | `P` |
| Pub/Sub — falha/troubleshooting | `P` |
| Storage Transfer — arquitetura | `E` |
| Storage Transfer — bucket→bucket | `P` |
| Transfer Job — listar/describe | `P` |
| Transfer Operation — listar | `P` |
| Dataflow — batch × streaming | `E` |
| Dataflow — source/transform/sink | `E` |
| Dataflow — WordCount template | `P` |
| Dataflow — listar/describe/status | `P` |
| Dataflow — validar output | `P` |
| Dataflow — falha real controlada | `P*` |
| BigQuery/Dataflow/Transfer Jobs | `E/P` |
| Matriz de decisão | `E/P` |

---

# 16. Checklist

- [ ] Expliquei publisher, topic, subscription, subscriber e ACK;
- [ ] Criei e inspecionei topic;
- [ ] Criei e inspecionei subscription;
- [ ] Publiquei e consumi mensagens;
- [ ] Provoquei e corrigi uma falha simples de Pub/Sub;
- [ ] Diferenciei `gcloud storage cp` de Storage Transfer Service;
- [ ] Criei buckets de origem e destino;
- [ ] Executei uma transferência gerenciada;
- [ ] Diferenciei Transfer Job e Transfer Operation;
- [ ] Diferenciei batch e streaming;
- [ ] Expliquei source, transformations e sink;
- [ ] Executei o WordCount oficial no Dataflow;
- [ ] Listei Dataflow jobs;
- [ ] Inspecionei o estado do job;
- [ ] Validei o output do pipeline;
- [ ] Diferenciei os significados de job entre os serviços;
- [ ] Resolvi cenários Pub/Sub × Dataflow × Storage Transfer × BigQuery;
- [ ] Executei o cleanup.

---

# 17. Cleanup

> Execute o cleanup somente depois que o Dataflow job estiver em estado terminal. Não exclua o bucket de saída enquanto o job ainda estiver escrevendo.

## 17.1 Pub/Sub

```bash
# Remove a subscription.
gcloud pubsub subscriptions delete "$PUBSUB_SUB" --quiet
# Remove o topic.
gcloud pubsub topics delete "$PUBSUB_TOPIC" --quiet
```

## 17.2 Storage Transfer

Antes de remover os buckets, confirme que a transferência terminou.

```bash
# Lista operações para confirmar o estado final da transferência.
gcloud transfer operations list
# Remove os objetos e buckets do laboratório.
gcloud storage rm --recursive "gs://$TRANSFER_SOURCE/**"
gcloud storage rm --recursive "gs://$TRANSFER_DEST/**"
gcloud storage buckets delete "gs://$TRANSFER_SOURCE" --quiet
gcloud storage buckets delete "gs://$TRANSFER_DEST" --quiet
# Remove arquivo local.
rm -f dados-transfer.csv
```

O Transfer Job pode permanecer como histórico/configuração até ser removido explicitamente. Se desejar excluí-lo após identificar o resource name:

```bash
# Remove o transfer job criado pelo laboratório.
gcloud transfer jobs delete "$TRANSFER_JOB"
```

## 17.3 Dataflow

Confirme o estado:

```bash
# Confirma que o job batch terminou.
gcloud dataflow jobs describe "$DATAFLOW_JOB_ID" \
  --region="$REGION" \
  --format="value(currentState)"
```

Se estiver `JOB_STATE_DONE`, remova o bucket:

```bash
# Remove outputs do WordCount.
gcloud storage rm --recursive "gs://$DATAFLOW_BUCKET/**"
# Remove o bucket.
gcloud storage buckets delete "gs://$DATAFLOW_BUCKET" --quiet
```

Se o job ainda estiver executando, não apague o bucket. Aguarde o término ou cancele o job conscientemente antes do cleanup.

---

# 18. Referências oficiais

- Pub/Sub — topics, pull subscriptions, publish, pull e acknowledgment.
- Storage Transfer Service — transfer jobs e transfer operations.
- Dataflow — Google-provided templates e WordCount.
- Dataflow — execução e inspeção de jobs.
- Associate Cloud Engineer — exam guide.
