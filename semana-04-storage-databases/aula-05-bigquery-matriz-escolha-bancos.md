# Aula 5 — BigQuery e Matriz de Escolha de Bancos

## Objetivos

Ao final desta aula, você deverá:

- Criar dataset/tabela BigQuery;
- Carregar CSV e consultar;
- Entender warehouse analítico serverless;
- Escolher banco por requisito;

---

# 1. Modelo mental

```text
CSV/GCS ──> BigQuery
             ├─ dataset
             ├─ tables
             └─ SQL analytics
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

```bash
export PROJECT_ID=$(gcloud config get-value project)
bq mk --dataset --location=US $PROJECT_ID:ace_analytics

cat > vendas.csv <<'EOF'
id,estado,valor
1,SP,100
2,RJ,200
3,SP,150
EOF

bq load --source_format=CSV --skip_leading_rows=1 \
  ace_analytics.vendas \
  vendas.csv \
  id:INTEGER,estado:STRING,valor:NUMERIC

bq query --use_legacy_sql=false \
'SELECT estado, SUM(valor) receita
 FROM `'"$PROJECT_ID"'.ace_analytics.vendas`
 GROUP BY estado ORDER BY receita DESC'
```

Matriz de decisão:
- OLTP relacional tradicional → Cloud SQL
- PostgreSQL-compatible high performance → AlloyDB
- relacional horizontal/global → Spanner
- documentos → Firestore
- wide-column → Bigtable
- analytics/warehouse → BigQuery

---

# 4. Testes e falhas propositais

- Execute `SELECT *` e discuta bytes processados em tabelas grandes.
- BigQuery não é escolha padrão para transação OLTP.
- Particionamento/clustering ajudam performance/custo analítico.

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

- BigQuery separa armazenamento/compute e é serverless para analytics.
- Escolha banco por padrão de acesso, consistência, escala e modelo, não por popularidade.
- Export/backup operacional e queries analíticas são problemas diferentes.

---

# 7. Questões estilo ACE

- BI sobre terabytes/petabytes? → BigQuery.
- CRUD transacional PostgreSQL pequeno/médio? → Cloud SQL.

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

