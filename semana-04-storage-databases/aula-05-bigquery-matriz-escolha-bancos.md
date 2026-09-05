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
# Explicação: Define `PROJECT_ID` com o ID do projeto Google Cloud usado pelos comandos seguintes.
export PROJECT_ID=$(gcloud config get-value project)

# Explicação: Cria um recurso BigQuery, como dataset ou tabela, conforme as flags.
bq mk --dataset --location=US "$PROJECT_ID:ace_analytics"

# Explicação: Exibe conteúdo de arquivo ou cria conteúdo via redirecionamento/heredoc, conforme a sintaxe usada.
cat > vendas.csv <<'EOF'
id,estado,valor
1,SP,100
2,RJ,200
3,SP,150
EOF

# Explicação: Carrega dados no BigQuery a partir do arquivo/origem e schema informados.
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
# Explicação: Exibe metadados e schema do recurso BigQuery indicado.
bq show "$PROJECT_ID:ace_analytics"
# Explicação: Exibe metadados e schema do recurso BigQuery indicado.
bq show "$PROJECT_ID:ace_analytics.vendas"
# Explicação: Lista datasets, tabelas ou jobs BigQuery conforme o argumento.
bq ls "$PROJECT_ID:ace_analytics"
```

---

# 4. Testar

```bash
# Explicação: Executa uma consulta SQL no BigQuery; as flags controlam Standard SQL, dry run e outros parâmetros.
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
# Explicação: Executa uma consulta SQL no BigQuery; as flags controlam Standard SQL, dry run e outros parâmetros.
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
# Explicação: Lista datasets, tabelas ou jobs BigQuery conforme o argumento.
bq ls "$PROJECT_ID:ace_analytics"
# Explicação: Exibe metadados e schema do recurso BigQuery indicado.
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
# Explicação: Remove o recurso BigQuery indicado durante o cleanup.
bq rm -r -f "$PROJECT_ID:ace_analytics"
# Explicação: Remove o arquivo/diretório temporário indicado durante correção ou cleanup.
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

---

# Cobertura adicional — BigQuery Jobs e estimativa de custo

O exam guide inclui revisar status de jobs e estimar custos de storage/data processing.

## Jobs

```bash
# Explicação: Lista datasets, tabelas ou jobs BigQuery conforme o argumento.
bq ls -j -a -n 20
```

Para inspecionar um job específico:

```bash
# Explicação: Exibe metadados e schema do recurso BigQuery indicado.
bq show -j PROJECT_ID:LOCATION.JOB_ID
```

## Dry run

Antes de executar query analítica maior:

```bash
# Explicação: Executa uma consulta SQL no BigQuery; as flags controlam Standard SQL, dry run e outros parâmetros.
bq query \
  --use_legacy_sql=false \
  --dry_run \
  'SELECT estado, SUM(valor) FROM `PROJECT.dataset.table` GROUP BY estado'
```

O dry run ajuda a estimar bytes processados sem executar a consulta.

Diferencie:

```text
bytes processados por query
storage armazenado
slots/capacidade (quando aplicável)
```

---

<!-- MEP-ACCEPTANCE-V8 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v8.

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
| 4.4 | Queries BigQuery | `P` | `P` |
| 4.4 | Status BigQuery jobs | `P` | `P` |
