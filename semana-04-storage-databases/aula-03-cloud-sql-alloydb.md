# Aula 3 — Cloud SQL e AlloyDB

## Objetivos

Ao final, você deverá:
- entender o problema que Cloud SQL resolve;
- criar uma instância PostgreSQL gerenciada;
- criar database e usuário;
- inspecionar estado, versão, região, IP e configurações de backup;
- conectar pelo Cloud Shell;
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

1. **Estado da instância** — `RUNNABLE` indica que a instância está disponível.
2. **Database** — conexão aponta para um database existente.
3. **Usuário** — autenticação usa um usuário configurado no Cloud SQL.
4. **Senha** — credencial do usuário; erro gera falha de autenticação.
5. **IP público/privado** — determina o caminho de conectividade.
6. **Authorized networks / Cloud SQL Auth Proxy / conectores** — métodos diferentes de conexão.
7. **Backup configuration** — recuperação não é o mesmo que alta disponibilidade.
8. **Availability type** — disponibilidade regional é uma configuração separada de backup.

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
export REGION=us-central1
export INSTANCE=ace-sql
export DB=aceapp
export DB_USER=aceuser

gcloud services enable sqladmin.googleapis.com

gcloud sql instances create "$INSTANCE" \
  --database-version=POSTGRES_16 \
  --cpu=1 \
  --memory=3840MiB \
  --region="$REGION" \
  --storage-size=10GB

gcloud sql databases create "$DB" \
  --instance="$INSTANCE"

gcloud sql users create "$DB_USER" \
  --instance="$INSTANCE" \
  --password='Ace-Lab-12345!'
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

### 3.1 Estado, engine e região

```bash
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(name,state,databaseVersion,region,settings.availabilityType)"
```

Localize:

```text
state
databaseVersion
region
settings.availabilityType
```

### 3.2 IPs

```bash
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(ipAddresses)"
```

Agora você sabe se há endereço público configurado.

### 3.3 Databases

```bash
gcloud sql databases list \
  --instance="$INSTANCE"
```

Confirme que `aceapp` existe.

### 3.4 Usuários

```bash
gcloud sql users list \
  --instance="$INSTANCE"
```

Confirme que `aceuser` existe.

### 3.5 Backup

```bash
gcloud sql instances describe "$INSTANCE" \
  --format="yaml(settings.backupConfiguration)"
```

O objetivo é reconhecer se backup está habilitado/configurado. Não confunda backup com HA.

### 3.6 Conectividade

Para o laboratório, `gcloud sql connect` pode criar temporariamente a autorização necessária para o Cloud Shell e abrir o cliente PostgreSQL. Isso evita ensinar CIDRs de authorized networks antes da hora.

```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```

Quando solicitado, use:

```text
Ace-Lab-12345!
```

Dentro do `psql`:

```sql
SELECT current_database();
SELECT current_user;

CREATE TABLE clientes (
    id INTEGER PRIMARY KEY,
    nome TEXT NOT NULL
);

INSERT INTO clientes VALUES
(1, 'Ana'),
(2, 'Bruno');

SELECT * FROM clientes;
```

Saia:

```text
\q
```

---

# 4. Testar

### Teste 1 — persistência

Conecte novamente:

```bash
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database="$DB"
```

Execute:

```sql
SELECT * FROM clientes;
```

Os dados devem continuar lá.

### Teste 2 — estado

```bash
gcloud sql instances describe "$INSTANCE" \
  --format="value(state)"
```

### Teste 3 — diferenciar backup e HA

Confira simultaneamente:

```bash
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
gcloud sql connect "$INSTANCE" \
  --user="$DB_USER" \
  --database=banco-que-nao-existe
```

### Falha B — usuário incorreto

```bash
gcloud sql connect "$INSTANCE" \
  --user=usuario-que-nao-existe \
  --database="$DB"
```

> Para erro de senha, o comando interativo solicitará a senha. Digite deliberadamente uma senha incorreta e observe a mensagem de autenticação.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

## Caso A — database inexistente

**Sintoma:** conexão informa que o database não existe.

**Hipótese:** o nome passado em `--database` não está na instância.

**Evidência:**
```bash
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
gcloud sql users list --instance="$INSTANCE"
```

Isso confirma que o usuário existe. A senha não é exibida pelo serviço.

**Causa:** senha incorreta digitada deliberadamente.

**Correção:** usar a senha correta ou redefini-la:

```bash
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
SELECT current_database(), current_user;
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

1. Aplicação existente usa MySQL e quer banco gerenciado com mínima mudança. **Cloud SQL**.
2. Backup e HA são a mesma configuração? **Não**.
3. Erro “database does not exist”: qual evidência primeiro? **`gcloud sql databases list`**.
4. Erro de autenticação mas usuário existe: o que verificar? **Senha/credencial**, não route table.
5. Workload PostgreSQL-compatible com requisitos maiores de desempenho e arquitetura AlloyDB: **AlloyDB**.

---

# 9. Cleanup

```bash
gcloud sql instances delete "$INSTANCE" --quiet
```

---

# 10. Checklist

- [ ] Entendi os conceitos usados no laboratório;
- [ ] Criei o recurso;
- [ ] Inspecionei estado e configuração;
- [ ] Testei o comportamento esperado;
- [ ] Provoquei a falha descrita;
- [ ] Diagnostiquei usando evidências;
- [ ] Corrigi sem aumentar privilégios ou alterar componentes desnecessários;
- [ ] Consigo relacionar o cenário a uma questão ACE;
- [ ] Executei o cleanup.

---

# Cobertura adicional — Backup e Restore de Cloud SQL

O exam guide exige criar backups e restaurar instâncias de banco.

## Antes de restaurar, saiba listar backups

```bash
gcloud sql backups list --instance="$INSTANCE"
```

Criar backup on-demand:

```bash
gcloud sql backups create --instance="$INSTANCE"
```

Inspecione novamente:

```bash
gcloud sql backups list --instance="$INSTANCE"
```

### Modelo mental

```text
HA
→ continuidade/disponibilidade da instância

Backup
→ cópia para recuperação

PITR
→ recuperação para ponto no tempo quando configurado
```

### Falha proposital segura

Antes de apagar dados, crie uma tabela de laboratório e backup. Depois remova uma linha e valide que o backup existe. Em projeto descartável, pratique restore seguindo o fluxo suportado pelo Console/CLI para a versão atual.

Na prova, não responda “HA” quando o requisito for recuperar dado apagado logicamente.
