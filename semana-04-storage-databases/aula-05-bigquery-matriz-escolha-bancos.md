# Aula 5 — BigQuery e Matriz de Escolha de Bancos

## Objetivos

Ao final desta aula, você deverá:

- Entender BigQuery em nível ACE;
- Diferenciar BigQuery de bancos transacionais;
- Revisar todos os serviços;
- Tomar decisões por requisito.

---

# 1. BigQuery

BigQuery é o data warehouse analítico serverless do Google Cloud.

```text
Data
  │
  ▼
BigQuery
  │
  ├── SQL
  ├── Analytics
  ├── Large Scale
  └── Serverless
```

---

# 2. Estrutura

```text
Project
   │
   ▼
Dataset
   │
   ▼
Table
```

---

# 3. Casos de uso

- BI;
- Analytics;
- Data warehouse;
- Grandes volumes;
- SQL analítico;
- Data lakehouse/analytics.

---

# 4. BigQuery não é OLTP

Não escolha BigQuery para:

- CRUD transacional;
- Sistemas operacionais de baixa latência por linha;
- Workloads relacionais transacionais tradicionais.

---

# 5. Matriz principal

| Necessidade | Serviço |
|---|---|
| MySQL/PostgreSQL/SQL Server tradicional | Cloud SQL |
| PostgreSQL enterprise/performance | AlloyDB |
| SQL distribuído/global | Spanner |
| Documentos serverless | Firestore |
| Wide-column / time series | Bigtable |
| Analytics / DW | BigQuery |

---

# 6. Heurística de decisão

Pergunte:

```text
1. É transacional ou analítico?
2. Precisa SQL?
3. Precisa escala horizontal?
4. Precisa distribuição global?
5. É documento?
6. É wide-column/time series?
7. É PostgreSQL especificamente?
```

---

# 7. Exemplos

## E-commerce tradicional

```text
PostgreSQL
→ Cloud SQL
```

## Plataforma PostgreSQL enterprise

```text
PostgreSQL + performance
→ AlloyDB
```

## Ledger global

```text
SQL + transactions + horizontal scale
→ Spanner
```

## App mobile

```text
Documents
→ Firestore
```

## Telemetria

```text
High volume + low latency + wide-column
→ Bigtable
```

## BI corporativo

```text
Analytics
→ BigQuery
```

---

# 8. Armadilhas comuns

## Escolher Spanner para tudo

Errado.

## Escolher BigQuery para OLTP

Errado.

## Escolher Firestore para SQL relacional

Errado.

## Escolher Cloud SQL para volume massivo de telemetria

Provavelmente inadequado.

---

# 9. Questões Estilo ACE

## Questão 1

Equipe de BI precisa consultar dezenas de TB com SQL.

**Resposta:** BigQuery.

## Questão 2

Aplicação CRUD PostgreSQL tradicional.

**Resposta:** Cloud SQL.

## Questão 3

Banco SQL precisa escalar globalmente.

**Resposta:** Spanner.

## Questão 4

App mobile usa documentos.

**Resposta:** Firestore.

## Questão 5

Telemetria massiva.

**Resposta:** Bigtable.

---

# 10. Revisão Final

```text
Storage
  └── Cloud Storage

Relational
  ├── Cloud SQL
  ├── AlloyDB
  └── Spanner

NoSQL
  ├── Firestore
  └── Bigtable

Analytics
  └── BigQuery
```

---

# 11. Checklist

- [ ] Entendo BigQuery em nível ACE
- [ ] Sei que BigQuery é analítico
- [ ] Sei diferenciar OLTP e OLAP
- [ ] Sei comparar Cloud SQL, AlloyDB e Spanner
- [ ] Sei comparar Firestore e Bigtable
- [ ] Consigo escolher serviço por requisito
