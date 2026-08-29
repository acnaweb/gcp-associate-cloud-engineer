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
gcloud spanner instances list
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
