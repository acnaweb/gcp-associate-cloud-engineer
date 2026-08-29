# Aula 5 — BigQuery e Matriz de Escolha de Bancos

## Objetivos

Ao final, você deverá:
- criar dataset/tabela;
- carregar CSV;
- consultar;
- inspecionar schema e bytes;
- provocar erro de tabela/dataset;
- fechar matriz de escolha de bancos.


---

# 1. Conceito

BigQuery é plataforma analítica serverless. Dataset agrupa tabelas e possui localização. Tabela possui schema. Queries processam dados e podem gerar custo conforme modelo/edição.

## Arquitetura mental

```text
CSV
 ↓
BigQuery dataset
 ↓
table
 ↓
SQL analytics
```

---

# 2. Criar

```bash
export PROJECT_ID=$(gcloud config get-value project)

bq mk --dataset --location=US "$PROJECT_ID:ace_analytics"

cat > vendas.csv <<'EOF'
id,estado,valor
1,SP,100
2,RJ,200
3,SP,150
EOF

bq load \
  --source_format=CSV \
  --skip_leading_rows=1 \
  ace_analytics.vendas \
  vendas.csv \
  id:INTEGER,estado:STRING,valor:NUMERIC
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

```bash
bq show "$PROJECT_ID:ace_analytics"
bq show "$PROJECT_ID:ace_analytics.vendas"
bq ls "$PROJECT_ID:ace_analytics"
```

---

# 4. Testar

```bash
bq query --use_legacy_sql=false \
'SELECT estado, SUM(valor) receita
 FROM `'"$PROJECT_ID"'.ace_analytics.vendas`
 GROUP BY estado
 ORDER BY receita DESC'
```

---

# 5. Quebrar propositalmente

Use uma tabela inexistente:

```bash
bq query --use_legacy_sql=false \
'SELECT * FROM `'"$PROJECT_ID"'.ace_analytics.vendas_errada`'
```

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** BigQuery informa tabela não encontrada.

**Hipótese:** dataset existe, mas table ID está incorreto.

**Evidências:**
```bash
bq ls "$PROJECT_ID:ace_analytics"
bq show "$PROJECT_ID:ace_analytics.vendas"
```

**Causa:** consultamos `vendas_errada`.

Esse erro é diferente de schema inválido ou IAM; a mensagem aponta para identificação do recurso.

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

Execute usando o table ID correto e feche a matriz:

```text
Cloud SQL  → OLTP relacional tradicional
AlloyDB    → PostgreSQL-compatible exigente
Spanner    → relacional distribuído/global
Firestore  → documentos
Bigtable   → wide-column/alta escala por chave
BigQuery   → analytics/warehouse
```

---

# 8. Questões estilo ACE

1. SQL analítico sobre TB/PB? **BigQuery**.
2. CRUD PostgreSQL pequeno/médio? **Cloud SQL**.
3. Tabela não encontrada: primeiro listar dataset/tabelas? **Sim**.

---

# 9. Cleanup

```bash
bq rm -r -f "$PROJECT_ID:ace_analytics"
rm -f vendas.csv
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
