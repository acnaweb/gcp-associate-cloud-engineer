# Aula 5 — BigQuery e Matriz de Escolha de Bancos

## Objetivos

Ao final, você deverá:

- explicar o papel do BigQuery como data warehouse serverless;
- diferenciar project, dataset, table, schema e job;
- criar e inspecionar um dataset BigQuery;
- criar uma tabela carregando dados CSV;
- inspecionar schema e metadados da tabela;
- executar consultas SQL no BigQuery;
- executar uma query com dry run e interpretar a estimativa de bytes processados;
- listar e inspecionar jobs BigQuery;
- provocar uma falha de query de forma controlada;
- diagnosticar a falha usando informações do job;
- corrigir a query e validar sua execução;
- explicar os principais fatores de custo do BigQuery;
- diferenciar BigQuery de bancos destinados a workloads transacionais;
- escolher entre Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable e BigQuery a partir de um cenário;
- justificar a escolha pelo modelo de dados, padrão de acesso, consistência, escala e tipo de workload.

> **Custos:** o laboratório usa um dataset e uma tabela pequenos. BigQuery pode cobrar por armazenamento e processamento de consultas conforme o modelo de cobrança e o uso do projeto. O `dry run` será usado antes das consultas para reforçar a relação entre dados processados e custo.

---

# 1. Conceito

BigQuery é o data warehouse serverless do Google Cloud.

Modelo mental:

```text
dados analíticos
+
SQL
+
grandes scans
+
agregações
+
data warehouse
↓
BigQuery
```

BigQuery não deve ser escolhido simplesmente porque:

```text
"há muitos dados"
```

O padrão de acesso importa.

Exemplos:

```text
milhões de transações OLTP por chave
→ BigQuery provavelmente não é o banco operacional
grandes agregações sobre histórico
→ BigQuery é forte candidato
```

---

# 2. Arquitetura mental do BigQuery

```text
Google Cloud Project
↓
Dataset
↓
Table
├── Schema
└── Data
Query / Load / Copy / Extract
↓
Job
```

## 2.1 Project

É o contêiner administrativo no qual os recursos e jobs são associados.

## 2.2 Dataset

Organiza tabelas e outros objetos BigQuery.

A localização do dataset é uma decisão importante e não deve ser tratada como um detalhe.

## 2.3 Table

Contém os dados tabulares.

## 2.4 Schema

Define campos e tipos.

Exemplo:

```text
id        INTEGER
nome      STRING
segmento  STRING
valor     NUMERIC
```

## 2.5 Job

Operações como consultas e cargas são executadas como jobs.

Para a ACE, isso é importante porque você precisa saber:

```text
executar operação
↓
inspecionar job
↓
verificar status
↓
diagnosticar falha
```

---

# 3. Preparar o laboratório

## 3.1 Variáveis

```bash
# Obtém o projeto atualmente configurado no gcloud.
export PROJECT_ID="$(gcloud config get-value project)"
# Define o dataset dedicado ao laboratório.
export BQ_DATASET=ace_bigquery
# Define a tabela do laboratório.
export BQ_TABLE=clientes
# Usa uma localização regional para manter o laboratório explícito.
export BQ_LOCATION=us-central1
# Exibe as variáveis antes da criação dos recursos.
printf 'PROJECT_ID=%s\nBQ_DATASET=%s\nBQ_TABLE=%s\nBQ_LOCATION=%s\n' \
  "$PROJECT_ID" "$BQ_DATASET" "$BQ_TABLE" "$BQ_LOCATION"
```

## 3.2 Habilitar API

```bash
# Habilita a API do BigQuery no projeto.
gcloud services enable bigquery.googleapis.com
```

## 3.3 Validar a CLI bq

```bash
# Confirma que a ferramenta bq está disponível.
command -v bq
# Exibe a versão instalada.
bq version
```

---

# 4. Criar e inspecionar o dataset

Antes de criar:

```bash
# Lista datasets visíveis no projeto.
bq ls --project_id="$PROJECT_ID"
```

Crie:

```bash
# Cria o dataset na localização definida para o laboratório.
bq --location="$BQ_LOCATION" mk \
  --dataset \
  --description="Dataset laboratorio ACE BigQuery" \
  "$PROJECT_ID:$BQ_DATASET"
```

Confirme:

```bash
# Lista novamente os datasets após a criação.
bq ls --project_id="$PROJECT_ID"
```

Inspecione:

```bash
# Exibe metadados detalhados do dataset.
bq show \
  --format=prettyjson \
  "$PROJECT_ID:$BQ_DATASET"
```

Localize:

```text
datasetReference
location
creationTime
```

---

# 5. Criar dados CSV

Crie um arquivo pequeno e determinístico:

```bash
# Cria o CSV usado no load job.
cat > clientes.csv <<'EOF'
id,nome,segmento,valor
1,Ana,premium,120.50
2,Bruno,standard,80.00
3,Carla,premium,210.75
4,Diego,standard,55.25
5,Elisa,premium,310.00
EOF
# Inspeciona o arquivo antes do upload.
cat clientes.csv
```

---

# 6. Carregar dados no BigQuery

O comando `bq load` cria um load job.

Use schema explícito para tornar o laboratório previsível:

```bash
# Carrega o CSV local e cria a tabela clientes.
bq --location="$BQ_LOCATION" load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  "$PROJECT_ID:$BQ_DATASET.$BQ_TABLE" \
  ./clientes.csv \
  'id:INTEGER,nome:STRING,segmento:STRING,valor:NUMERIC'
```

## 6.1 Inspecionar a tabela

```bash
# Lista as tabelas do dataset.
bq ls "$PROJECT_ID:$BQ_DATASET"
# Exibe schema e metadados da tabela.
bq show \
  --schema \
  --format=prettyjson \
  "$PROJECT_ID:$BQ_DATASET.$BQ_TABLE"
```

Confirme os campos:

```text
id
nome
segmento
valor
```

---

# 7. Consultar dados

## 7.1 SELECT básico

```bash
# Consulta os dados carregados usando GoogleSQL.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  "SELECT id, nome, segmento, valor
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   ORDER BY id"
```

Resultado esperado:

```text
1 Ana   premium
2 Bruno standard
3 Carla premium
4 Diego standard
5 Elisa premium
```

## 7.2 Agregação

```bash
# Agrega quantidade e valor por segmento.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  "SELECT
     segmento,
     COUNT(*) AS quantidade,
     SUM(valor) AS valor_total
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   GROUP BY segmento
   ORDER BY segmento"
```

Modelo mental:

```text
scan
↓
filter / aggregate / join
↓
resultado analítico
```

---

# 8. Dry run — validar antes de executar

O `dry run` valida a consulta sem executá-la e informa uma estimativa de dados processados quando aplicável.

```bash
# Valida a consulta e estima bytes processados sem executá-la.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  --dry_run \
  "SELECT
     segmento,
     COUNT(*) AS quantidade,
     SUM(valor) AS valor_total
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   GROUP BY segmento"
```

Procure uma mensagem equivalente a:

```text
Query successfully validated
running this query will process ... bytes
```

Para a ACE:

```text
dry run
→ valida query
+
estima dados processados
+
ajuda a antecipar impacto de custo
```

Não conclua:

```text
LIMIT 10
→ sempre reduz bytes processados
```

Em BigQuery, custo de consulta depende do modelo de cobrança e, no modelo on-demand, do volume de dados processado, não simplesmente da quantidade de linhas exibidas.

---

# 9. Jobs — inspecionar execução

O guia ACE cobra análise de status de jobs BigQuery.

## 9.1 Listar jobs

```bash
# Lista jobs recentes do projeto.
bq ls \
  --jobs=true \
  --project_id="$PROJECT_ID" \
  --max_results=10
```

Observe:

```text
jobId
jobType
state
```

Estados importantes:

```text
PENDING
RUNNING
DONE
```

Um job `DONE` pode ter terminado com sucesso ou erro. Portanto, para diagnóstico, inspecione seus detalhes.

## 9.2 Capturar um job recente

```bash
# Captura o ID do job mais recente visível para o usuário atual.
export BQ_JOB_ID="$(bq ls \
  --jobs=true \
  --project_id="$PROJECT_ID" \
  --max_results=1 \
  --format=prettyjson | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d[0]["jobReference"]["jobId"])')"
# Exibe o ID capturado.
echo "$BQ_JOB_ID"
```

## 9.3 Inspecionar o job

```bash
# Exibe detalhes do job na localização usada pelo laboratório.
bq --location="$BQ_LOCATION" show \
  --job=true \
  --format=prettyjson \
  "$PROJECT_ID:$BQ_JOB_ID"
```

Procure:

```text
status.state
status.errorResult
statistics
configuration
```

---

# 10. Quebrar propositalmente — query inválida

Vamos alterar apenas uma variável conhecida: o nome da coluna.

Tabela correta:

```text
clientes
```

Coluna existente:

```text
segmento
```

Coluna que usaremos para provocar erro:

```text
segmento_inexistente
```

Execute:

```bash
# Provoca uma falha usando uma coluna que não existe.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  "SELECT segmento_inexistente, COUNT(*)
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   GROUP BY segmento_inexistente"
```

Resultado esperado:

```text
query falha
```

---

# 11. Troubleshooting do job

## Sintoma

```text
a query não conclui com sucesso
```

## Hipótese

```text
a consulta referencia uma coluna inexistente
```

## Evidência 1 — schema

```bash
# Inspeciona o schema conhecido da tabela.
bq show \
  --schema \
  --format=prettyjson \
  "$PROJECT_ID:$BQ_DATASET.$BQ_TABLE"
```

Confirme:

```text
segmento existe
segmento_inexistente não existe
```

## Evidência 2 — job

Liste os jobs novamente:

```bash
# Lista jobs recentes para localizar a execução com falha.
bq ls \
  --jobs=true \
  --project_id="$PROJECT_ID" \
  --max_results=10
```

Copie o `jobId` correspondente à falha:

```bash
# Substitua pelo ID real do job com falha.
export FAILED_JOB_ID="JOB_ID_COM_FALHA"
```

Inspecione:

```bash
# Exibe o status e a mensagem de erro do job com falha.
bq --location="$BQ_LOCATION" show \
  --job=true \
  --format=prettyjson \
  "$PROJECT_ID:$FAILED_JOB_ID"
```

Procure:

```text
status.state
status.errorResult
```

## Causa

```text
campo inexistente
```

## Correção

Troque:

```text
segmento_inexistente
```

por:

```text
segmento
```

---

# 12. Corrigir e validar

Primeiro faça dry run:

```bash
# Valida a query corrigida antes da execução real.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  --dry_run \
  "SELECT segmento, COUNT(*) AS quantidade
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   GROUP BY segmento"
```

Depois execute:

```bash
# Executa a query corrigida.
bq --location="$BQ_LOCATION" query \
  --use_legacy_sql=false \
  "SELECT segmento, COUNT(*) AS quantidade
   FROM \`$PROJECT_ID.$BQ_DATASET.$BQ_TABLE\`
   GROUP BY segmento
   ORDER BY segmento"
```

Resultado esperado:

```text
premium  3
standard 2
```

Fluxo completo:

```text
query
↓
job
↓
falha
↓
schema + job
↓
causa
↓
correção
↓
dry run
↓
query válida
```

---

# 13. Custos do BigQuery

Os principais fatores que o aluno deve reconhecer são:

```text
armazenamento
+
processamento de consultas
+
modelo de capacidade / cobrança adotado
+
transferência de dados quando aplicável
```

Para consultas on-demand, pense:

```text
mais bytes processados
→ maior potencial de custo
```

Ferramentas de controle:

```text
dry run
→ estimativa antes da execução
partitioning
→ reduz leitura quando filtro usa partição
clustering
→ pode reduzir dados lidos em padrões adequados
selecionar somente colunas necessárias
→ evita leitura desnecessária
```

Anti-pattern:

```sql
SELECT *
```

quando a aplicação precisa de poucas colunas em uma tabela muito larga.

A ideia para ACE não é tuning avançado. É reconhecer:

```text
arquitetura da tabela
+
query
+
bytes processados
+
modelo de cobrança
→ custo
```

---

# 14. BigQuery não é OLTP

Compare:

| Característica | Banco OLTP | BigQuery |
|---|---|---|
| foco | transações operacionais | analytics |
| acesso típico | registros/chaves | scans/agregações |
| consultas | pequenas e frequentes | analíticas |
| histórico massivo | secundário | caso de uso central |
| warehouse | não | sim |

Cenário:

> Uma API recebe pedidos e precisa confirmar cada transação imediatamente.

Não escolha BigQuery apenas porque os pedidos serão analisados posteriormente.

Modelo:

```text
operação transacional
→ banco operacional
histórico analítico
→ BigQuery
```

---

# 15. Matriz de escolha de bancos

Esta matriz consolida as Aulas 3, 4 e 5.

| Serviço | Modelo / característica | Padrão dominante | Exemplo |
|---|---|---|---|
| Cloud SQL | relacional gerenciado | OLTP tradicional | aplicação MySQL/PostgreSQL/SQL Server |
| AlloyDB | PostgreSQL-compatible | PostgreSQL exigente | workload PostgreSQL com maior demanda de performance/escala |
| Spanner | relacional distribuído | transações + escala horizontal | sistema transacional distribuído |
| Firestore | documentos | acesso por documentos | aplicação web/mobile serverless |
| Bigtable | wide-column/key-value | chave/range + throughput | telemetria/séries de eventos |
| BigQuery | data warehouse | SQL analítico | BI, agregações, histórico |

## 15.1 Árvore mental

```text
Preciso de analytics / warehouse / grandes agregações?
├─ sim → BigQuery
└─ não
   ↓
Preciso de documentos?
├─ sim → Firestore
└─ não
   ↓
Preciso de chave/range com throughput massivo?
├─ sim → Bigtable
└─ não
   ↓
Preciso de modelo relacional?
├─ não → reavalie requisitos
└─ sim
   ↓
Preciso de escala horizontal/distribuída para transações?
├─ sim → Spanner
└─ não
   ↓
PostgreSQL-compatible com requisitos elevados de performance/arquitetura?
├─ sim → AlloyDB
└─ não → Cloud SQL
```

A árvore é uma heurística para prova, não substitui análise arquitetural real.

---

# 16. Anti-patterns de escolha

## 16.1 BigQuery para OLTP

```text
transações operacionais por registro
→ não escolher BigQuery como banco primário apenas pelo volume
```

## 16.2 Bigtable porque há muito dado

```text
"tem petabytes"
≠
"deve ser Bigtable"
```

Pergunte pelo padrão de acesso.

## 16.3 Firestore para joins relacionais tradicionais

```text
muitos joins e relações SQL
→ Firestore provavelmente não é o encaixe natural
```

## 16.4 Spanner somente porque o banco é grande

```text
banco grande
≠
necessidade automática de Spanner
```

Procure:

```text
relacional
+
transações
+
escala horizontal/distribuição
```

## 16.5 Cloud SQL para escala horizontal global massiva

Cloud SQL é excelente para muitos workloads relacionais, mas não deve ser forçado para um requisito cujo fator dominante seja banco relacional distribuído horizontalmente em grande escala.

---

# 17. Cenários de decisão

## Cenário A

> Aplicação existente usa MySQL e quer serviço gerenciado com mínima mudança.

```text
Cloud SQL
```

## Cenário B

> Sistema PostgreSQL-compatible possui requisitos elevados de desempenho e arquitetura gerenciada.

```text
AlloyDB
```

## Cenário C

> Sistema financeiro relacional precisa de transações e escala horizontal.

```text
Spanner
```

## Cenário D

> Aplicação mobile armazena perfis e preferências como documentos.

```text
Firestore
```

## Cenário E

> Milhões de dispositivos produzem telemetria acessada principalmente por device e intervalo.

```text
Bigtable
```

## Cenário F

> A empresa precisa executar SQL, joins e agregações sobre anos de histórico.

```text
BigQuery
```

---

# 18. Questões estilo ACE

### Questão 1

Você precisa carregar um CSV em um data warehouse serverless e executar agregações SQL.

**Resposta:** BigQuery.

### Questão 2

Antes de executar uma query BigQuery on-demand, você quer validar a sintaxe e estimar os dados processados.

**Resposta:** `bq query --dry_run`.

### Questão 3

Uma query falhou. Você precisa analisar seu status e mensagem de erro.

**Resposta:** localizar o job com `bq ls --jobs=true` e inspecioná-lo com `bq show --job=true`.

### Questão 4

Uma API de pedidos precisa de transações OLTP. A equipe escolheu BigQuery porque haverá milhões de pedidos.

**Resposta:** a escolha está baseada apenas em volume; use um banco operacional adequado ao requisito transacional.

### Questão 5

Uma aplicação precisa de documentos serverless, sem modelo relacional tradicional.

**Resposta:** Firestore.

### Questão 6

Um sistema relacional transacional precisa escalar horizontalmente.

**Resposta:** Spanner.

### Questão 7

Telemetria exige altíssimo throughput e acesso eficiente por row key/range.

**Resposta:** Bigtable.

### Questão 8

Aplicação existente usa PostgreSQL tradicional e quer banco gerenciado com mínima mudança, sem requisito especial de escala distribuída.

**Resposta:** Cloud SQL for PostgreSQL.

---

# 19. M/E/P

| Conteúdo | Nível |
|---|---:|
| BigQuery — arquitetura mental | `E` |
| Dataset — criar e inspecionar | `P` |
| CSV — criar e validar | `P` |
| Load job / tabela | `P` |
| Schema — inspecionar | `P` |
| Query SQL | `P` |
| Agregação | `P` |
| Dry run / bytes processados | `P` |
| Jobs — listar e inspecionar | `P` |
| Query com falha | `P` |
| Troubleshooting do job | `P` |
| Correção e validação | `P` |
| Fatores de custo | `E/P` |
| BigQuery × OLTP | `E` |
| Matriz de escolha de bancos | `E/P` |
| Cenários ACE | `P` |

---

# 20. Checklist

- [ ] Expliquei project, dataset, table, schema e job;
- [ ] Criei e inspecionei um dataset;
- [ ] Criei um CSV pequeno;
- [ ] Carreguei o CSV usando `bq load`;
- [ ] Inspecionei a tabela e seu schema;
- [ ] Executei um SELECT;
- [ ] Executei uma agregação;
- [ ] Executei um dry run;
- [ ] Interpretei a estimativa de bytes processados;
- [ ] Listei jobs BigQuery;
- [ ] Inspecionei os detalhes de um job;
- [ ] Provoquei uma query inválida;
- [ ] Localizei o job com falha;
- [ ] Usei schema e job como evidências;
- [ ] Corrigi a query;
- [ ] Validei a correção com dry run;
- [ ] Executei a query corrigida;
- [ ] Diferenciei BigQuery de OLTP;
- [ ] Expliquei os principais fatores de custo;
- [ ] Diferenciei Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable e BigQuery;
- [ ] Resolvi cenários de escolha de banco;
- [ ] Executei o cleanup.

---

# 21. Cleanup

Remova o dataset criado pelo laboratório. A opção `-r` remove recursivamente suas tabelas.

```bash
# Remove o dataset e as tabelas criadas nesta aula.
bq rm \
  -r \
  -f \
  -d \
  "$PROJECT_ID:$BQ_DATASET"
```

Confirme:

```bash
# Confirma que o dataset não aparece mais na listagem.
bq ls --project_id="$PROJECT_ID"
```

Remova o arquivo local:

```bash
# Remove o CSV local criado para o laboratório.
rm -f clientes.csv
```

Nenhum banco das Aulas 3 e 4 deve ser excluído por este cleanup.

---

# 22. Referências oficiais

- BigQuery — ferramenta de linha de comando `bq`.
- BigQuery — criar datasets.
- BigQuery — carregar dados.
- BigQuery — executar queries e dry run.
- BigQuery — gerenciar e inspecionar jobs.
- Associate Cloud Engineer — exam guide.
