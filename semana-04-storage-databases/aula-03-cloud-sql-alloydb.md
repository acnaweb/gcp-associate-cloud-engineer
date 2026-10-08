# Aula 3 — Cloud SQL e AlloyDB


## Objetivos


Ao final, você deverá:

- entender o problema que Cloud SQL resolve;

- criar uma instância PostgreSQL gerenciada;

- criar database e usuário;

- inspecionar estado, versão, região, IP e configurações de backup;

- validar os pré-requisitos de conexão (`cloud-sql-proxy`, `psql` e ADC) quando usar ambiente local;
- conectar ao Cloud SQL pelo Cloud Shell ou por ambiente local;

- criar tabela e validar persistência;

- entender, antes do troubleshooting, IP público, usuário, database e estado da instância;

- provocar erros de senha/database de forma controlada;

- diferenciar Cloud SQL e AlloyDB no nível esperado para ACE.


> **Custos:** Cloud SQL gera cobrança enquanto a instância existir. Cleanup é obrigatório.


---


# 1. Conceito


Cloud SQL é um banco relacional gerenciado para MySQL, PostgreSQL e SQL Server. O Google gerencia infraestrutura, patches de plataforma, backups configuráveis e mecanismos de disponibilidade, enquanto você continua responsável por schema, usuários, queries e escolhas de configuração.


AlloyDB é PostgreSQL-compatible, mas possui arquitetura própria voltada a workloads PostgreSQL mais exigentes. Para ACE, o objetivo principal é reconhecer o caso de uso, não administrar profundamente AlloyDB.


### Conceitos que serão usados no troubleshooting


Antes de quebrar qualquer coisa, precisamos conhecer:


1\. **Estado da instância** — `RUNNABLE` indica que a instância está disponível.

2\. **Database** — conexão aponta para um database existente.

3\. **Usuário** — autenticação usa um usuário configurado no Cloud SQL.

4\. **Senha** — credencial do usuário; erro gera falha de autenticação.

5\. **IP público/privado** — determina o caminho de conectividade.

6\. **Authorized networks / Cloud SQL Auth Proxy / conectores** — métodos diferentes de conexão.

7\. **Backup configuration** — recuperação não é o mesmo que alta disponibilidade.

8\. **Availability type** — disponibilidade regional é uma configuração separada de backup.


Nenhum desses conceitos aparecerá no troubleshooting sem antes ser inspecionado no laboratório.


## Arquitetura mental


```text
Aplicação / Cloud Shell
        |
        v
Cloud SQL for PostgreSQL
 ├─ instance
 ├─ database: aceapp
 ├─ user: aceuser
 ├─ IP/configuração de conexão
 └─ backups/configuração
AlloyDB
 └─ PostgreSQL-compatible para requisitos maiores de performance/HA
```


---


# 2. Criar


> **Atenção:** Cloud SQL gera cobrança. Use uma instância pequena compatível com sua conta/região e exclua no final.


```bash
# Explicação: Define `REGION` com o valor da região padrão usada pelos recursos do laboratório.
export REGION=us-central1
# Explicação: Define `INSTANCE` com o nome da instância usada no laboratório.
export INSTANCE=ace-sql
# Explicação: Define a variável `DB` usada nas próximas etapas do laboratório.
export DB=aceapp
# Explicação: Define a variável `DB_USER` usada nas próximas etapas do laboratório.
export DB_USER=aceuser
# Explicação: Habilita a API/serviço indicado no projeto ativo para permitir o uso do recurso no laboratório.
gcloud services enable sqladmin.googleapis.com
```


### 2.1 Escolhendo a edição corretamente


Para **PostgreSQL 16 ou superior**, o Cloud SQL usa **Enterprise Plus** como edição padrão quando `--edition` não é informado.


Isso é importante porque as edições usam modelos de máquina diferentes:


```text
Enterprise
→ aceita tipos de máquina customizados
→ podemos usar --cpu e --memory
Enterprise Plus
→ usa tipos de máquina predefinidos
→ exemplo: db-perf-optimized-N-*
```


Neste laboratório queremos uma instância pequena e didática:


```text
POSTGRES_16
+
1 vCPU
+
3840 MiB
```


Por isso, devemos informar explicitamente:


```text
--edition=ENTERPRISE
```


Sem essa flag, o comando pode tentar criar uma instância Enterprise Plus e retornar erro semelhante a:


```text
Invalid Tier (db-custom-1-3840) for (ENTERPRISE_PLUS) Edition
```


Agora crie a instância:


```sh
# PostgreSQL 16+ usa Enterprise Plus como edição padrão quando --edition
# não é informado. Enterprise Plus exige tipos de máquina predefinidos.
#
# Como este laboratório usa uma configuração customizada pequena com
# --cpu e --memory, fixamos explicitamente a edição Enterprise.
#
# --edition=ENTERPRISE
#   permite o uso do dimensionamento customizado deste laboratório.
#
# --cpu=1
#   define 1 vCPU.
#
# --memory=3840MiB
#   define 3,75 GiB de memória, valor mínimo compatível com este perfil.
gcloud sql instances create "$INSTANCE" \
  --database-version=POSTGRES_16 \
  --edition=ENTERPRISE \
  --cpu=1 \
  --memory=3840MiB \
  --region="$REGION" \
  --storage-size=10GB
# Explicação: Cria um database lógico dentro da instância Cloud SQL.
gcloud sql databases create "$DB" \
  --instance="$INSTANCE"
# Explicação: Cria um usuário de banco na instância Cloud SQL.
gcloud sql users create "$DB_USER" \
  --instance="$INSTANCE" \
  --password='Ace-Lab-12345!'
```


---


# 3. Inspecionar


Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.


### 3.1 Estado, engine, edição, tier e região

```bash
# Exibe os principais atributos da instância.
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(name,state,databaseVersion,region,settings.edition,settings.tier,settings.availabilityType)"
```

Localize:

```text
state
databaseVersion
region
settings.edition
settings.tier
settings.availabilityType
```

Para este laboratório, confirme:

```text
databaseVersion
→ POSTGRES_16
settings.edition
→ ENTERPRISE
settings.tier
→ db-custom-1-3840
state
→ RUNNABLE
```

Isso confirma que a instância foi criada na edição correta e que o tier customizado foi aceito.

### 3.2 IPs


```bash
# Explicação: Exibe configuração e estado da instância Cloud SQL para inspeção.
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(ipAddresses)"
```


Agora você sabe se há endereço público configurado.


### 3.3 Databases


```bash
# Explicação: Lista databases existentes na instância Cloud SQL.
gcloud sql databases list \
  --instance="$INSTANCE"
```


Confirme que `aceapp` existe.


### 3.4 Usuários


```bash
# Explicação: Lista usuários configurados na instância Cloud SQL.
gcloud sql users list \
  --instance="$INSTANCE"
```


Confirme que `aceuser` existe.


### 3.5 Backup


```bash
# Explicação: Exibe configuração e estado da instância Cloud SQL para inspeção.
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(settings.backupConfiguration)"
```


O objetivo é reconhecer se backup está habilitado/configurado. Não confunda backup com HA.


### 3.6 Pré-requisitos da conexão

O comando:

```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```

precisa encontrar o cliente PostgreSQL e conseguir autenticar o caminho de conexão.

| Ambiente | Normalmente disponível | Pode exigir configuração |
|---|---|---|
| Cloud Shell | `gcloud`, `psql` | autorização da sessão |
| Linux local / VM | depende da instalação | Cloud SQL Auth Proxy, `psql` e ADC |

> Os comandos de instalação abaixo são para **Linux x86_64 / Debian ou Ubuntu**.

#### 3.6.1 Verificar o Cloud SQL Auth Proxy

```bash
# Verifica se o proxy está disponível no PATH.
command -v cloud-sql-proxy
# Mostra a versão instalada.
cloud-sql-proxy --version
```

Se não estiver instalado:

```bash
# Baixa o Cloud SQL Auth Proxy v2 para Linux x86_64.
curl -o cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.26.0/cloud-sql-proxy.linux.amd64
# Torna o binário executável.
chmod +x cloud-sql-proxy
# Instala em um diretório normalmente presente no PATH.
sudo mv cloud-sql-proxy /usr/local/bin/cloud-sql-proxy
# Confirma a instalação.
cloud-sql-proxy --version
```

> `gcloud components install cloud-sql-proxy` não é uma solução universal. Quando o Google Cloud CLI é instalado pelo gerenciador de pacotes do sistema, componentes adicionais podem não estar disponíveis por `gcloud components`.

---

#### 3.6.2 Verificar o cliente PostgreSQL (`psql`)

```bash
# Verifica se psql está no PATH.
command -v psql
# Mostra a versão instalada.
psql --version
```

Se não estiver instalado em Debian/Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y postgresql-client
psql --version
```

O `gcloud sql connect` precisa localizar `psql` para abrir a sessão PostgreSQL.

---

#### 3.6.3 Entender `gcloud auth login` x ADC

```text
gcloud auth login
→ autentica a CLI gcloud
Application Default Credentials (ADC)
→ credenciais descobertas automaticamente por aplicações e conectores
```

Em ambiente local, configure ADC:

```bash
# Cria Application Default Credentials locais.
gcloud auth application-default login
```

Valide:

```bash
# Se retornar um token, ADC está funcionando.
gcloud auth application-default print-access-token
```

Se o proxy retornar:

```text
could not find default credentials
```

configure ADC antes de repetir a conexão.

---

#### 3.6.4 Checklist rápido do ambiente local

```bash
# 1. Conta ativa no gcloud.
gcloud auth list
# 2. ADC disponível.
gcloud auth application-default print-access-token >/dev/null \
  && echo "ADC OK"
# 3. Proxy disponível.
cloud-sql-proxy --version
# 4. Cliente PostgreSQL disponível.
psql --version
```

Modelo mental:

```text
gcloud autenticado
+
ADC
+
cloud-sql-proxy
+
psql
=
ambiente pronto
```

---

### 3.7 Conectividade

```bash
# Abre uma conexão SQL autenticada com a instância e database informados.
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```

Em Cloud Shell, o fluxo pode autorizar temporariamente o IP da sessão. Em ambiente local, versões atuais do `gcloud sql connect` podem iniciar o Cloud SQL Auth Proxy e, por isso, dependem dos pré-requisitos verificados acima.

Quando solicitado, use:

```text
Ace-Lab-12345!
```

Dentro do `psql`:

```sql
-- Confirma o database atual.
SELECT current_database();
-- Confirma o usuário atual.
SELECT current_user;
-- Cria a tabela usada no laboratório.
CREATE TABLE clientes (
  id INTEGER PRIMARY KEY,
  nome TEXT NOT NULL
);
-- Insere dados de teste.
INSERT INTO clientes VALUES
(1, 'Ana'),
(2, 'Bruno');
-- Confirma os dados persistidos.
SELECT * FROM clientes;
```

Saia:

```text
\q
```

---

## Enterprise x Enterprise Plus neste laboratório


Para a ACE, não memorize apenas o erro. Entenda a decisão:


| Situação | Escolha |

|---|---|

| laboratório pequeno com CPU/memória customizadas | `ENTERPRISE` |

| Enterprise Plus com PostgreSQL 16+ | tier predefinido compatível |

| usar `--cpu` e `--memory` | fixar `--edition=ENTERPRISE` |


Modelo mental:


```text
POSTGRES_16 sem --edition
→ default pode ser ENTERPRISE_PLUS
ENTERPRISE_PLUS
→ tier predefinido
ENTERPRISE
→ pode usar --cpu + --memory
```


---


# 4. Testar


### Teste 1 — persistência


Conecte novamente:


```bash
# Explicação: Abre uma conexão SQL autenticada com a instância e database informados.
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```


Execute:


```sql
-- Explicação: Executa uma consulta para recuperar/validar os dados descritos nesta etapa.
SELECT * FROM clientes;
```


Os dados devem continuar lá.


### Teste 2 — estado


```bash
# Explicação: Exibe configuração e estado da instância Cloud SQL para inspeção.
gcloud sql instances describe "$INSTANCE" \
  --format="value(state)"
```


### Teste 3 — diferenciar backup e HA


Confira simultaneamente:


```bash
# Explicação: Exibe configuração e estado da instância Cloud SQL para inspeção.
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(settings.availabilityType,settings.backupConfiguration)"
```


Pergunta:


> Uma instância pode possuir backup configurado sem ser HA?


Sim. São mecanismos diferentes.


---


# 5. Quebrar propositalmente


Vamos quebrar dois elementos **já ensinados**.


### Falha A — database incorreto


```bash
# Explicação: Abre uma conexão SQL autenticada com a instância e database informados.
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database=banco-que-nao-existe
```


### Falha B — usuário incorreto


```bash
# Explicação: Abre uma conexão SQL autenticada com a instância e database informados.
gcloud sql connect "$INSTANCE" \
  --user=usuario-que-nao-existe \
  --database="$DB"
```


> Para erro de senha, o comando interativo solicitará a senha. Digite deliberadamente uma senha incorreta e observe a mensagem de autenticação.


---


# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

## Caso 0A — Cloud SQL Auth Proxy não encontrado

**Sintoma:**

```text
Cloud SQL Proxy (v2) couldn't be found in PATH
```

**Hipótese:** `cloud-sql-proxy` não está instalado ou não está no `PATH`.

**Evidência:**

```bash
command -v cloud-sql-proxy
```

**Causa:** o ambiente local não possui o binário necessário.

**Correção:** instale conforme a seção 3.6.1 e valide:

```bash
cloud-sql-proxy --version
```

---

## Caso 0B — `psql` não encontrado

**Sintoma:**

```text
Psql client not found
```

**Hipótese:** o cliente PostgreSQL não está instalado ou não está no `PATH`.

**Evidência:**

```bash
command -v psql
```

**Causa:** o fluxo chegou à abertura do cliente PostgreSQL, mas não encontrou `psql`.

**Correção em Debian/Ubuntu:**

```bash
sudo apt-get update
sudo apt-get install -y postgresql-client
psql --version
```

---

## Caso 0C — ADC ausente

**Sintoma:**

```text
failed to create default credentials
could not find default credentials
```

**Hipótese:** a CLI pode estar autenticada, mas ADC não está configurado.

**Evidência:**

```bash
gcloud auth list
gcloud auth application-default print-access-token
```

Se o primeiro funcionar e o segundo falhar:

```text
credencial da CLI
≠
ADC
```

**Causa:** o Cloud SQL Auth Proxy tentou descobrir credenciais via ADC e não encontrou.

**Correção:**

```bash
gcloud auth application-default login
gcloud auth application-default print-access-token
```

Depois repita:

```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```

---


## Caso A — database inexistente


**Sintoma:** conexão informa que o database não existe.


**Hipótese:** o nome passado em `--database` não está na instância.


**Evidência:**

```bash
# Explicação: Lista databases existentes na instância Cloud SQL.
gcloud sql databases list --instance="$INSTANCE"
```


**Causa:** usamos deliberadamente `banco-que-nao-existe`.


**Correção:** usar `aceapp`.


---


## Caso B — usuário inexistente


**Sintoma:** falha envolvendo usuário/role não existente.


**Hipótese:** `--user` não corresponde a um usuário do Cloud SQL.


**Evidência:**

```bash
# Explicação: Lista usuários configurados na instância Cloud SQL.
gcloud sql users list --instance="$INSTANCE"
```


**Causa:** usamos deliberadamente `usuario-que-nao-existe`.


**Correção:** usar `aceuser`.


---


## Caso C — senha incorreta


**Sintoma:** autenticação falha.


**Hipótese:** usuário existe, mas a senha fornecida não corresponde.


**Evidências:**

```bash
# Explicação: Lista usuários configurados na instância Cloud SQL.
gcloud sql users list --instance="$INSTANCE"
```


Isso confirma que o usuário existe. A senha não é exibida pelo serviço.


**Causa:** senha incorreta digitada deliberadamente.


**Correção:** usar a senha correta ou redefini-la:


```bash
# Explicação: Redefine a senha do usuário Cloud SQL indicado.
gcloud sql users set-password "$DB_USER" \
  --instance="$INSTANCE" \
  --password='Ace-Lab-12345!'
```


---


## O que NÃO investigar primeiro nesses três casos


Não comece por:


```text
VPC
Firewall
Route
Cloud NAT
```


porque o próprio `gcloud sql connect` chegou ao serviço e retornou erros específicos de database/usuário/autenticação.


A mensagem de erro é evidência.


Use sempre:


```text
Sintoma
   ↓
Hipótese
   ↓
Evidência
   ↓
Causa
   ↓
Correção
```


---


# 7. Corrigir


Conecte com os três valores corretos:


```bash
# Explicação: Abre uma conexão SQL autenticada com a instância e database informados.
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```


Senha:


```text
Ace-Lab-12345!
```


Valide:


```sql
-- Explicação: Executa uma consulta para recuperar/validar os dados descritos nesta etapa.
SELECT current_database(), current_user;
-- Explicação: Executa uma consulta para recuperar/validar os dados descritos nesta etapa.
SELECT * FROM clientes;
```


### Cloud SQL x AlloyDB


Use este modelo:


```text
Cloud SQL
→ MySQL, PostgreSQL, SQL Server
→ aplicações relacionais tradicionais
→ operação gerenciada
→ HA e backups configuráveis
AlloyDB
→ PostgreSQL-compatible
→ arquitetura própria do Google
→ workloads PostgreSQL exigentes em performance/escala
```


Para ACE, escolha pelo requisito; não transforme a questão em tuning avançado.


---


# 8. Questões estilo ACE


1\. Aplicação existente usa MySQL e quer banco gerenciado com mínima mudança. **Cloud SQL**.

2\. Backup e HA são a mesma configuração? **Não**.

3\. Erro “database does not exist”: qual evidência primeiro? **`gcloud sql databases list`**.

4\. Erro de autenticação mas usuário existe: o que verificar? **Senha/credencial**, não route table.

5\. Workload PostgreSQL-compatible com requisitos maiores de desempenho e arquitetura AlloyDB: **AlloyDB**.


---


---


# 9. Backup e Restore — prática completa


Backup e Restore não são a mesma coisa que HA.


```text
HA
→ disponibilidade/failover
Backup
→ cópia para recuperação
Restore
→ recupera o estado da instância a partir de um backup
```


> **Atenção:** restaurar sobre uma instância existente sobrescreve os dados do destino e causa indisponibilidade durante a operação. Faça este laboratório apenas na instância descartável criada nesta aula.


---


## 9.1 Validar o dado antes do backup


Conecte:


```bash
# Abre conexão com o database usado no laboratório.
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```


Execute:


```sql
SELECT * FROM clientes ORDER BY id;
```


Resultado esperado:


```text
1 | Ana
2 | Bruno
```


Saia:


```text
\q
```


---


## 9.2 Criar backup on-demand


Crie um backup manual:


```bash
# Cria um backup on-demand da instância Cloud SQL.
gcloud sql backups create \
  --instance="$INSTANCE"
```


Liste os backups:


```bash
# Lista backups da instância, incluindo ID e estado.
gcloud sql backups list \
  --instance="$INSTANCE"
```


Capture o backup mais recente com estado `SUCCESSFUL`:


```bash
# Obtém o ID do backup bem-sucedido mais recente.
export BACKUP_ID="$(gcloud sql backups list \
  --instance="$INSTANCE" \
  --filter="status=SUCCESSFUL" \
  --sort-by="~endTime" \
  --limit=1 \
  --format='value(id)')"
echo "$BACKUP_ID"
```


Valide:


```text
BACKUP_ID
→ deve conter um ID de backup válido
```


---


## 9.3 Alterar o dado depois do backup


Agora provoque uma alteração lógica segura **depois** do backup.


Conecte novamente:


```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```


Apague uma linha:


```sql
DELETE FROM clientes
WHERE id = 2;
SELECT * FROM clientes ORDER BY id;
```


Resultado esperado:


```text
1 | Ana
```


Saia:


```text
\q
```


Agora temos:


```text
Backup
→ contém Ana + Bruno
Estado atual
→ contém apenas Ana
```


---


## 9.4 Restaurar o backup


Restaure o backup sobre a própria instância do laboratório:


```bash
# Restaura o backup selecionado na instância atual.
#
# --restore-instance
#   define a instância de destino.
#
# --backup-instance
#   informa a instância de origem do backup.
gcloud sql backups restore "$BACKUP_ID" \
  --restore-instance="$INSTANCE" \
  --backup-instance="$INSTANCE" \
  --quiet
```


Durante o restore:


```text
instância
→ temporariamente indisponível
dados atuais do destino
→ sobrescritos pelo conteúdo do backup
```


---


## 9.5 Inspecionar o estado após o restore


Confirme que a instância voltou a ficar disponível:


```bash
# Exibe o estado da instância após a restauração.
gcloud sql instances describe "$INSTANCE" \
  --format="value(state)"
```


Resultado esperado:


```text
RUNNABLE
```


Liste as operações recentes:


```bash
# Mostra as operações recentes da instância.
gcloud sql operations list \
  --instance="$INSTANCE" \
  --limit=5
```


---


## 9.6 Validar a recuperação do dado


Conecte novamente:


```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```


Execute:


```sql
SELECT * FROM clientes ORDER BY id;
```


Resultado esperado novamente:


```text
1 | Ana
2 | Bruno
```


Isso comprova operacionalmente:


```text
criar dados
↓
backup
↓
alterar/apagar dado
↓
restore
↓
dado recuperado
```


Saia:


```text
\q
```


---


# 10. HA, Read Replica, PITR e Database Center


## 10.1 Backup x Restore x HA x Read Replica


```text
Backup
→ recuperação de dados
Restore
→ recupera estado a partir do backup
HA
→ disponibilidade/failover
Read replica
→ leitura/escala e, dependendo da arquitetura, estratégia de DR
→ não substitui backup
```


Para a ACE:


```text
"recuperar dado apagado"
→ Backup / Restore ou PITR
"reduzir indisponibilidade por falha de zona"
→ HA
"escalar leitura"
→ Read Replica
```


---


## 10.2 PITR


Point-in-Time Recovery é outro mecanismo de recuperação.


Modelo:


```text
Backup
→ recupera um estado capturado em um backup
PITR
→ recupera para um ponto específico no tempo
```


Não confunda:


```text
PITR
≠
HA
```


A configuração detalhada de PITR não é necessária para este laboratório; o objetivo aqui é saber escolher o mecanismo correto em cenários de prova.


---


## 10.3 Database Center


Database Center oferece uma visão central da frota de bancos suportados no Google Cloud.


Use para responder perguntas como:


```text
Quais bancos existem?
Quais possuem alertas ou insights?
Como está a frota em diferentes projetos?
```


No Console:


```text
Database Center
```


---


# 11. Estimativa de custos de banco


Antes de usar a Pricing Calculator, decomponha o custo.


## Cloud SQL


```text
compute / machine tier
+ armazenamento provisionado
+ backups
+ HA regional, quando habilitada
+ read replicas
+ transferência de rede
```


## AlloyDB


```text
compute dos nós
+ armazenamento
+ arquitetura HA / read pools
+ transferência
```


Compare na Pricing Calculator:


```text
Cenário 1
Cloud SQL pequeno, single-zone, sem réplica
Cenário 2
Cloud SQL com HA regional
Cenário 3
Cloud SQL com HA + read replica
```


Use a mesma região, engine e horizonte mensal.


| Cenário | Compute | Storage | HA/Replica | Backup | Estimativa mensal |

|---|---:|---:|---:|---:|---:|

| 1 | | | | | |

| 2 | | | | | |

| 3 | | | | | |


Para prova:


```text
Alta disponibilidade
≠
backup
Read replica
≠
HA automática
Mais resiliência / mais capacidade
→ normalmente mais recursos faturáveis
```


---


# 12. Critério de aceite M/E/P desta aula


Para um tópico ser classificado como `P`, não basta existir um comando.


A aula precisa apresentar:


```text
conceito operacional
↓
configuração/comando
↓
inspeção
↓
teste ou comportamento observável
```


Quando a execução depender de privilégio administrativo, custo relevante ou infraestrutura especial, use `P*`.


| Tópico | Nível |

|---|---:|

| Cloud SQL — criar/inspecionar/conectar/query | `P` |

| Troubleshooting de database/usuário/senha | `P` |

| Backup Cloud SQL | `P` |

| Restore Cloud SQL | `P` |

| Validação do dado após restore | `P` |

| Cloud SQL x AlloyDB | `E` |

| AlloyDB operacional | `E/P*` |

| Estimativa de custos | `E/P*` |


A diferença importante em relação à versão anterior é:


```text
Restore
antes → apenas mencionado/orientado
Restore
agora → executado, inspecionado e validado
```


---


# 13. Checklist


- [ ] Entendi o problema que Cloud SQL resolve;

- [ ] Criei uma instância PostgreSQL gerenciada;

- [ ] Criei database e usuário;

- [ ] Inspecionei estado, versão, região, IP e backup;

- [ ] Validei `cloud-sql-proxy`, `psql` e ADC quando necessário;
- [ ] Diferenciei autenticação da CLI gcloud de ADC;
- [ ] Conectei pelo Cloud Shell ou por ambiente local;

- [ ] Criei tabela e validei persistência;

- [ ] Provoquei falhas de database, usuário e senha;

- [ ] Diagnostiquei usando evidências;

- [ ] Diferenciei Cloud SQL e AlloyDB;

- [ ] Criei um backup on-demand;

- [ ] Capturei o `BACKUP_ID`;

- [ ] Alterei o dado depois do backup;

- [ ] Executei um restore real;

- [ ] Confirmei `RUNNABLE` após o restore;

- [ ] Validei a recuperação do dado;

- [ ] Diferenciei Backup, Restore, HA, Read Replica e PITR;

- [ ] Revisei os fatores de custo;

- [ ] Executei o cleanup.


---


# 14. Cleanup


O Cleanup agora é propositalmente a **última etapa da aula**.


Antes de excluir, confirme que concluiu o exercício de Backup/Restore.


```bash
# Exclui a instância Cloud SQL e encerra sua cobrança.
gcloud sql instances delete "$INSTANCE" \
  --quiet
```


Valide que a instância não aparece mais:


```bash
# Lista as instâncias restantes no projeto.
gcloud sql instances list
```


> Cloud SQL gera cobrança enquanto a instância existir. Não deixe a instância do laboratório ativa depois de concluir a aula.
