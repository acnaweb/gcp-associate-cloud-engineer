# Aula 4 — Spanner, Firestore e Bigtable

## Objetivos

Ao final, você deverá:

- diferenciar Spanner, Firestore e Bigtable por modelo de dados, arquitetura, padrão de acesso e caso de uso;
- identificar quando utilizar Spanner, Firestore, Bigtable ou BigQuery a partir de requisitos técnicos;
- criar e inspecionar um database Firestore em Native mode;
- criar, consultar, atualizar e excluir documentos no Firestore;
- executar uma consulta filtrada no Firestore;
- entender como instances, databases, schemas e tabelas se relacionam no Spanner;
- executar ou acompanhar de forma guiada uma consulta SQL no Spanner;
- entender instances, clusters, tables, column families, columns, cells e row keys no Bigtable;
- explicar por que a row key é determinante para desempenho e distribuição no Bigtable;
- identificar uma row key com risco de hotspot;
- diferenciar backup, restore, replicação e alta disponibilidade;
- configurar e inspecionar um backup schedule do Firestore;
- acompanhar de forma guiada o restore de um backup Firestore;
- diagnosticar uma escolha inadequada de banco a partir do padrão de acesso;
- comparar Cloud SQL, AlloyDB, Spanner, Firestore, Bigtable e BigQuery em questões de cenário da ACE.

> **Custos:** Firestore pode gerar cobrança conforme operações, armazenamento e recursos de backup. Spanner e Bigtable podem gerar custos relevantes quando provisionados. Esta aula usa Firestore como laboratório principal, Spanner como prática guiada/condicional e Bigtable como exercício de arquitetura e inspeção.

---

# 1. Conceito

Os três serviços resolvem problemas diferentes.

| Serviço | Modelo dominante | Melhor encaixe |
|---|---|---|
| Spanner | relacional distribuído | transações relacionais em escala horizontal |
| Firestore | documentos | aplicações serverless/mobile/web orientadas a documentos |
| Bigtable | wide-column / key-value | altíssimo throughput e acesso por chave/range |
| BigQuery | warehouse analítico | SQL analítico e grandes scans/agregações |

Modelo mental:

```text
relacional distribuído
→ Spanner
documentos
→ Firestore
chave + wide-column + throughput
→ Bigtable
analytics
→ BigQuery
```

A pergunta correta não é:

```text
"qual banco suporta mais dados?"
```

A pergunta correta é:

```text
"qual é o modelo de dados?"
+
"qual é o padrão de leitura/escrita?"
+
"preciso de transações relacionais?"
+
"consulto por documento, chave/range ou SQL analítico?"
```

---

# 2. Arquitetura dos três serviços

## 2.1 Spanner

Modelo simplificado:

```text
Spanner Instance
↓
Database
↓
Schema
↓
Tables
↓
Rows
```

Spanner mantém modelo relacional e SQL, mas foi projetado para escala horizontal e distribuição.

Use quando o requisito dominante combina:

```text
relacional
+
transações
+
escala horizontal
+
alta disponibilidade/distribuição
```

Não escolha Spanner apenas porque:

```text
"o banco é grande"
```

Um Cloud SQL ou AlloyDB pode ser mais adequado quando o problema continua sendo OLTP relacional tradicional.

---

## 2.2 Firestore

Modelo:

```text
Database
↓
Collection
↓
Document
↓
Fields
```

Exemplo:

```text
clientes
├── ana
│   ├── nome: Ana
│   ├── segmento: premium
│   └── ativo: true
└── bruno
    ├── nome: Bruno
    ├── segmento: standard
    └── ativo: true
```

Firestore é orientado a documentos. Não modele a solução esperando joins relacionais tradicionais.

---

## 2.3 Bigtable

Modelo mental:

```text
Instance
↓
Cluster
↓
Table
↓
Row Key
↓
Column Family
↓
Column
↓
Cell + timestamp
```

O ponto central é a **row key**.

Bigtable organiza as linhas lexicograficamente pela row key. Por isso, a chave deve ser desenhada a partir das consultas que a aplicação fará.

Exemplo de telemetria:

```text
device-001#20261007T220000
device-001#20261007T220100
device-002#20261007T220000
```

A row key permite agrupar leituras do mesmo dispositivo em ranges contíguos.

---

# 3. Preparar o laboratório Firestore

## 3.1 Variáveis

```bash
# Obtém o projeto atualmente configurado no gcloud.
export PROJECT_ID="$(gcloud config get-value project)"
# Define um database dedicado para o laboratório.
export FIRESTORE_DB=ace-firestore
# Define a região do database.
export FIRESTORE_LOCATION=us-central1
# Mostra as variáveis para evitar operar no projeto errado.
printf 'PROJECT_ID=%s\nFIRESTORE_DB=%s\nFIRESTORE_LOCATION=%s\n' \
  "$PROJECT_ID" "$FIRESTORE_DB" "$FIRESTORE_LOCATION"
```

## 3.2 Habilitar API

```bash
# Habilita a API do Firestore.
gcloud services enable firestore.googleapis.com
```

## 3.3 Criar o database

Antes, liste os databases existentes:

```bash
# Lista os databases Firestore existentes no projeto.
gcloud firestore databases list
```

Crie um database Native mode dedicado ao laboratório:

```bash
# Cria um database Firestore Standard em Native mode.
gcloud firestore databases create \
  --database="$FIRESTORE_DB" \
  --location="$FIRESTORE_LOCATION" \
  --edition=standard \
  --type=firestore-native
```

> Se o database já existir, não execute novamente o `create`.

---

# 4. Inspecionar o Firestore

```bash
# Inspeciona localização, tipo, edição e estado do database.
gcloud firestore databases describe \
  --database="$FIRESTORE_DB"
```

Localize:

```text
name
locationId
type
databaseEdition
```

Modelo esperado:

```text
database
→ ace-firestore
type
→ FIRESTORE_NATIVE
edition
→ STANDARD
location
→ us-central1
```

---

# 5. Testar Firestore — CRUD de documentos

O `gcloud firestore` administra o database e recursos operacionais. Para tornar as operações de documentos reproduzíveis por terminal, usaremos a API REST do Firestore com um access token do `gcloud`.

## 5.1 Obter token

```bash
# Obtém um access token da identidade ativa no gcloud.
export ACCESS_TOKEN="$(gcloud auth print-access-token)"
# Confirma que a variável foi preenchida sem imprimir o token.
test -n "$ACCESS_TOKEN" && echo "ACCESS_TOKEN OK"
```

## 5.2 Criar documento Ana

```bash
# Cria o documento clientes/ana.
curl -sS -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes?documentId=ana" \
  -d '{"fields":{"nome":{"stringValue":"Ana"},"segmento":{"stringValue":"premium"},"ativo":{"booleanValue":true}}}'
```

## 5.3 Criar documento Bruno

```bash
# Cria o documento clientes/bruno.
curl -sS -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes?documentId=bruno" \
  -d '{"fields":{"nome":{"stringValue":"Bruno"},"segmento":{"stringValue":"standard"},"ativo":{"booleanValue":true}}}'
```

## 5.4 Listar documentos

```bash
# Lista os documentos da collection clientes.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes"
```

Confirme que existem:

```text
clientes/ana
clientes/bruno
```

## 5.5 Consultar um documento

```bash
# Consulta somente clientes/ana.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes/ana"
```

## 5.6 Atualizar um campo

```bash
# Atualiza somente o campo segmento de clientes/bruno.
curl -sS -X PATCH \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes/bruno?updateMask.fieldPaths=segmento" \
  -d '{"fields":{"segmento":{"stringValue":"premium"}}}'
```

Valide:

```bash
# Consulta Bruno após a alteração.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes/bruno"
```

---

# 6. Consultar Firestore com filtro

Firestore suporta consultas estruturadas sobre collections.

Consulte clientes cujo segmento é `premium`:

```bash
# Executa uma StructuredQuery filtrando segmento=premium.
curl -sS -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents:runQuery" \
  -d '{"structuredQuery":{"from":[{"collectionId":"clientes"}],"where":{"fieldFilter":{"field":{"fieldPath":"segmento"},"op":"EQUAL","value":{"stringValue":"premium"}}}}}'
```

Resultado esperado:

```text
Ana
Bruno
```

Neste ponto você praticou:

```text
CREATE document
READ document
UPDATE document
QUERY collection
```

---

# 7. Quebrar propositalmente — Firestore

## 7.1 Consultar documento inexistente

```bash
# Tenta consultar um documento que não existe.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes/carla"
```

Resultado esperado:

```text
HTTP/API error
→ document not found
```

## 7.2 Troubleshooting

**Sintoma**

```text
consulta a clientes/carla falha
```

**Hipótese**

```text
o database existe, mas o document ID informado não existe
```

**Evidência**

```bash
# Lista os documentos existentes na collection.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes"
```

**Causa**

```text
collection correta
+
document ID inexistente
```

**Correção**

Use um document ID existente ou crie o documento antes da leitura.

A variável alterada foi apenas:

```text
document ID
```

---

# 8. Excluir documento e validar

```bash
# Exclui clientes/bruno.
curl -sS -X DELETE \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes/bruno"
```

Liste novamente:

```bash
# Confirma que Bruno não aparece mais.
curl -sS \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  "https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/$FIRESTORE_DB/documents/clientes"
```

Agora o ciclo CRUD foi praticado:

```text
Create
Read
Update
Delete
```

---

# 9. Firestore — Backup e Restore

Firestore usa **backup schedules** para criar backups diários ou semanais.

Um backup contém uma cópia consistente dos dados e configurações de índice do database naquele momento.

## 9.1 Criar backup schedule

```bash
# Cria um backup schedule diário com retenção de 7 dias.
gcloud firestore backups schedules create \
  --database="$FIRESTORE_DB" \
  --recurrence=daily \
  --retention=7d
```

## 9.2 Inspecionar o schedule

```bash
# Lista os backup schedules do database.
gcloud firestore backups schedules list \
  --database="$FIRESTORE_DB"
```

Observe:

```text
recurrence
retention
resource name
```

## 9.3 Listar backups

O backup não é necessariamente criado imediatamente após o schedule.

```bash
# Lista backups disponíveis no projeto.
gcloud firestore backups list \
  --format="table(name,database,state)"
```

### Classificação M/E/P

```text
criar backup schedule
→ P
listar/inspecionar schedule
→ P
aguardar geração do backup
→ P*
restore efetivo
→ P*
```

O `P*` existe porque o horário do backup agendado não é controlado pelo laboratório.

## 9.4 Restore guiado

Quando existir um backup disponível, copie seu resource name:

```text
projects/PROJECT_ID/locations/LOCATION/backups/BACKUP_ID
```

Defina:

```bash
# Informe o resource name real retornado por backups list.
export FIRESTORE_BACKUP="projects/PROJECT_ID/locations/LOCATION/backups/BACKUP_ID"
# Define um NOVO database para receber o restore.
export FIRESTORE_RESTORE_DB=ace-firestore-restore
```

O restore padrão cria um **novo database**:

```bash
# Restaura o backup em um novo database.
gcloud firestore databases restore \
  --source-backup="$FIRESTORE_BACKUP" \
  --destination-database="$FIRESTORE_RESTORE_DB"
```

Inspecione:

```bash
# Inspeciona o database restaurado.
gcloud firestore databases describe \
  --database="$FIRESTORE_RESTORE_DB"
```

Modelo mental:

```text
Firestore database
↓ backup schedule
Backup
↓ restore
novo Firestore database
```

Não confunda:

```text
Backup/Restore
→ recuperação de dados
HA/replicação
→ disponibilidade
```

---

# 10. Spanner — arquitetura e prática guiada

## 10.1 Por que P*

O Spanner possui instância de teste gratuita por tempo limitado para projetos elegíveis. Entretanto:

```text
eligibilidade
+
billing habilitado
+
limite por projeto/conta
```

fazem com que a prática seja classificada como `P*`.

Não crie uma instância paga apenas para concluir esta aula.

## 10.2 Variáveis

```bash
# Define recursos do laboratório Spanner.
export SPANNER_INSTANCE=ace-spanner
export SPANNER_DB=ace-db
export SPANNER_CONFIG=regional-us-central1
```

## 10.3 Criar instância gratuita — somente se elegível

```bash
# Habilita a API do Spanner.
gcloud services enable spanner.googleapis.com
# Cria uma free trial instance, se o projeto for elegível.
gcloud spanner instances create "$SPANNER_INSTANCE" \
  --instance-type=free-instance \
  --config="$SPANNER_CONFIG" \
  --description="ACE Spanner Lab"
```

> A free trial instance é limitada por projeto/ciclo de vida. Não a exclua automaticamente se pretende continuar usando-a em outros estudos.

## 10.4 Inspecionar

```bash
# Lista as instâncias Spanner.
gcloud spanner instances list
# Inspeciona a instância do laboratório.
gcloud spanner instances describe "$SPANNER_INSTANCE"
```

## 10.5 Criar database e schema

```bash
# Cria um database GoogleSQL com a tabela Clientes.
gcloud spanner databases create "$SPANNER_DB" \
  --instance="$SPANNER_INSTANCE" \
  --ddl="CREATE TABLE Clientes (ClienteId INT64 NOT NULL, Nome STRING(100), Segmento STRING(30)) PRIMARY KEY (ClienteId)"
```

Inspecione:

```bash
# Lista databases da instância.
gcloud spanner databases list \
  --instance="$SPANNER_INSTANCE"
# Exibe o DDL do database.
gcloud spanner databases ddl describe "$SPANNER_DB" \
  --instance="$SPANNER_INSTANCE"
```

## 10.6 Inserir dados

```bash
# Insere duas linhas usando DML.
gcloud spanner databases execute-sql "$SPANNER_DB" \
  --instance="$SPANNER_INSTANCE" \
  --sql="INSERT INTO Clientes (ClienteId, Nome, Segmento) VALUES (1, 'Ana', 'premium'), (2, 'Bruno', 'standard')"
```

## 10.7 Consultar

```bash
# Executa uma consulta SQL relacional no Spanner.
gcloud spanner databases execute-sql "$SPANNER_DB" \
  --instance="$SPANNER_INSTANCE" \
  --sql="SELECT ClienteId, Nome, Segmento FROM Clientes ORDER BY ClienteId"
```

O objetivo não é aprender SQL novamente. É reconhecer:

```text
Spanner
→ relacional
→ schema
→ SQL
→ transações
→ escala horizontal
```

---

# 11. Bigtable — arquitetura, row key e hotspots

Bigtable não será provisionado nesta aula para evitar um recurso pago apenas para demonstrar conceitos que podem ser avaliados por arquitetura e inspeção.

Classificação:

```text
Bigtable operacional
→ E/P*
row key e decisão arquitetural
→ E
```

## 11.1 Inspecionar recursos existentes

```bash
# Lista instâncias Bigtable existentes no projeto.
gcloud bigtable instances list
```

Se não houver instância:

```text
resultado vazio
→ esperado no laboratório
```

Não crie uma instância apenas para preencher a lista.

## 11.2 Modelo de dados

```text
table: telemetria
column family: metricas
row key: device-001#20261007T220000
columns:
  cpu
  memoria
  temperatura
```

O schema deve ser orientado pelas consultas.

Se a consulta principal é:

```text
"leituras do device-001 em determinado intervalo"
```

uma chave com prefixo do dispositivo permite agrupar os dados relacionados.

## 11.3 Row key inadequada

Considere:

```text
20261007T220000#device-001
20261007T220001#device-002
20261007T220002#device-003
```

Problema:

```text
timestamp no início
+
escritas sequenciais
↓
concentração em uma faixa de chaves
↓
risco de hotspot
```

Uma alternativa coerente com consulta por dispositivo:

```text
device-001#20261007T220000
device-002#20261007T220001
device-003#20261007T220002
```

A escolha final depende do padrão real de consulta.

## 11.4 Quebrar propositalmente — decisão de row key

Requisito:

```text
milhões de devices enviam telemetria continuamente
+
row key começa somente pelo timestamp
```

Diagnóstico:

**Sintoma**

```text
latência aumenta durante escrita intensa
```

**Hipótese**

```text
as escritas estão concentradas em uma pequena faixa de row keys
```

**Evidência**

```text
row keys sequenciais iniciadas por timestamp
```

**Causa**

```text
hotspot
```

**Correção**

Redesenhar a row key considerando:

```text
padrão de consulta
+
distribuição das escritas
+
prefixos/ranges necessários
```

---

# 12. Falha proposital — escolha do banco

Cenário:

> Precisamos executar SQL analítico ad hoc, joins e grandes agregações sobre terabytes de histórico. A equipe escolheu Bigtable porque o volume é alto.

Diagnostique antes de continuar.

## Troubleshooting

**Sintoma**

```text
consultas analíticas exigem scans, joins e agregações
```

**Hipótese**

```text
o serviço foi escolhido pelo volume, não pelo padrão de acesso
```

**Evidência**

```text
requisito dominante
→ SQL analítico ad hoc
```

**Causa**

```text
Bigtable foi usado como se fosse um data warehouse
```

**Correção**

```text
BigQuery
```

Bigtable é candidato quando o requisito dominante é acesso de baixa latência e alto throughput orientado a row key/ranges.

---

# 13. Matriz de decisão

| Requisito dominante | Serviço candidato |
|---|---|
| OLTP relacional tradicional | Cloud SQL |
| PostgreSQL-compatible de alto desempenho | AlloyDB |
| relacional distribuído/horizontal | Spanner |
| documentos serverless | Firestore |
| chave/range + altíssimo throughput | Bigtable |
| SQL analítico / warehouse | BigQuery |

## Não usar quando

| Serviço | Evite quando |
|---|---|
| Spanner | não existe necessidade de relacional distribuído/escala horizontal |
| Firestore | aplicação depende de joins relacionais tradicionais |
| Bigtable | requisito dominante é BI/SQL analítico ad hoc |
| BigQuery | workload é OLTP transacional por registro |

---

# 14. Questões estilo ACE

### Questão 1

Uma aplicação financeira precisa de banco relacional transacional e escala horizontal.

**Resposta:** Spanner.

### Questão 2

Uma aplicação web armazena perfis e preferências como documentos e quer operação serverless.

**Resposta:** Firestore.

### Questão 3

Milhões de dispositivos enviam séries de telemetria e as leituras são feitas principalmente por device e intervalo.

**Resposta:** Bigtable.

### Questão 4

A empresa precisa executar SQL ad hoc, joins e agregações sobre grandes volumes históricos.

**Resposta:** BigQuery.

### Questão 5

Uma tabela Bigtable recebe escritas sequenciais e a row key começa pelo timestamp. A latência aumenta.

**Resposta:** investigar hotspot provocado pelo desenho da row key.

### Questão 6

A equipe precisa recuperar documentos apagados acidentalmente do Firestore.

**Resposta:** backup/restore, se houver backup adequado disponível.

---

# 15. M/E/P

| Conteúdo | Nível |
|---|---:|
| Spanner — arquitetura/modelo | `E` |
| Spanner — criar/inspecionar/query | `P*` |
| Firestore — criar/inspecionar database | `P` |
| Firestore — CRUD de documentos | `P` |
| Firestore — query filtrada | `P` |
| Firestore — falha e troubleshooting | `P` |
| Firestore — criar/inspecionar backup schedule | `P` |
| Firestore — backup efetivamente gerado | `P*` |
| Firestore — restore | `P*` |
| Bigtable — arquitetura/modelo | `E` |
| Bigtable — row key/hotspot | `E` |
| Bigtable — provisionamento/query | `P*` |
| Matriz de decisão | `E` |
| Escolha inadequada + troubleshooting | `P` |

`P*` significa prática guiada ou condicional por elegibilidade, tempo de geração do recurso ou custo.

---

# 16. Checklist

- [ ] Diferenciei Spanner, Firestore, Bigtable e BigQuery por padrão de acesso;
- [ ] Criei e inspecionei um database Firestore;
- [ ] Criei documentos no Firestore;
- [ ] Consultei documentos e collection;
- [ ] Atualizei um documento;
- [ ] Executei uma query filtrada;
- [ ] Provoquei e diagnostiquei uma leitura de documento inexistente;
- [ ] Excluí um documento;
- [ ] Criei e inspecionei um backup schedule;
- [ ] Entendi que o backup é gerado de forma agendada;
- [ ] Entendi que o restore padrão usa um novo database;
- [ ] Entendi instance → database → schema → table no Spanner;
- [ ] Executei ou acompanhei a prática guiada de SQL no Spanner;
- [ ] Entendi instance → cluster → table → row key → column family no Bigtable;
- [ ] Expliquei por que timestamp no início da row key pode provocar hotspot;
- [ ] Diferenciei backup de HA/replicação;
- [ ] Diagnostiquei uma escolha inadequada de Bigtable para analytics;
- [ ] Consigo escolher o serviço em uma questão de cenário ACE;
- [ ] Executei o cleanup aplicável.

---

# 17. Cleanup

## 17.1 Firestore — remover backup schedule

Primeiro liste os schedules:

```bash
# Lista os schedules para obter o ID real.
gcloud firestore backups schedules list \
  --database="$FIRESTORE_DB"
```

Se você criou o schedule nesta aula, exclua-o usando o ID retornado:

```bash
# Substitua pelo ID real do schedule.
export BACKUP_SCHEDULE_ID="BACKUP_SCHEDULE_ID"
# Remove o backup schedule criado no laboratório.
gcloud firestore backups schedules delete \
  --database="$FIRESTORE_DB" \
  --backup-schedule="$BACKUP_SCHEDULE_ID" \
  --quiet
```

> Excluir o schedule não exclui backups que já tenham sido gerados.

## 17.2 Firestore — remover database restaurado

Execute somente se você realizou o restore:

```bash
# Remove o database criado como destino do restore.
gcloud firestore databases delete \
  --database="$FIRESTORE_RESTORE_DB" \
  --quiet
```

## 17.3 Firestore — remover database do laboratório

```bash
# Remove o database Firestore dedicado à aula.
gcloud firestore databases delete \
  --database="$FIRESTORE_DB" \
  --quiet
```

## 17.4 Spanner

Se você criou uma **instância paga** exclusivamente para laboratório, remova-a para interromper cobrança.

Se usou uma **free trial instance**, não a exclua automaticamente: a elegibilidade permite quantidade limitada de instâncias gratuitas e a exclusão não deve ser feita sem decidir se você ainda pretende utilizá-la.

Para uma instância paga descartável:

```bash
# ATENÇÃO: execute somente se esta instância deve realmente ser removida.
gcloud spanner instances delete "$SPANNER_INSTANCE"
```

## 17.5 Bigtable

Nenhum recurso Bigtable foi criado no fluxo principal, portanto não há cleanup.

---

# 18. Referências oficiais

- Firestore — gerenciamento de databases.
- Firestore — consultas e filtros.
- Firestore — backup schedules e restore.
- Spanner — free trial instance.
- Spanner — criação e consultas com gcloud.
- Bigtable — boas práticas de schema e row keys.
