# Aula 4 — Spanner, Firestore e Bigtable

## Objetivos

Ao final, você deverá:
- diferenciar os três modelos;
- praticar Firestore de baixo custo quando possível;
- inspecionar comandos dos serviços;
- diagnosticar escolha inadequada de banco por padrão de acesso.


---

# 1. Conceito

Spanner é relacional distribuído e horizontalmente escalável. Firestore é banco de documentos serverless. Bigtable é wide-column de grande throughput e baixa latência por chave. A aula prioriza **decisão de serviço**, pois provisionar Spanner/Bigtable só para observar console pode gerar custo desnecessário.

## Arquitetura mental

```text
SQL relacional global → Spanner
Documentos           → Firestore
Wide-column/time key → Bigtable
```

---

# 2. Criar

### Firestore

Se o projeto não possui Firestore database, crie no Console em Native mode em um projeto de laboratório.

Inspecione:

```bash
# Explicação: Executa `gcloud firestore databases list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud firestore databases list
```

No Console crie:

```text
collection: clientes
document:
  nome: Ana
  segmento: premium
```

### Spanner e Bigtable — inspeção sem provisionar cluster caro

```bash
# Explicação: Executa `gcloud spanner instances list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud spanner instances list
# Explicação: Executa `gcloud bigtable instances list` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud bigtable instances list
```

Monte uma matriz:

```text
transação relacional global → Spanner
documento JSON-like         → Firestore
telemetria por device/time  → Bigtable
```

---

# 3. Inspecionar

Antes de provocar qualquer erro, confirme a configuração criada. O troubleshooting desta aula usará **somente elementos que você já observou aqui**.

Para Firestore, confira database/mode/location no Console ou:

```bash
# Explicação: Executa `gcloud firestore databases describe --database='(default)'` nesta etapa para aplicar ou inspecionar a configuração indicada.
gcloud firestore databases describe --database='(default)'
```

Para a matriz, escreva para cada serviço:
- modelo;
- padrão de consulta;
- escala;
- consistência/transação relevante;
- custo operacional.

---

# 4. Testar

Teste no Firestore:
1. crie dois documentos;
2. consulte collection;
3. altere um campo;
4. exclua um documento.

O foco é experimentar o modelo de documentos.

---

# 5. Quebrar propositalmente

Falha proposital de **decisão**, não de infraestrutura:

Cenário:
> “Precisamos fazer SQL analítico ad hoc sobre terabytes e escolhemos Bigtable.”

Anote por que essa escolha é inadequada antes de ver a correção.

---

# 6. Troubleshooting

Agora o erro já foi produzido e os componentes envolvidos já foram apresentados.

**Sintoma:** a equipe precisa de agregações/joins analíticos e a solução escolhida exige modelagem por chave e não oferece a experiência de warehouse desejada.

**Hipótese:** o banco foi escolhido pelo volume, não pelo padrão de acesso.

**Evidência:** requisito dominante é SQL analítico ad hoc.

**Causa:** Bigtable resolve alta escala por chave/wide-column, não warehouse analítico.

**Correção:** BigQuery é o candidato natural para analytics.

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

Atualize sua matriz com a coluna **“não usar quando”**:

```text
Spanner   → não escolher apenas porque “é grande”; exige necessidade relacional distribuída
Firestore → não escolher para SQL relacional/joins
Bigtable  → não escolher para BI ad hoc
```

---

# 8. Questões estilo ACE

1. Banco relacional global/horizontal? **Spanner**.
2. App mobile com documentos? **Firestore**.
3. Telemetria por chave com altíssimo throughput? **Bigtable**.
4. Analytics ad hoc? **BigQuery**, não Bigtable.

---

# 9. Cleanup

Remova documentos/collections de laboratório no Firestore se criados. Não há cleanup de Spanner/Bigtable porque não os provisionamos.

---


---

# Cobertura ACE ampliada — backups e serviços de dados adicionais

## Backup/restore como capacidade operacional

O guia cita backup/restore para Cloud SQL, Firestore, Spanner, AlloyDB e Bigtable. No nível ACE, saiba:

- identificar se o produto oferece backup gerenciado;
- localizar backups;
- entender restore;
- distinguir backup de HA/replicação.

## Memorystore

```text
Memorystore → cache/in-memory gerenciado (Redis/Valkey conforme produto atual)
```

Use quando o requisito é cache/sessão/baixa latência em memória, não como warehouse analítico.

## Google Cloud Managed Service for Apache Kafka

Serviço gerenciado para workloads Kafka compatíveis quando o requisito exige ecossistema/protocolo Kafka. Não confunda com Pub/Sub, que é serviço nativo de mensageria do Google Cloud com modelo operacional diferente.

## Matriz ampliada

```text
Cloud SQL     → OLTP relacional tradicional
AlloyDB       → PostgreSQL-compatible exigente
Spanner       → relacional distribuído/global
Firestore     → documentos
Bigtable      → wide-column / chave / alto throughput
BigQuery      → analytics
Memorystore   → cache/in-memory
Pub/Sub       → messaging/event ingestion nativo
Managed Kafka → ecossistema Kafka
```

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

## Prática guiada obrigatória — backup e restore do Firestore

O guia anexado exige **backup e restore do Firestore**. Apenas citar “backup/restore” não é cobertura suficiente.

**Nível:** `P*` — depende do modo/database e das funcionalidades habilitadas na conta/projeto.

No Console do projeto de laboratório:

1. abra **Firestore**;
2. identifique o database correto;
3. localize a área de **Backups** disponível para o database;
4. crie um backup de laboratório quando a opção estiver disponível;
5. aguarde status de conclusão;
6. inspecione o backup e seu timestamp;
7. execute o fluxo de restore para um database de destino compatível, sem sobrescrever dados importantes;
8. valide documentos após o restore.

### Modelo mental

```text
Firestore database
      ↓ backup
Backup resource
      ↓ restore
Database restaurado
```

### Troubleshooting

```text
Sintoma: backup existe, mas restore não pode ser executado no alvo escolhido
Hipótese: destino/configuração do database não atende aos requisitos do restore
Evidência: propriedades do backup + database alvo
Causa: incompatibilidade/configuração, não consulta de documentos
Correção: selecionar destino compatível conforme o fluxo suportado
```

> Se a interface/feature não estiver disponível no seu projeto, marque como `P*` e faça a prática guiada sem inventar comandos não validados.

---

<!-- MEP-ACCEPTANCE-V9 -->
# Critério de aceite M/E/P desta aula

> Esta seção não substitui o conteúdo acima; ela explicita o critério usado na auditoria da baseline v9.

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
| 4.4 | Queries Spanner | `P` | `E/P*` |
| 4.4 | Queries Firestore | `P` | `P*` |
| 4.4 | Backup/restore Firestore | `P` | `P*` |
