# Aula 3 — Cloud SQL e AlloyDB

## Objetivos

Ao final desta aula, você deverá:

- Criar Cloud SQL de laboratório;
- Conectar e inspecionar;
- Entender HA/backups;
- Diferenciar Cloud SQL e AlloyDB;

---

# 1. Modelo mental

```text
App ──> Cloud SQL
          ├─ managed relational DB
          ├─ backups
          └─ HA opcional

App ──> AlloyDB for PostgreSQL
          └─ PostgreSQL-compatible, performance/HA architecture
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

> Cloud SQL gera custo. Use instância pequena e remova no final.

```bash
export REGION=us-central1
gcloud services enable sqladmin.googleapis.com

gcloud sql instances create ace-sql \
  --database-version=POSTGRES_16 \
  --cpu=1 --memory=3840MiB \
  --region=$REGION \
  --storage-size=10GB

gcloud sql databases create aceapp --instance=ace-sql
gcloud sql users set-password postgres \
  --instance=ace-sql \
  --password='Troque-Esta-Senha-123!'
gcloud sql instances describe ace-sql
```

Conexão pelo Cloud Shell:
```bash
gcloud sql connect ace-sql --user=postgres --database=aceapp
```

Dentro do psql:
```sql
CREATE TABLE clientes(id INT PRIMARY KEY, nome TEXT);
INSERT INTO clientes VALUES (1,'ACE');
SELECT * FROM clientes;
```

Compare no console as opções de backup, PITR e HA.

---

# 4. Testes e falhas propositais

- Pare a conexão e valide que dado persiste.
- Não confunda read replica com HA/failover.
- AlloyDB não é 'Cloud SQL premium'; é serviço próprio PostgreSQL-compatible com arquitetura distinta.

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

- Cloud SQL suporta engines relacionais gerenciadas.
- HA é decisão de disponibilidade; backup/PITR é recuperação.
- AlloyDB é forte candidato para PostgreSQL de alto desempenho/escala, mas ACE cobra principalmente escolha de serviço.

---

# 7. Questões estilo ACE

- Aplicação MySQL tradicional gerenciada? → Cloud SQL.
- PostgreSQL-compatible com alta performance e arquitetura AlloyDB? → AlloyDB.

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

